import { createClient } from "@supabase/supabase-js";

type JsonObject = Record<string, unknown>;

interface RevenueCatEntitlement {
  expires_date?: string | null;
  grace_period_expires_date?: string | null;
  product_identifier?: string | null;
  purchase_date?: string | null;
}

interface RevenueCatSubscriberResponse {
  subscriber?: {
    entitlements?: Record<string, RevenueCatEntitlement>;
  };
}

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const optionalDate = (value: string | null | undefined) => {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.valueOf()) ? null : parsed;
};

const laterDate = (first: Date | null, second: Date | null) => {
  if (first === null) return second;
  if (second === null) return first;
  return first > second ? first : second;
};

export const isSupabaseUserId = (value: unknown): value is string =>
  typeof value === "string" && uuidPattern.test(value);

export const requiredEnvironment = () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  const revenueCatSecretKey = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  const entitlementId =
    Deno.env.get("REVENUECAT_PREMIUM_ENTITLEMENT_ID") ?? "pro";

  if (!supabaseUrl || !serviceRoleKey || !revenueCatSecretKey) {
    throw new Error("ENTITLEMENT_SERVICE_NOT_CONFIGURED");
  }

  return {
    adminClient: createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    }),
    revenueCatSecretKey,
    entitlementId,
  };
};

export const syncRevenueCatEntitlement = async (
  userId: string,
  context: { eventId?: string | null; eventAt?: Date | null } = {},
) => {
  if (!isSupabaseUserId(userId)) throw new Error("INVALID_USER_ID");

  const { adminClient, revenueCatSecretKey, entitlementId } =
    requiredEnvironment();
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    {
      headers: {
        Authorization: `Bearer ${revenueCatSecretKey}`,
        Accept: "application/json",
      },
    },
  );

  let payload: RevenueCatSubscriberResponse = {};
  if (response.status !== 404) {
    if (!response.ok) {
      const requestId = response.headers.get("x-request-id") ?? "unknown";
      throw new Error(
        `REVENUECAT_LOOKUP_FAILED:${response.status}:${requestId}`,
      );
    }
    payload = await response.json() as RevenueCatSubscriberResponse;
  }

  const entitlement = payload.subscriber?.entitlements?.[entitlementId];
  const expiration = optionalDate(entitlement?.expires_date);
  const graceExpiration = optionalDate(entitlement?.grace_period_expires_date);
  const effectiveExpiration = laterDate(expiration, graceExpiration);
  const isLifetime = entitlement !== undefined &&
    entitlement.expires_date === null;
  const isActive = entitlement !== undefined &&
    (isLifetime ||
      (effectiveExpiration !== null && effectiveExpiration > new Date()));

  const row: JsonObject = {
    user_id: userId,
    entitlement_id: "pro",
    is_active: isActive,
    product_id: entitlement?.product_identifier ?? null,
    expires_at: effectiveExpiration?.toISOString() ?? null,
    original_purchase_at:
      optionalDate(entitlement?.purchase_date)?.toISOString() ?? null,
    last_event_id: context.eventId ?? null,
    last_event_at: context.eventAt?.toISOString() ?? null,
    updated_at: new Date().toISOString(),
  };

  const { error } = await adminClient.from("user_entitlements").upsert(row, {
    onConflict: "user_id",
  });
  if (error) {
    // 23503 is foreign_key_violation: this RevenueCat subscriber has no row in
    // auth.users. That happens for a deleted account whose billing record
    // outlives it, and for dashboard TEST events whose placeholder ids merely
    // look like UUIDs. There is nothing to project, and the caller must still
    // answer 2xx — a 5xx would make RevenueCat retry this forever and
    // eventually disable the webhook.
    if (error.code === "23503") {
      return { isActive: false, productId: null, expiresAt: null, skipped: true };
    }
    throw new Error(`ENTITLEMENT_UPSERT_FAILED:${error.code}`);
  }

  return {
    isActive,
    productId: entitlement?.product_identifier ?? null,
    expiresAt: effectiveExpiration?.toISOString() ?? null,
    skipped: false,
  };
};
