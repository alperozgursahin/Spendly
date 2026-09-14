import { createClient } from "@supabase/supabase-js";
import { importPKCS8, SignJWT } from "jose";

type JsonObject = Record<string, unknown>;

const reminderBodies: Record<string, string> = {
  en: "You have a friendly expense reminder.",
  tr: "Bir gider için nazik bir hatırlatman var.",
  es: "Tienes un recordatorio amistoso de un gasto.",
  pt: "Você recebeu um lembrete amigável de despesa.",
  de: "Du hast eine freundliche Ausgabenerinnerung.",
  fr: "Vous avez reçu un rappel amical de dépense.",
  it: "Hai ricevuto un promemoria amichevole per una spesa.",
  nl: "Je hebt een vriendelijke uitgavenherinnering.",
  ru: "У вас есть дружеское напоминание о расходе.",
  ar: "لديك تذكير ودي بمصروف.",
  hi: "आपके लिए खर्च का एक विनम्र रिमाइंडर है।",
  id: "Anda menerima pengingat pengeluaran yang ramah.",
};

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: JsonObject, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

const accessToken = async (serviceAccount: JsonObject) => {
  const email = serviceAccount.client_email;
  const privateKey = serviceAccount.private_key;
  const tokenUri = typeof serviceAccount.token_uri === "string"
    ? serviceAccount.token_uri
    : "https://oauth2.googleapis.com/token";
  if (typeof email !== "string" || typeof privateKey !== "string") {
    throw new Error("INVALID_FIREBASE_SERVICE_ACCOUNT");
  }
  const key = await importPKCS8(privateKey, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(email)
    .setSubject(email)
    .setAudience(tokenUri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`FIREBASE_AUTH_FAILED:${response.status}`);
  const payload = await response.json() as JsonObject;
  if (typeof payload.access_token !== "string") throw new Error("FIREBASE_TOKEN_MISSING");
  return payload.access_token;
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  const authorization = request.headers.get("authorization") ?? "";
  if (!url || !anonKey || !serviceKey || !authorization.startsWith("Bearer ")) {
    return json({ error: "UNAUTHORIZED" }, 401);
  }

  let body: JsonObject;
  try {
    body = await request.json() as JsonObject;
  } catch {
    return json({ error: "INVALID_BODY" }, 400);
  }
  if (typeof body.expense_id !== "string" || typeof body.recipient_id !== "string") {
    return json({ error: "INVALID_BODY" }, 400);
  }

  const callerClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: reminder, error: reminderError } = await callerClient.rpc(
    "send_debt_reminder_v1",
    { p_expense_id: body.expense_id, p_recipient_id: body.recipient_id },
  );
  if (reminderError) {
    return json({ error: reminderError.message }, 400);
  }

  const recipientId = (reminder as JsonObject).recipient_id;

  // Past this point the reminder row and the in-app notification are already
  // committed by send_debt_reminder_v1. Push delivery is strictly best-effort,
  // so every failure below must still return 200: a 500 here would show the
  // sender an error for a reminder that was in fact delivered, and their retry
  // would then be rejected as REMINDER_RATE_LIMITED.
  let sent = 0;
  try {
    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: tokenRows, error: tokenError } = await admin
      .from("push_tokens")
      .select("token, language_code")
      .eq("user_id", recipientId);
    if (tokenError) {
      console.error("Push token lookup failed", tokenError.code);
      return json({ sent: 0, in_app_created: true });
    }

    const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
    if (!rawServiceAccount || !firebaseProjectId || !tokenRows?.length) {
      // Recovers on its own once the console secrets are configured.
      return json({ sent: 0, in_app_created: true });
    }

    const oauthToken = await accessToken(JSON.parse(rawServiceAccount) as JsonObject);
    const results = await Promise.allSettled(tokenRows.map(async ({ token, language_code }) => {
      const localizedBody = reminderBodies[String(language_code)] ?? reminderBodies.en;
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(firebaseProjectId)}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${oauthToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: "Splixa",
                body: localizedBody,
              },
              data: {
                type: "debt_reminder",
                group_id: String((reminder as JsonObject).group_id ?? ""),
                expense_id: String((reminder as JsonObject).expense_id ?? ""),
              },
              android: { priority: "high" },
              apns: { payload: { aps: { sound: "default" } } },
            },
          }),
        },
      );
      if (!response.ok) throw new Error(`FCM_SEND_FAILED:${response.status}`);
    }));
    sent = results.filter((result) => result.status === "fulfilled").length;
  } catch (pushError) {
    console.error(
      "Debt reminder push delivery failed",
      pushError instanceof Error ? pushError.message : "unknown",
    );
  }
  return json({ sent, in_app_created: true });
});
