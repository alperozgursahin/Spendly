  import { createClient } from "npm:@supabase/supabase-js@2";

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body, null, 2), {
      status,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": "no-store",
      },
    });

  const secretKeyFromEnvironment = () => {
    const legacy =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
      Deno.env.get("SUPABASE_SECRET_KEY");
    if (legacy) return legacy;

    try {
      const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}") as
        Record<string, string>;
      return keys.default ?? Object.values(keys)[0];
    } catch {
      return undefined;
    }
  };

  const constantTimeEqual = (left: string, right: string) => {
    const encoder = new TextEncoder();
    const leftBytes = encoder.encode(left);
    const rightBytes = encoder.encode(right);
    let difference = leftBytes.length ^ rightBytes.length;
    const length = Math.max(leftBytes.length, rightBytes.length);

    for (let index = 0; index < length; index += 1) {
      difference |= (leftBytes[index] ?? 0) ^ (rightBytes[index] ?? 0);
    }
    return difference === 0;
  };

  const randomPassword = () => {
    const bytes = crypto.getRandomValues(new Uint8Array(24));
    const base64 = btoa(String.fromCharCode(...bytes));
    return `${base64.replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "")}aA1!`;
  };

  const cleanPrefix = (value: unknown) => {
    const prefix = String(value ?? "splixa-loadtest")
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9-]/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 24);
    return prefix || "splixa-loadtest";
  };

  Deno.serve(async (request: Request) => {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const expectedToken = Deno.env.get("LOAD_TEST_ADMIN_TOKEN") ?? "";
    const suppliedToken = request.headers.get("x-load-test-token") ?? "";
    if (
      expectedToken.length < 32 ||
      !constantTimeEqual(suppliedToken, expectedToken)
    ) {
      return json({ error: "Unauthorized" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const secretKey = secretKeyFromEnvironment();
    if (!supabaseUrl || !secretKey) {
      return json({ error: "Supabase admin configuration is unavailable" }, 503);
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Request body must be valid JSON" }, 400);
    }

    const count = Number(body.count ?? 25);
    if (!Number.isInteger(count) || count < 1 || count > 30) {
      return json({ error: "count must be an integer between 1 and 30" }, 400);
    }

    const prefix = cleanPrefix(body.prefix);
    const batch = Date.now().toString(36);
    const admin = createClient(supabaseUrl, secretKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const created: Array<{ email: string; password: string }> = [];

    for (let index = 1; index <= count; index += 1) {
      const suffix = String(index).padStart(2, "0");
      const username = `loadtest_${batch}_${suffix}`;
      const email = `${prefix}-${batch}-${suffix}@example.com`;
      const password = randomPassword();

      const { error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { username, load_test: true, load_test_batch: batch },
        app_metadata: { load_test: true, load_test_batch: batch },
      });

      if (error) {
        return json(
          {
            error: `Creation stopped at user ${index}: ${error.message}`,
            batch,
            created,
          },
          500,
        );
      }

      created.push({ email, password });
    }

    // The response is intentionally the exact array format consumed by k6.
    // Save it as splixa_test_users.json without editing.
    return json(created, 201);
  });
