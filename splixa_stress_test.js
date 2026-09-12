import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import exec from 'k6/execution';

const BASE_URL = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || '';
const USERS_FILE = __ENV.USERS_FILE || './splixa_test_users.json';

const users = new SharedArray('test users', () => {
  const parsed = JSON.parse(open(USERS_FILE));
  if (!Array.isArray(parsed) || parsed.length === 0) {
    throw new Error(`${USERS_FILE} must contain a non-empty JSON array`);
  }
  return parsed.map((user, index) => {
    if (!user.email || !user.password) {
      throw new Error(`User at index ${index} must have email and password`);
    }
    return { email: String(user.email), password: String(user.password) };
  });
});

const VUS = Number(__ENV.VUS || Math.min(users.length, 5));
const DURATION = __ENV.DURATION || '30s';
const THINK_TIME = Number(__ENV.THINK_TIME || 1);

if (!BASE_URL || !ANON_KEY) {
  throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
}
if (!Number.isInteger(VUS) || VUS < 1) {
  throw new Error('VUS must be a positive integer');
}
if (VUS > users.length) {
  throw new Error(`VUS (${VUS}) cannot exceed the number of test users (${users.length})`);
}

export const options = {
  scenarios: {
    concurrent_users: {
      executor: 'constant-vus',
      vus: VUS,
      duration: DURATION,
      gracefulStop: '10s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000', 'p(99)<2000'],
    'http_req_duration{name:auth_login}': ['p(95)<1500'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  userAgent: 'Splixa-k6-stress-test/1.0',
};

let session;

function publicHeaders() {
  return {
    apikey: ANON_KEY,
    Authorization: `Bearer ${ANON_KEY}`,
    'Content-Type': 'application/json',
  };
}

function authenticatedHeaders(accessToken) {
  return {
    apikey: ANON_KEY,
    Authorization: `Bearer ${accessToken}`,
    Accept: 'application/json',
  };
}

function login(user) {
  const response = http.post(
    `${BASE_URL}/auth/v1/token?grant_type=password`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: publicHeaders(), tags: { name: 'auth_login' } },
  );

  const ok = check(response, {
    'login returns 200': (res) => res.status === 200,
    'login returns access token': (res) => {
      try {
        return Boolean(res.json('access_token'));
      } catch (_) {
        return false;
      }
    },
  });

  if (!ok) {
    exec.test.abort(
      `Login failed for VU ${__VU}: HTTP ${response.status} ${response.body}`,
    );
  }

  const body = response.json();
  return { accessToken: body.access_token, userId: body.user.id };
}

function get(path, name) {
  const response = http.get(`${BASE_URL}/rest/v1/${path}`, {
    headers: authenticatedHeaders(session.accessToken),
    tags: { name },
  });

  check(response, {
    [`${name} returns 200`]: (res) => res.status === 200,
    [`${name} returns JSON`]: (res) => {
      try {
        res.json();
        return true;
      } catch (_) {
        return false;
      }
    },
  });
}

export default function () {
  if (!session) {
    const userIndex = (exec.vu.idInTest - 1) % users.length;
    session = login(users[userIndex]);
  }

  const userId = encodeURIComponent(session.userId);

  // Dashboard/application read flow. These requests exercise RLS and joins,
  // but deliberately do not create, update, or delete user data.
  get(
    `transactions?select=*&user_id=eq.${userId}&order=date.desc`,
    'transactions_list',
  );
  sleep(THINK_TIME);

  get(
    `group_members?select=groups(*)&user_id=eq.${userId}`,
    'groups_list',
  );
  sleep(THINK_TIME);

  get(
    `friendships?select=created_at,status,profiles!friendships_user_id2_fkey(username)&user_id1=eq.${userId}&status=eq.accepted&order=created_at.desc&limit=3`,
    'recent_friendships',
  );

  get(
    `group_transactions?select=created_at,description,amount,groups(name)&payer_id=eq.${userId}&order=created_at.desc&limit=3`,
    'recent_group_transactions',
  );
  sleep(THINK_TIME);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'splixa_k6_summary.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metric = (name, field) => data.metrics[name]?.values?.[field];
  const pct = (value) => (value === undefined ? 'n/a' : `${(value * 100).toFixed(2)}%`);
  const ms = (value) => (value === undefined ? 'n/a' : `${value.toFixed(2)} ms`);

  return [
    '',
    'Splixa k6 summary',
    `  VUs:             ${VUS}`,
    `  Duration:        ${DURATION}`,
    `  Requests:        ${metric('http_reqs', 'count') ?? 0}`,
    `  Failed requests: ${pct(metric('http_req_failed', 'rate'))}`,
    `  Checks passed:   ${pct(metric('checks', 'rate'))}`,
    `  Response p95:    ${ms(metric('http_req_duration', 'p(95)'))}`,
    `  Response p99:    ${ms(metric('http_req_duration', 'p(99)'))}`,
    '',
    'Detailed JSON: splixa_k6_summary.json',
    '',
  ].join('\n');
}
