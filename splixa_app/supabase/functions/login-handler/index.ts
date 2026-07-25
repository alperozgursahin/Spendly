import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {},
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...extraHeaders,
    },
  });

const hashBucketValue = async (value: string) => {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
};

const clientIpFrom = (request: Request) => {
  const cloudflareIp = request.headers.get("cf-connecting-ip")?.trim();
  if (cloudflareIp) return cloudflareIp;

  const forwardedIp = request.headers
    .get("x-forwarded-for")
    ?.split(",")[0]
    ?.trim();
  if (forwardedIp) return forwardedIp;

  return request.headers.get("x-real-ip")?.trim() || "unknown";
};

type AdminClient = ReturnType<typeof createClient>;
type RateLimitResult = { allowed: boolean; retryAfterSeconds: number };

const consumeRateLimit = async (
  adminClient: AdminClient,
  bucketKey: string,
  maxAttempts: number,
  windowSeconds: number,
): Promise<RateLimitResult> => {
  const { data, error } = await adminClient.rpc("consume_login_rate_limit", {
    p_bucket_key: bucketKey,
    p_max_attempts: maxAttempts,
    p_window_seconds: windowSeconds,
  });

  if (error) throw error;

  const row = Array.isArray(data) ? data[0] : data;
  if (!row || typeof row.allowed !== "boolean") {
    throw new Error("Invalid rate-limit response");
  }

  return {
    allowed: row.allowed,
    retryAfterSeconds: Number(row.retry_after_seconds ?? 0),
  };
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey =
    Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("MY_SECRET_KEY");
  const playReviewEmail = Deno.env
    .get("PLAY_REVIEW_EMAIL")
    ?.trim()
    .toLowerCase();

  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    console.error("login-handler is missing required Supabase secrets");
    return jsonResponse({ error: "Login service is unavailable" }, 503);
  }

  let identifier: string;
  let password: string;
  try {
    const body = await request.json();
    identifier = String(body.identifier ?? "").trim().toLowerCase();
    password = String(body.password ?? "");
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  if (
    !identifier ||
    !password ||
    identifier.length > 320 ||
    password.length > 1024
  ) {
    return jsonResponse({ error: "Invalid login credentials" }, 401);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const authClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    let blocked: RateLimitResult | null = null;
    const clientIp = clientIpFrom(request);

    // Check the broader IP bucket first. Once it is blocked, random identifiers
    // cannot create an unbounded number of identifier buckets.
    if (clientIp !== "unknown") {
      const ipHash = await hashBucketValue(clientIp);
      const ipLimit = await consumeRateLimit(
        adminClient,
        `ip:${ipHash}`,
        30,
        900,
      );
      if (!ipLimit.allowed) blocked = ipLimit;
    }

    if (!blocked) {
      const identifierHash = await hashBucketValue(identifier);
      const identifierLimit = await consumeRateLimit(
        adminClient,
        `identifier:${identifierHash}`,
        6,
        900,
      );
      if (!identifierLimit.allowed) blocked = identifierLimit;
    }

    if (blocked) {
      const retryAfter = Math.max(1, blocked.retryAfterSeconds);
      return jsonResponse(
        { error: "Too many login attempts. Please try again later." },
        429,
        { "Retry-After": String(retryAfter) },
      );
    }
  } catch (error) {
    console.error(
      "login-handler rate-limit check failed",
      error instanceof Error ? error.message : "unknown error",
    );
    // Fail closed: never bypass throttling when its backing store is unavailable.
    return jsonResponse({ error: "Login service is unavailable" }, 503);
  }

  let email = identifier;
  if (!identifier.includes("@")) {
    const username = identifier.replace(/^@/, "");
    const { data: profile, error: lookupError } = await adminClient
      .from("profiles")
      .select("email")
      .ilike("username", username)
      .maybeSingle();

    if (lookupError) {
      console.error("login-handler profile lookup failed", lookupError.code);
      return jsonResponse({ error: "Login service is unavailable" }, 503);
    }
    if (!profile?.email) {
      // Keep the response identical to a wrong password to prevent username
      // enumeration through status codes or response bodies.
      return jsonResponse({ error: "Invalid login credentials" }, 401);
    }
    email = String(profile.email).trim().toLowerCase();
  }

  const { data: passwordResult, error: passwordError } =
    await authClient.auth.signInWithPassword({ email, password });
  if (passwordError || !passwordResult.session) {
    return jsonResponse({ error: "Invalid login credentials" }, 401);
  }

  // Google Play receives the review account password through Play Console.
  // The password is still verified by Supabase Auth and is never embedded in
  // the app or this function. Only the server-configured review account skips
  // email OTP; its normal Supabase refresh token establishes the client session.
  if (playReviewEmail && email === playReviewEmail) {
    return jsonResponse({
      email,
      reviewRefreshToken: passwordResult.session.refresh_token,
    });
  }

  // The temporary password session remains inside this isolated function and is
  // discarded locally before the OTP request; no session token is returned.
  await authClient.auth.signOut({ scope: "local" });

  const { error: otpError } = await authClient.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: false },
  });
  if (otpError) {
    console.error("login-handler OTP delivery failed", otpError.status);
    return jsonResponse({ error: "Verification code could not be sent" }, 503);
  }

  return jsonResponse({ email });
});
