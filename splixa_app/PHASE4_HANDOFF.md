# Phase 4 Handoff — Monetization & PRO Tier

## Read this first

Phase 4 is **in progress, uncommitted, and not yet validated**. Do not discard
the working tree and do not begin Phase 5. Continue from the files listed here.
The owner explicitly prefers to build APK/AAB manually; do not spend time or
tokens on a release build unless they reverse that instruction.

The last clean commit before this phase is:

`884027b feat(ux): complete onboarding polish and product experiments`

All current Phase 4 changes are intentionally uncommitted. Preserve unrelated
changes. Use `apply_patch` for source edits.

## Current blocker

The local Dart toolchain started hanging during validation. `dart analyze`,
`dart format lib test`, and finally even `dart --version` created a Dart process
that used roughly 550–620 MB and then stopped producing output. The stuck
processes were terminated explicitly. This is a local SDK/process problem, not
yet evidence of a source error.

Before continuing validation:

1. Confirm no stale Dart process: `Get-Process dart -ErrorAction SilentlyContinue`.
2. Try `flutter doctor -v` or
   `C:\Users\alper\flutter\bin\cache\dart-sdk\bin\dart.exe --version`.
3. If it still stalls, inspect Flutter/Dart cache locks and running IDE analysis
   servers. Do not delete the SDK or `.dart_tool` without establishing the
   target and explaining why.
4. Once the SDK responds, run `dart format lib test`,
   `flutter analyze --no-pub`, and `flutter test`.

No successful Phase 4 analyzer or test result has been obtained yet.

## Implemented: entitlement and server limits

### `supabase/migrations/20260913000100_phase4_pro_entitlements_and_limits.sql`

- Adds `user_entitlements`, a client-read-only projection of RevenueCat's
  `pro` entitlement.
- Adds server helpers `has_active_pro_entitlement` and
  `splixa_actor_has_pro`.
- Adds profile timezone and `set_profile_timezone_v1`.
- Adds `pro_usage_v1`.
- Enforces max 2 groups and max 50 personal expense rows per local calendar
  month with security-definer triggers and advisory locks.
- Adds atomic `create_group_v1` and `create_personal_transaction_v1` RPCs.
- Defines limits as current memberships/owned groups and successful personal
  `expense` inserts. Group expenses and income do not consume the 50 limit;
  deleting a personal expense currently releases one slot.

### RevenueCat Edge Functions

- `supabase/functions/_shared/revenuecat_entitlement.ts`
- `supabase/functions/revenuecat-webhook/index.ts`
- `supabase/functions/sync-pro-entitlement/index.ts`
- corresponding entries in `supabase/config.toml`

The webhook validates a configured authorization header, filters RevenueCat
aliases to Supabase UUIDs, looks up current subscriber state from RevenueCat,
and writes with the service role. Client sync verifies the caller JWT and only
syncs that authenticated user's ID.

Required production secrets (never commit values):

- `REVENUECAT_SECRET_API_KEY`
- `REVENUECAT_WEBHOOK_AUTHORIZATION`
- optional `REVENUECAT_PREMIUM_ENTITLEMENT_ID=pro`

RevenueCat must be configured to send webhooks to the deployed
`revenuecat-webhook` function with the exact authorization value.

### Flutter entitlement work

- `premium_provider.dart` publishes server usage, syncs RevenueCat to the
  backend, propagates `CustomerInfo`, surfaces offering errors, and caches only
  a bounded seven-day verified offline entitlement.
- `pro_access.dart` centralizes user-facing Pro gates and source analytics.
- Group and personal writes use the new atomic RPCs.
- Dashboard/group creation paths preflight the limits, while PostgreSQL remains
  authoritative against modified clients and concurrent requests.

## Implemented: paid feature backend

### `supabase/migrations/20260913000200_phase4_pro_features.sql`

- `custom_categories` with Pro RLS; ARGB color is `bigint`, not signed
  `integer`.
- `expense_attachments` plus private `receipt-attachments` Storage bucket and
  membership/owner policies.
- `recurring_expense_templates` and idempotent `(template_id, due_at)` runs.
- Scheduled recurring generation requires service role and pauses templates
  whose Pro entitlement ends.
- Automatic EUR/USD recurring entries lock a fresh Open ER API rate at each
  occurrence; deliberately manual rates stay fixed and preserve their original
  lock timestamp. Missing automatic rates write nothing and retry later.
- `push_tokens` with locale, owner policies, and an atomic
  `register_push_token_v1` RPC that transfers a reused device token between
  accounts to prevent cross-account notification leakage.
- `debt_reminders`, recipient opt-out, creditor-only validation, one reminder
  per debt per 24h, and sender max five reminders per 24h.
- Free direct ledger writes cannot bypass Custom Categories or
  `manual_user_locked` FX: a server trigger requires Pro.

New backend functions:

- `generate-recurring-expenses`: bearer job secret, current TRY-based FX fetch,
  service-role RPC.
- `send-debt-reminder`: authenticated caller, server RPC authorization, durable
  in-app notification, best-effort FCM HTTP v1 push. Push copy is selected from
  the device token's 12-language locale and contains no balance/amount/PII.

Additional production secrets:

- `RECURRING_JOB_SECRET`
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `FIREBASE_PROJECT_ID`

The recurring function needs a scheduled POST with
`Authorization: Bearer <RECURRING_JOB_SECRET>` after deployment.

## Implemented: Pro feature Flutter UI/services

- Biometric lifecycle lock: `app_lock_service.dart`; Android permission and
  `FlutterFragmentActivity`; iOS Face ID reason.
- Home widget: `home_widget_service.dart`, Android provider/resources and deep
  link. iOS Swift widget source exists under `ios/SplixaQuickAddWidget/` but is
  **not an Xcode extension target yet** (see manual blockers).
- Receipt OCR: `receipt_service.dart` uses ML Kit, camera/gallery, compression,
  private upload, five-minute signed URLs, localized amount parsing, confidence,
  and mandatory form review. `add_expense_sheet.dart` uploads only after the
  normalized expense succeeds.
- `ReceiptTextParser` was extracted for unit testing.
- Custom categories: reusable model/provider, create/update/delete, emoji and
  ARGB palette; personal Quick Add lists them.
- Recurring expense management: create, activate/pause, delete. Reactivation
  schedules a future run so lapsed subscription periods are not backfilled.
- Debt reminder buttons appear only on appropriate approved/payment-pending
  debtor shares and invoke the secured Edge Function.
- Custom FX: personal/group forms persist exact original amount, currency,
  locked rate, rate source, and timestamp without rewriting history.
- Advanced PDF/CSV export: CSV includes original/base/FX audit columns; PDF
  converts totals into the selected display currency and uses `AppFormat`.
- Advanced analytics: category chart/heatmap plus custom date range; direct
  route is Pro-guarded.
- Privacy-safe trip summary PNG: totals/count/top category only; direct route is
  Pro-guarded.
- `pro_tools_screen.dart` is reachable from Profile and manages Pro tools.
- Friendly errors, analytics sources/events, 12 localization dictionaries,
  Android/iOS platform permissions, routes, and profile entry were updated.

## Implemented: paywall

- Monthly, annual, lifetime packages are ordered from RevenueCat offerings.
- Every visible amount uses `StoreProduct.priceString` or
  `pricePerMonthString`; no subscription currency symbol is reconstructed.
- Annual is marked Best Value only when its numeric store price is actually
  lower than 12 monthly purchases.
- Lifetime has non-renewing language.
- A monthly “7-day trial” badge/disclosure appears only when Android reports an
  exact `P1W` free phase or Apple reports an eligible zero-price `P1W`, one-cycle
  introductory offer.
- Lottie hero has reduced-motion/error fallback.
- Restore, close/free path, Terms, Privacy, recurring billing disclosure,
  purchase analytics and global entitlement refresh remain wired.
- One automatic post-auth/onboarding paywall is frequency-capped to 30 days.
- Third-group/50th-personal-expense and every locked feature use distinct
  paywall sources.

## Tests and validation assets added

- `test/receipt_text_parser_test.dart` tests localized totals, fallback
  selection and unusable OCR.
- `supabase/tests/phase4_pro_guards_rollback_smoke.sql` fills rollback-only rows
  and asserts the 50/month limit, two-group limit, custom category gate and
  manual-FX gate.
- Existing `normalized_financial_rpc_smoke.sql` category changed from arbitrary
  `test` to built-in `Diğer` so the free custom-category guard does not
  invalidate the ledger lifecycle smoke test.

These tests have **not run yet** because of the Dart toolchain blocker and
because the new migrations have not been deployed.

## Deployment — DONE (13 Sep 2026)

Applied to the live project `lbalfjhpfslvqigdmbdg` by the owner via
`supabase db push`, then verified: 8/8 new tables, 10/10 functions, 6/6
triggers, the `receipt-attachments` bucket and its 3 storage policies, and both
new `profiles` columns are present.

All four Edge Functions are ACTIVE. Their successful deploy also served as the
TypeScript check — Deno could not be installed in the assistant's container
(blocked by the egress proxy), so bundling stands in for `deno check`.

The five production secrets are set via the dashboard (never through shell
history): `REVENUECAT_SECRET_API_KEY`, `REVENUECAT_WEBHOOK_AUTHORIZATION`,
`RECURRING_JOB_SECRET`, `FIREBASE_PROJECT_ID`,
`FIREBASE_SERVICE_ACCOUNT_JSON`.

### Server-side guard tests — ALL PASS

Run against production inside `BEGIN … ROLLBACK`, so no rows persisted.

| Check | Result |
| --- | --- |
| 50 personal expenses/month limit | enforced server-side |
| Two-group limit | enforced server-side |
| Custom-category Pro gate on a direct ledger write | rejected |
| Custom-FX (`manual_user_locked`) Pro gate on a direct write | rejected |
| Normal personal transaction by a free user | succeeds |
| Group expense insert by a free user | succeeds |
| Group creation by an under-quota free user | succeeds |

The last three matter as much as the rejections: they are what the generic
trigger defect would have broken.

### RevenueCat webhook — verified end to end

`https://<project>.supabase.co/functions/v1/revenuecat-webhook`, authorization
header matched, dashboard TEST event returns
`200 {"received":true,"processed":0,"test":true}`.

Getting there exposed a third production defect, fixed:

**Unknown subscriber crashed the webhook.** `syncRevenueCatEntitlement` upserts
into `user_entitlements`, whose `user_id` is a foreign key to `auth.users`. Any
RevenueCat subscriber without a matching Supabase account raised
`ENTITLEMENT_UPSERT_FAILED:23503` (foreign_key_violation) and the webhook
answered 503. Since this app supports account deletion, a deleted user's
surviving billing record would have made RevenueCat retry forever and
eventually disable the webhook — after which *no* subscription would reach the
server for *any* user. The existing guard assumed TEST events use non-UUID
identifiers; the real ones are UUID-shaped, so it never fired.

Fix: `23503` is now treated as "this subscriber has no account here" and
skipped with a 2xx; the response reports `processed` and `skipped` separately.
`type: "TEST"` events are acknowledged without touching the database.

### Two Edge Function defects fixed during review

- `send-debt-reminder` threw after the reminder row and in-app notification
  were already committed, so a push failure returned 500 for a reminder that
  had in fact been delivered — and the user's retry then hit
  `REMINDER_RATE_LIMITED`. Push delivery is now wrapped so every path returns
  200.
- The receipt-deletion queue pinned `attempts` to the literal `1`, so a
  permanently undeletable object retried silently forever. It now increments.

## Exact next work

1. Repair/clear the local Dart toolchain hang without deleting user work.
2. Run formatter and analyzer. Fix every compile/lint error. Likely areas:
   - RevenueCat trial/pricing API usage in `paywall_screen.dart`.
   - `HomeWidget.setAppGroupId` and `requestPinWidget` signatures.
   - `local_auth` API and Riverpod `Ref.listen` signatures.
   - `flutter_timezone` result API.
   - `share_plus` `ShareParams`/`XFile.fromData` signatures.
3. Run all Flutter tests, localization catalog/key-usage tests, and
   `git diff --check`.
4. Inspect the Phase 4 migrations for PostgreSQL syntax. Specifically verify
   that generic `splixa_enforce_paid_ledger_features` can access the
   table-specific `NEW.user_id`/`NEW.created_by` branches. Split it into two
   trigger functions if PostgreSQL rejects generic record field access.
5. Run `deno check` for all four new Edge Functions if Deno is available. If
   not, use Supabase's function bundler without deploying.
6. Add/verify attachment deletion and object-retention cleanup. Current DB rows
   cascade with expenses, but Storage object deletion is not guaranteed; this
   is an incomplete requirement.
7. Decide whether to add personal-expense receipt attachment UI. Current OCR
   and photo flow is implemented in group Add Expense only.
8. Localize native Android widget strings for 12 shipped locales and add an iOS
   localization catalog. Flutter-side strings are translated, native widget
   strings currently default to English.
9. Finish iOS widget setup manually on macOS/Xcode: create Widget Extension
   target, add App Group `group.net.splixa.app` to Runner and extension, include
   the Swift file/assets, and verify signing. This cannot be completed or built
   from the current Windows environment.
10. Prepare deployment/runbook commands, but do not mutate production before
    owner review unless explicitly requested.
11. Update Phase 4 checkboxes/evidence honestly, bump `pubspec.yaml` (likely
    `0.8.0-alpha+8`), make one focused conventional commit, and stop for review.
    Do not push unless asked.

## Known caveats

- RevenueCat offering correctness, real trial eligibility, grace, lifetime and
  localized store prices require sandbox/licence-tester checks; source alone
  cannot prove console configuration.
- iOS widget delivery is incomplete until its Xcode target/App Group exists.
- Attachment Storage-object cleanup is incomplete as noted above.
- The app selector currently supports TRY, USD and EUR. The normalized schema
  permits USDT, but Phase 4 did not add USDT UI/rate sourcing.
- The post-auth paywall may appear once to an existing free user after updating,
  not only to a brand-new registration; it is capped to once per 30 days.
- Do not mark Phase 4 complete or production-ready until analyzer/tests,
  migration smoke tests, Edge Function checks, RevenueCat sandbox checks and
  manual platform requirements are evidenced.

## Current working-tree overview

Modified/new areas include Android widget/platform files, the iOS scaffold,
analytics and localization, dashboard/group/profile/paywall/provider files,
new subscription/notification/OCR services, dependencies, Supabase config,
two migrations, four Edge Functions and rollback smoke tests. Run
`git status --short` for the authoritative list.
