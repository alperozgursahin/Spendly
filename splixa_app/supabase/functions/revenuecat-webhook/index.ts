import {
  isSupabaseUserId,
  syncRevenueCatEntitlement,
} from "../_shared/revenuecat_entitlement.ts";

type JsonObject = Record<string, unknown>;

const jsonResponse = (body: JsonObject, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });

const collectUserIds = (event: JsonObject) => {
  const candidates: unknown[] = [event.app_user_id];
  for (const key of ["aliases", "transferred_from", "transferred_to"]) {
    const values = event[key];
    if (Array.isArray(values)) candidates.push(...values);
  }
  return [...new Set(candidates.filter(isSupabaseUserId))];
};

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }

  const configuredAuthorization = Deno.env.get(
    "REVENUECAT_WEBHOOK_AUTHORIZATION",
  )?.trim();
  const receivedAuthorization = request.headers.get("authorization")?.trim();
  if (
    !configuredAuthorization ||
    !receivedAuthorization ||
    receivedAuthorization !== configuredAuthorization
  ) {
    return jsonResponse({ error: { code: "UNAUTHORIZED" } }, 401);
  }

  let payload: JsonObject;
  try {
    payload = await request.json() as JsonObject;
  } catch {
    return jsonResponse({ error: { code: "INVALID_BODY" } }, 400);
  }

  const event = payload.event;
  if (typeof event !== "object" || event === null || Array.isArray(event)) {
    return jsonResponse({ error: { code: "INVALID_EVENT" } }, 400);
  }
  const eventObject = event as JsonObject;

  // A dashboard TEST event carries invented identifiers. Acknowledge it so the
  // integration check passes on reachability and authorization alone, without
  // writing an entitlement for a subscriber this app has never seen.
  if (eventObject.type === "TEST") {
    return jsonResponse({ received: true, processed: 0, test: true });
  }

  const userIds = collectUserIds(eventObject);

  // RevenueCat dashboard TEST events often use a placeholder non-UUID user.
  // Acknowledge them without ever creating an unaffiliated database record.
  if (userIds.length === 0) {
    return jsonResponse({ received: true, processed: 0 });
  }

  const eventTimestamp = typeof eventObject.event_timestamp_ms === "number"
    ? new Date(eventObject.event_timestamp_ms)
    : new Date();
  const eventId = typeof eventObject.id === "string" ? eventObject.id : null;

  try {
    const results = await Promise.all(
      userIds.map((userId) =>
        syncRevenueCatEntitlement(userId, {
          eventId,
          eventAt: eventTimestamp,
        })
      ),
    );
    const processed = results.filter((result) => !result.skipped).length;
    return jsonResponse({
      received: true,
      processed,
      skipped: results.length - processed,
    });
  } catch (error) {
    console.error(
      "RevenueCat webhook sync failed",
      error instanceof Error ? error.message : "unknown",
    );
    // RevenueCat retries non-2xx webhook responses. No secret, payload, email,
    // receipt, or user identifier is written to logs.
    return jsonResponse({ error: { code: "SYNC_FAILED" } }, 503);
  }
});
