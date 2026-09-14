import { createClient } from "@supabase/supabase-js";

// Supabase's cron UI caps pg_net's timeout at 5000 ms, but this job fetches
// live FX rates, generates up to 200 recurring expenses and drains the receipt
// deletion queue — occasionally longer than that. Acknowledging immediately and
// finishing under EdgeRuntime.waitUntil decouples the work from the caller's
// timeout entirely, so a slow run can never be cut short or silently skipped.
const runInBackground = (task: Promise<unknown>) => {
  const runtime = (globalThis as Record<string, unknown>).EdgeRuntime as
    | { waitUntil?: (promise: Promise<unknown>) => void }
    | undefined;
  if (typeof runtime?.waitUntil === "function") {
    runtime.waitUntil(task);
  } else {
    void task;
  }
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  const expected = Deno.env.get("RECURRING_JOB_SECRET")?.trim();
  const received = request.headers.get("authorization")?.trim();
  if (!expected || received !== `Bearer ${expected}`) {
    return json({ error: "UNAUTHORIZED" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) return json({ error: "SERVICE_UNAVAILABLE" }, 503);

  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const job = async () => {
    let usdPerTry: number | null = null;
    let eurPerTry: number | null = null;
    let rateLockedAt: string | null = null;
    try {
      const ratesResponse = await fetch(
        "https://open.er-api.com/v6/latest/TRY",
        { signal: AbortSignal.timeout(5_000) },
      );
      if (ratesResponse.ok) {
        const ratesPayload = await ratesResponse.json() as Record<string, unknown>;
        const rates = ratesPayload.rates as Record<string, unknown> | undefined;
        const usd = rates?.USD;
        const eur = rates?.EUR;
        if (
          ratesPayload.result === "success" &&
          ratesPayload.base_code === "TRY" &&
          typeof usd === "number" && usd > 0 &&
          typeof eur === "number" && eur > 0
        ) {
          usdPerTry = usd;
          eurPerTry = eur;
          const timestamp = ratesPayload.time_last_update_unix;
          rateLockedAt = typeof timestamp === "number"
            ? new Date(timestamp * 1000).toISOString()
            : new Date().toISOString();
        }
      }
    } catch {
      // TRY and manually locked templates can still run. Automatic FX templates
      // remain due and retry without ever writing an invented conversion rate.
    }
    const { data, error } = await client.rpc("generate_due_recurring_expenses_v1", {
      p_usd_per_try: usdPerTry,
      p_eur_per_try: eurPerTry,
      p_rate_locked_at: rateLockedAt,
      p_rate_source: "scheduled_open_er_api",
      p_limit: 200,
    });
    if (error) {
      // Log the whole error: a PostgREST failure (stale schema cache, overload
      // resolution, permissions) carries its detail in message/details/hint,
      // and `code` alone is often empty.
      console.error(
        "Recurring generation failed",
        JSON.stringify({
          code: error.code ?? null,
          message: error.message ?? null,
          details: error.details ?? null,
          hint: error.hint ?? null,
        }),
      );
      return;
    }

    // Storage objects live outside PostgreSQL, so the attachment-row cascade
    // cannot delete the bytes. Draining the queue here keeps the whole Phase 4
    // background job to one schedule instead of two.
    const { data: queuedObjects, error: queueError } = await client
      .from("receipt_storage_deletion_queue")
      .select("storage_path, attempts")
      .order("queued_at")
      .limit(200);
    let removedObjects = 0;
    if (queueError) {
      console.error("Receipt deletion queue read failed", queueError.code);
    } else if (queuedObjects?.length) {
      const paths = queuedObjects.map(({ storage_path }) => storage_path);
      const { error: storageError } = await client.storage
        .from("receipt-attachments")
        .remove(paths);
      if (!storageError) {
        const { error: deleteQueueError } = await client
          .from("receipt_storage_deletion_queue")
          .delete()
          .in("storage_path", paths);
        if (deleteQueueError) {
          console.error("Receipt queue cleanup failed", deleteQueueError.code);
        } else {
          removedObjects = paths.length;
        }
      } else {
        // Keep the rows queued, but record the attempt so a permanently failing
        // object becomes visible instead of silently retrying forever. This job
        // runs on a single schedule, so a read-then-write increment is safe.
        console.error("Receipt object removal failed", storageError.message);
        await Promise.all(queuedObjects.map(({ storage_path, attempts }) =>
          client
            .from("receipt_storage_deletion_queue")
            .update({ attempts: Math.min((attempts ?? 0) + 1, 1000) })
            .eq("storage_path", storage_path)
        ));
      }
    }
    console.log(
      `Recurring job finished: generated=${data} removed_receipt_objects=${removedObjects}`,
    );
  };

  runInBackground(
    job().catch((jobError) =>
      console.error(
        "Recurring job crashed",
        jobError instanceof Error ? jobError.message : "unknown",
      )
    ),
  );
  return json({ accepted: true }, 202);
});
