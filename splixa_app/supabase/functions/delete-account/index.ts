import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonObject = Record<string, unknown>;

const jsonResponse = (body: JsonObject, status = 200) =>
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
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() ?? null;
};

const removeFolderObjects = async (
  adminClient: ReturnType<typeof createClient>,
  bucket: string,
  folder: string,
) => {
  const paths: string[] = [];
  let offset = 0;
  const limit = 100;

  while (true) {
    const { data, error } = await adminClient.storage
      .from(bucket)
      .list(folder, { limit, offset, sortBy: { column: "name", order: "asc" } });

    if (error) throw new Error(`${bucket} listing failed: ${error.message}`);
    const objects = (data ?? []).filter((item) => item.id !== null);
    paths.push(...objects.map((item) => `${folder}/${item.name}`));
    if ((data ?? []).length < limit) break;
    offset += limit;
  }

  if (paths.length === 0) return;
  const { error } = await adminClient.storage.from(bucket).remove(paths);
  if (error) throw new Error(`${bucket} deletion failed: ${error.message}`);
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
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("delete-account is missing required Supabase secrets");
    return jsonResponse(
      { error: { code: "SERVICE_UNAVAILABLE", message: "Deletion service unavailable." } },
      503,
    );
  }

  const accessToken = bearerTokenFrom(request);
  if (!accessToken) {
    return jsonResponse(
      { error: { code: "UNAUTHORIZED", message: "Authentication required." } },
      401,
    );
  }

  let body: JsonObject;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(
      { error: { code: "INVALID_BODY", message: "Invalid request body." } },
      400,
    );
  }
  if (body.confirmation !== "DELETE") {
    return jsonResponse(
      { error: { code: "CONFIRMATION_REQUIRED", message: "Type DELETE to confirm." } },
      400,
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Verify the presented JWT with Supabase Auth and derive the target id only
  // from that verified token. The request cannot supply another user's id.
  const { data: userResult, error: userError } =
    await adminClient.auth.getUser(accessToken);
  const user = userResult.user;
  if (userError || !user) {
    return jsonResponse(
      { error: { code: "UNAUTHORIZED", message: "Invalid or expired session." } },
      401,
    );
  }

  try {
    const { data: prepared, error: preparationError } = await adminClient.rpc(
      "prepare_account_deletion_v1",
      { p_user_id: user.id },
    );
    if (preparationError) {
      console.error("Account deletion preparation failed", preparationError.code);
      return jsonResponse(
        { error: { code: "PREPARATION_FAILED", message: "Account deletion could not be prepared." } },
        500,
      );
    }

    const result = (prepared ?? {}) as JsonObject;
    if (result.allowed !== true) {
      return jsonResponse(
        {
          error: {
            code: String(result.code ?? "DELETION_BLOCKED"),
            message: String(result.message ?? "Account deletion is currently blocked."),
            groups: Array.isArray(result.groups) ? result.groups : [],
          },
        },
        409,
      );
    }

    // Storage is outside the PostgreSQL transaction. This step is retry-safe:
    // preparation is idempotent and Auth deletion happens only after all known
    // profile objects have been removed.
    await removeFolderObjects(adminClient, "avatars", user.id);
    const soloGroupIds = Array.isArray(result.deleted_solo_group_ids)
      ? result.deleted_solo_group_ids
          .map((value) => String(value))
          .filter((value) => /^[0-9a-f-]{36}$/i.test(value))
      : [];
    for (const groupId of soloGroupIds) {
      await removeFolderObjects(adminClient, "group_avatars", groupId);
    }

    const { error: deletionError } =
      await adminClient.auth.admin.deleteUser(user.id);
    if (deletionError) {
      console.error("Auth user deletion failed", deletionError.status);
      return jsonResponse(
        { error: { code: "AUTH_DELETE_FAILED", message: "Account deletion could not be completed." } },
        500,
      );
    }

    return jsonResponse({ deleted: true });
  } catch (error) {
    console.error(
      "delete-account failed",
      error instanceof Error ? error.message : "unknown error",
    );
    return jsonResponse(
      { error: { code: "DELETION_FAILED", message: "Account deletion could not be completed." } },
      500,
    );
  }
});
