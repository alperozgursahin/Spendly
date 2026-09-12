# Splixa load-test users

This creates 1-30 dedicated Supabase Auth users through the supported Admin
API. Do not insert rows into `auth.users` with SQL.

## 1. Create a one-time secret

Generate a token locally in PowerShell:

```powershell
[Convert]::ToHexString(
  [Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
).ToLower()
```

In Supabase Dashboard, open **Edge Functions > Secrets** and add:

```text
LOAD_TEST_ADMIN_TOKEN=<generated token>
```

## 2. Deploy from Dashboard

1. Open **Edge Functions > Deploy a new function > Via Editor**.
2. Name it `create-load-test-users`.
3. Replace the editor contents with
   `supabase/functions/create-load-test-users/index.ts` from this repository.
4. Disable **Verify JWT** for this function. The function uses the separate,
   constant-time checked `x-load-test-token` secret.
5. Deploy the function.

## 3. Run once in the Dashboard tester

Use method `POST` and add these headers:

```text
Content-Type: application/json
x-load-test-token: <generated token>
```

Request body for 30 users:

```json
{
  "count": 30,
  "prefix": "splixa-loadtest"
}
```

On success the response status is `201` and the body is a JSON array. Save
that body exactly as:

```text
C:\Flutter Projects\Spendly\splixa_test_users.json
```

The file is ignored by Git and is already in the format expected by k6.

## 4. Remove the temporary endpoint

After saving the response:

1. Delete the `create-load-test-users` Edge Function.
2. Delete the `LOAD_TEST_ADMIN_TOKEN` secret.

The generated Auth users remain available for repeatable load tests. They are
email-confirmed without sending email and carry `load_test: true` plus a batch
identifier in their metadata.
