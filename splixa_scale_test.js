import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import exec from 'k6/execution';

const BASE_URL = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || '';
const USERS_FILE = __ENV.USERS_FILE || './splixa_test_users.json';
const THINK_TIME = Number(__ENV.THINK_TIME || 1);
const LOGIN_INTERVAL = Number(__ENV.LOGIN_INTERVAL || 2.1);

const users = new SharedArray('scale test users', () => {
  const parsed = JSON.parse(open(USERS_FILE));
  if (!Array.isArray(parsed) || parsed.length < 30) {
    throw new Error(`${USERS_FILE} must contain at least 30 test users`);
  }
  return parsed.slice(0, 30).map((user, index) => {
    if (!user.email || !user.password) {
      throw new Error(`User at index ${index} must have email and password`);
    }
    return { email: String(user.email), password: String(user.password) };
  });
});

if (!BASE_URL || !ANON_KEY) {
  throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
}

export const options = {
  setupTimeout: '2m',
  scenarios: {
    scale_users: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '2m', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '2m', target: 100 },
        { duration: '1m', target: 250 },
        { duration: '2m', target: 250 },
        { duration: '1m', target: 500 },
        { duration: '3m', target: 500 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_failed: [
      'rate<0.01',
      { threshold: 'rate<0.05', abortOnFail: true, delayAbortEval: '30s' },
    ],
    http_req_duration: [
      'p(95)<1000',
      { threshold: 'p(95)<2000', abortOnFail: true, delayAbortEval: '1m' },
    ],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  userAgent: 'Splixa-k6-scale-test/1.0',
};

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
    { headers: publicHeaders(), tags: { name: 'scale_setup_login' } },
  );

  const ok = check(response, {
    'setup login returns 200': (res) => res.status === 200,
    'setup login returns access token': (res) => {
      try {
        return Boolean(res.json('access_token'));
      } catch (_) {
        return false;
      }
    },
  });
  if (!ok) {
    exec.test.abort(`Scale-test setup login failed: HTTP ${response.status}`);
  }

  const body = response.json();
  return { accessToken: body.access_token, userId: body.user.id };
}

export function setup() {
  const sessions = [];
  for (let index = 0; index < users.length; index += 1) {
    sessions.push(login(users[index]));
    if (index < users.length - 1) sleep(LOGIN_INTERVAL);
  }
  return { sessions };
}

function get(session, path, name) {
  const response = http.get(`${BASE_URL}/rest/v1/${path}`, {
    headers: authenticatedHeaders(session.accessToken),
    tags: { name },
  });

  if (response.status === 429 || response.status >= 500) {
    exec.test.abort(`${name} triggered safety stop: HTTP ${response.status}`);
  }
  if (response.timings.duration > 5000) {
    exec.test.abort(
      `${name} triggered safety stop: ${response.timings.duration.toFixed(0)} ms`,
    );
  }

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

export default function (data) {
  const session = data.sessions[(exec.vu.idInTest - 1) % data.sessions.length];
  const userId = encodeURIComponent(session.userId);

  get(
    session,
    `transactions?select=*&user_id=eq.${userId}&order=date.desc`,
    'transactions_list',
  );
  sleep(THINK_TIME);

  get(
    session,
    `group_members?select=groups(*)&user_id=eq.${userId}`,
    'groups_list',
  );
  sleep(THINK_TIME);

  get(
    session,
    `friendships?select=created_at,status,profiles!friendships_user_id2_fkey(username)&user_id1=eq.${userId}&status=eq.accepted&order=created_at.desc&limit=3`,
    'recent_friendships',
  );
  get(
    session,
    `group_transactions?select=created_at,description,amount,groups(name)&payer_id=eq.${userId}&order=created_at.desc&limit=3`,
    'recent_group_transactions',
  );
  sleep(THINK_TIME);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'splixa_scale_summary.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metric = (name, field) => data.metrics[name]?.values?.[field];
  const pct = (value) => (value === undefined ? 'n/a' : `${(value * 100).toFixed(2)}%`);
  const ms = (value) => (value === undefined ? 'n/a' : `${value.toFixed(2)} ms`);

  return [
    '',
    'Splixa 500-VU scale summary',
    `  Requests:        ${metric('http_reqs', 'count') ?? 0}`,
    `  Failed requests: ${pct(metric('http_req_failed', 'rate'))}`,
    `  Checks passed:   ${pct(metric('checks', 'rate'))}`,
    `  Response p95:    ${ms(metric('http_req_duration', 'p(95)'))}`,
    `  Response p99:    ${ms(metric('http_req_duration', 'p(99)'))}`,
    '',
    'Detailed JSON: splixa_scale_summary.json',
    '',
  ].join('\n');
}
