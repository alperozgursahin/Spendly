import { createClient } from "@supabase/supabase-js";
import { syncRevenueCatEntitlement } from "../_shared/revenuecat_entitlement.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });

const bearerTokenFrom = (request: Request) => {
  const authorization = request.headers.get("authorization")?.trim() ?? "";
  return authorization.match(/^Bearer\s+(.+)$/i)?.[1]?.trim() ?? null;
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  const accessToken = bearerTokenFrom(request);
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: { code: "SERVICE_UNAVAILABLE" } }, 503);
  }
  if (!accessToken) {
    return jsonResponse({ error: { code: "UNAUTHORIZED" } }, 401);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await adminClient.auth.getUser(accessToken);
  if (error || !data.user) {
    return jsonResponse({ error: { code: "UNAUTHORIZED" } }, 401);
  }

  try {
    const entitlement = await syncRevenueCatEntitlement(data.user.id);
    return jsonResponse({ entitlement });
  } catch (syncError) {
    console.error(
      "Authenticated entitlement sync failed",
      syncError instanceof Error ? syncError.message : "unknown",
    );
    return jsonResponse({ error: { code: "SYNC_FAILED" } }, 503);
  }
});
