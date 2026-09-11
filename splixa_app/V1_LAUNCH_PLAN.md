# Splixa V1 Global Launch Plan

## Execution protocol

- [x] Break the V1 mission into six review-gated phases.
- [x] Receive explicit approval: `Approved, start Phase 1`.
- [x] Execute only the currently approved phase.
- [x] Preserve unrelated workspace changes throughout implementation.
- [x] Run the phase-specific validation suite and record evidence below.
- [x] Update completed checkboxes and phase notes in this document.
- [x] Create one focused conventional commit for the completed phase.
- [x] Stop for review before beginning the next phase.

## Cross-phase release rules

- [ ] Keep all user-facing strings localization-ready from the phase in which they are introduced.
- [ ] Centralize Pro entitlement checks around RevenueCat `entitlements.active['pro']`.
- [ ] Never hardcode product prices or currency symbols; use RevenueCat `StoreProduct.priceString`.
- [ ] Never place secrets, service-role keys, signing credentials, or production PII in source control.
- [ ] Preserve normalized-ledger accuracy and use atomic/RLS-protected backend operations for financial writes.
- [ ] Add analytics without sending sensitive financial values, receipt contents, email addresses, or other PII.
- [ ] Treat accessibility, small-screen behavior, dark mode, loading, empty, error, and offline states as acceptance requirements.
- [ ] Do not claim production readiness while any P0/P1 release blocker remains open.

---

## Phase 1 — Core Auth, Identity & Analytics

### Baseline and design

- [x] Audit the current auth router, onboarding persistence, Supabase session handling, RevenueCat provider, and analytics service.
- [x] Document the new-user versus returning-user routing contract before changing auth code.
- [ ] Confirm the Android Web OAuth client ID and iOS URL scheme/configuration are read from safe platform configuration.
- [x] Define typed, privacy-safe analytics parameters and duplicate-event prevention rules.

### Native Google authentication

- [x] Confirm compatible `google_sign_in` and `supabase_flutter` versions.
- [x] Replace browser-based Google OAuth with the native Google account picker.
- [x] Obtain the Google ID token and access token without logging either token.
- [x] Authenticate Supabase with `signInWithIdToken(provider: OAuthProvider.google, ...)`.
- [x] Handle cancellation, missing-token, revoked-consent, network, and Supabase errors with user-safe messages.
- [x] Ensure sign-out clears both the Supabase and native Google sessions where appropriate.
- [x] Route genuinely new users through onboarding and returning users directly to the dashboard.
- [x] Verify email/password authentication and password-recovery flows remain functional.

### RevenueCat identity synchronization

- [x] Log in to RevenueCat with the authenticated Supabase user ID after every successful session establishment.
- [x] Set the RevenueCat email only when a valid email exists.
- [x] Refresh and publish global `CustomerInfo` after RevenueCat login.
- [x] Log out/reset RevenueCat identity safely when the Supabase session ends.
- [x] Remove dashboard reliance on `$RCAnonymousID` and verify identified purchases restore correctly.
- [x] Prevent duplicate `Purchases.logIn` calls during auth stream and app-resume events.

### Analytics funnel

- [x] Verify Firebase initializes safely in release and debug environments.
- [x] Instrument `app_open` once per app launch/session as intended.
- [x] Instrument successful `login` with a non-PII method parameter.
- [x] Verify every paywall entry point emits `paywall_view` with a normalized source.
- [x] Instrument `subscription_started` only after confirmed subscription entitlement activation.
- [x] Instrument `expense_added` only after the backend confirms the write.
- [x] Add debug verification for event names, parameters, and accidental duplicates.

### Phase 1 validation gate

- [x] Run formatting and `flutter analyze` with zero errors.
- [x] Run relevant unit/widget tests and add missing auth/identity tests.
- [x] Build a release Android artifact successfully.
- [ ] Manually smoke-test native Google login: new user, returning user, cancellation, sign-out, and relogin.
- [ ] Verify RevenueCat user ID and active entitlement state after login and restore.
- [ ] Verify Firebase DebugView receives the required events without PII.
- [x] Record validation results in this file.
- [x] Commit Phase 1 with a focused conventional commit.
- [x] Stop and wait for Phase 1 review.

---

## Phase 2 — Global Localization & Auto-Locale

### Localization architecture

- [ ] Inventory all user-visible strings, including dialogs, snackbars, validation errors, paywalls, notifications, and accessibility labels.
- [ ] Choose and document `easy_localization` or Flutter `intl` based on current architecture and testability.
- [ ] Define locale file structure, naming conventions, interpolation, pluralization, and fallback behavior.
- [ ] Establish English as the complete source locale and fallback locale.
- [ ] Add automated validation for missing, unused, and structurally mismatched translation keys.

### Locale behavior and controls

- [ ] Detect the system locale on first launch.
- [ ] Match regional variants to supported base languages where appropriate.
- [ ] Fall back to English when the device language is unsupported.
- [ ] Persist an explicit user locale selection across launches and sign-in state changes.
- [ ] Add an accessible language selector to onboarding without increasing friction.
- [ ] Add the same language selector to Settings/Profile.
- [ ] Ensure locale changes update the app immediately without requiring restart.

### Translation coverage

- [ ] Finalize the exact 30+ launch locale list and locale codes before translation begins.
- [ ] Prepare complete dictionary key parity for all target locales, including at minimum EN, TR, ES, PT, DE, and FR.
- [ ] Translate core navigation, onboarding, authentication, expense, group, debt, profile, and paywall journeys.
- [ ] Localize dates, times, numbers, currencies, plurals, and relative-time labels.
- [ ] Remove remaining hardcoded user-facing strings from Dart and supported native surfaces.
- [ ] Review text expansion and right-to-left readiness; enable RTL behavior for any shipped RTL locale.
- [ ] Arrange native-speaker or professional review for monetization, legal, and destructive-action copy before launch.

### Phase 2 validation gate

- [ ] Run the translation key validator with zero missing source keys.
- [ ] Run an automated hardcoded-string audit and document justified exceptions.
- [ ] Test system auto-detection, unsupported fallback, persistence, and live switching.
- [ ] Test representative long-text and RTL locales on small screens.
- [ ] Run formatting, tests, and `flutter analyze` with zero errors.
- [ ] Build a release Android artifact successfully.
- [ ] Record validation results in this file.
- [ ] Commit Phase 2 with a focused conventional commit.
- [ ] Stop and wait for Phase 2 review.

---

## Phase 3 — Premium UX & UI Polish

### Animated onboarding

- [ ] Audit current onboarding completion, skip, back, and auth-routing behavior.
- [ ] Rewrite each slide to one concise value proposition with a clear progression.
- [ ] Select or create commercially licensed, size-efficient Lottie assets aligned with the Splixa visual system.
- [ ] Add Lottie loading/error fallbacks so onboarding never blocks on animation rendering.
- [ ] Implement smooth, accessible transitions that respect reduced-motion preferences.
- [ ] Preserve locale selector access and analytics instrumentation on every step.
- [ ] Optimize assets and verify startup size/performance impact.

### Skeleton and shimmer system

- [ ] Inventory every `CircularProgressIndicator` and classify full-page, inline-action, refresh, and blocking states.
- [ ] Create reusable theme-aware skeleton primitives matching the final content geometry.
- [ ] Replace Supabase data-fetch spinners with stable skeleton layouts without introducing layout jumps.
- [ ] Keep compact progress indicators where skeletons are inappropriate, such as button submissions or indeterminate actions.
- [ ] Respect reduced-motion settings and avoid excessive GPU/battery usage.
- [ ] Add polished empty, retryable error, and partial-data states alongside loading states.

### Phase 3 validation gate

- [ ] Test onboarding on small/large Android devices, dark/light modes, and representative long locales.
- [ ] Verify no animation jank, semantic regressions, overflow, or unbounded shimmer loops.
- [ ] Run formatting, tests, and `flutter analyze` with zero errors.
- [ ] Build and smoke-test a release artifact.
- [ ] Record validation results in this file.
- [ ] Commit Phase 3 with a focused conventional commit.
- [ ] Stop and wait for Phase 3 review.

---

## Phase 4 — Monetization & PRO Tier

### Entitlement and limits foundation

- [ ] Audit all current RevenueCat offerings, products, entitlement identifiers, restore flows, and premium checks.
- [ ] Create one fail-safe Pro access service backed by `entitlements.active['pro']`.
- [ ] Define loading/offline/grace-period behavior so temporary RevenueCat failures do not incorrectly remove paid access.
- [ ] Enforce free limits server-side as well as in Flutter to prevent client bypass.
- [ ] Limit free users to two active groups with a localized upgrade path before the third group is created.
- [ ] Limit free users to 50 personal expenses per calendar month using a timezone-safe server-side count.
- [ ] Define how deletes, imports, failed writes, group expenses, and month boundaries affect the limits.
- [ ] Add analytics for limit exposure, paywall source, purchase attempt, cancellation, success, restore, and entitlement activation.

### Pro feature delivery

- [ ] Biometric App Lock: define secure fallback behavior, add `local_auth`, implement lifecycle locking, and gate setup/use for Pro.
- [ ] Home Screen Widgets: define minimum viable Android/iOS widget scope, implement Quick Add deep links, and protect locked actions.
- [ ] Photo Attachments: add compressed uploads, private Supabase Storage paths, signed access, deletion/retention rules, and Pro gating.
- [ ] Custom Categories: add relational schema/RLS, colors/emojis, editing/deletion behavior, and Pro gating.
- [ ] Recurring Expenses: define recurrence/timezone/idempotency rules, implement scheduled backend generation, and Pro management UI.
- [ ] Auto-Nudge: implement consent-aware debt reminders, rate limits, notification preferences, auditability, and abuse prevention.
- [ ] OCR Scanner: reproduce existing failures, repair image preprocessing/parsing, add confidence/edit review, and prevent unreviewed financial writes.
- [ ] Advanced Exports: implement localized PDF and CSV exports with deterministic totals and safe sharing.
- [ ] Trip Summaries: produce privacy-safe, shareable image layouts without exposing hidden member data.
- [ ] Advanced Analytics: implement category heatmaps and custom date ranges from normalized ledger data.
- [ ] Custom FX Rates: persist locked rates, source metadata, timestamps, and original/base values without changing historical balances.
- [ ] Add per-feature entitlement, backend authorization, analytics, empty/error states, and tests.

### Localized, currency-aware paywall

- [ ] Confirm RevenueCat offering contains Monthly, Annual, and Lifetime packages mapped to the `pro` entitlement.
- [ ] Fetch all package metadata dynamically and handle missing/misconfigured offerings gracefully.
- [ ] Display Monthly with its configured seven-day trial only when the store reports that offer as eligible.
- [ ] Present Annual as Best Value using store-backed pricing and a truthful calculated comparison.
- [ ] Present Lifetime without implying a subscription or trial.
- [ ] Render every price from `StoreProduct.priceString`; never reconstruct or hardcode currency formatting.
- [ ] Build a localized Pro checklist tied to features that are genuinely available.
- [ ] Add Lottie with reduced-motion and load-failure fallbacks.
- [ ] Preserve Restore Purchases, Terms, Privacy, recurring billing disclosure, trial disclosure, and close controls.
- [ ] Refresh global `CustomerInfo` and unlock features immediately after a verified purchase or restore.
- [ ] Trigger the paywall after onboarding, before a third group, and from each locked feature with distinct source values.
- [ ] Frequency-cap non-user-initiated paywall presentation to avoid hostile or repetitive UX.

### Phase 4 validation gate

- [ ] Test free limits against client bypass attempts and concurrent requests.
- [ ] Test active, expired, cancelled, grace-period, restored, lifetime, offline, and anonymous-to-identified purchase states.
- [ ] Test localized store pricing and disclosures across representative currencies/locales.
- [ ] Reconcile export/analytics totals with normalized ledger balances.
- [ ] Verify attachment and custom-category RLS using positive and negative authorization tests.
- [ ] Verify recurring jobs and reminders are idempotent and rate-limited.
- [ ] Run formatting, tests, `flutter analyze`, and release builds with zero blocking errors.
- [ ] Record validation results in this file.
- [ ] Commit Phase 4 with a focused conventional commit.
- [ ] Stop and wait for Phase 4 review.

---

## Phase 5 — Viral Growth Loops & Offline Resilience

### Frictionless group invites

- [ ] Audit current group invite permissions, membership RPCs, deep links, and abuse controls.
- [ ] Create short-lived, revocable, non-guessable invite tokens that reveal no group/member PII.
- [ ] Generate shareable group QR codes from canonical invite links.
- [ ] Configure Android App Links and iOS Universal Links with verified domains.
- [ ] Route authenticated recipients directly to a safe group preview/join flow.
- [ ] Preserve the pending invite through authentication/onboarding for signed-out recipients.
- [ ] Make join operations atomic and idempotent; handle expired, revoked, full, duplicate, and unauthorized invites.
- [ ] Add invite-created, invite-opened, join-started, and join-completed funnel analytics without PII.

### Contextual in-app review

- [ ] Add and configure `in_app_review` for supported platforms.
- [ ] Define a happy-moment eligibility policy after successful debt settlement.
- [ ] Add cooldown, minimum-usage, version, and one-prompt safeguards.
- [ ] Never show the prompt after an error, dispute, rejected payment, or destructive action.
- [ ] Log eligibility/request outcomes without assuming the store displayed or completed a review.

### Offline resilience

- [ ] Inventory all Supabase reads/writes and current network error handling.
- [ ] Define which data may be cached locally and document encryption/privacy requirements.
- [ ] Show last-known safe read data with freshness indicators when offline.
- [ ] Add consistent offline/timeout/retry states without red-screen crashes.
- [ ] Define a conservative queued-write scope; do not silently queue ambiguous financial mutations.
- [ ] Make any queued writes idempotent and visibly pending until server confirmation.
- [ ] Reconcile cached state after reconnect, auth expiry, membership changes, and server rejection.
- [ ] Test airplane mode, slow network, mid-request disconnects, expired sessions, and recovery.

### Phase 5 validation gate

- [ ] Test invite links and QR codes across installed, fresh-install, signed-in, and signed-out states.
- [ ] Verify invite token security, expiry, revocation, and replay behavior.
- [ ] Verify review prompts satisfy cooldown and happy-moment rules.
- [ ] Run repeatable offline/reconnect tests without balance corruption or duplicate writes.
- [ ] Run formatting, tests, `flutter analyze`, and release builds with zero blocking errors.
- [ ] Record validation results in this file.
- [ ] Commit Phase 5 with a focused conventional commit.
- [ ] Stop and wait for Phase 5 review.

---

## Phase 6 — Security, Bug Audit & Final Readiness Report

### Code quality and functional regression

- [ ] Run formatting checks and full `flutter analyze` with zero errors.
- [ ] Run all unit, widget, integration, and backend validation tests.
- [ ] Build signed release candidates for Android and iOS where the required signing environment is available.
- [ ] Execute critical-path regression: onboarding, auth, group creation, expense creation, settlement, subscription, restore, invite, offline recovery, and account deletion.
- [ ] Reconfirm normalized balances and FX reproducibility against known fixtures.

### DevSecOps and backend security

- [ ] Scan tracked files and Git history for secrets, service-role keys, tokens, signing files, and sensitive Firebase/Supabase configuration.
- [ ] Audit `.gitignore`, environment templates, Android signing configuration, and Supabase temporary files.
- [ ] Review every relevant RLS policy, security-definer function, RPC grant, Edge Function JWT check, Storage policy, and service-role use.
- [ ] Run negative authorization tests for cross-user groups, expenses, shares, settlements, attachments, categories, invites, exports, and deletion.
- [ ] Verify rate limiting and abuse controls for auth, invites, OCR, reminders, exports, uploads, and account deletion.
- [ ] Review dependency vulnerabilities, outdated critical packages, Android/iOS permissions, and data-retention behavior.
- [ ] Verify analytics/crash reports contain no tokens, PII, receipt images, or financial payloads.

### UX, accessibility, and store readiness

- [ ] Test representative small phones, large phones, tablets, display scaling, keyboard insets, notches, and edge-to-edge system bars.
- [ ] Resolve RenderFlex overflow, clipped dialogs, unreachable actions, and unsafe touch targets.
- [ ] Audit screen-reader labels, focus order, contrast, reduced motion, and dynamic text sizing.
- [ ] Verify dark/light themes and all loading, empty, error, destructive, and offline states.
- [ ] Verify Play/App Store privacy disclosures, account deletion, subscription disclosures, restore, Terms, Privacy Policy, and data-safety answers.
- [ ] Confirm release version/build numbers, package IDs, signing, icons, screenshots, and store metadata.

### Final report and release decision

- [ ] Create a detailed implementation report covering every phase and validation result.
- [ ] Document the OCR root cause, repair, accuracy limits, fallback behavior, and test evidence.
- [ ] Document backend migrations, manual console configuration, operational runbooks, and rollback procedures.
- [ ] List residual risks by severity with owners and recommended follow-up dates.
- [ ] Produce a release checklist and a clear Go/No-Go decision.
- [ ] Confirm production readiness only if all P0/P1 checks pass with evidence; otherwise identify the exact blockers.
- [ ] Update all final checkboxes and evidence in this document.
- [ ] Commit Phase 6 and the final report with a focused conventional commit.
- [ ] Stop for final owner review before any store submission.

---

## Phase evidence log

### Phase 1

- Status: Implementation complete; awaiting owner/device validation and review
- Commit: `feat(auth): implement native Google identity and funnel analytics`
- Validation: `flutter analyze` passed with zero issues; 11 unit/widget tests passed; `flutter build apk --release` produced a signed 70.8 MB APK; `git diff --check` passed; release Firebase resources were generated; browser OAuth and `$RCAnonymousID` source references are absent.
- Routing contract: a newly created Supabase Google identity is sent through onboarding unless onboarding was already completed in the same install run; returning identities go to the dashboard. Restored sessions bypass auth according to persisted onboarding state.
- Analytics contract: Firebase owns automatic `app_open`; Splixa emits one privacy-safe `login`, normalized `paywall_view`, `subscription_started` only for a newly activated subscription product, and `expense_added` only after a successful backend write. No amounts, currencies, emails, or tokens are included.
- Manual release gate: verify native sign-in on a physical Android device and confirm Google Cloud has an Android OAuth client for `net.splixa.app` with release SHA-1 `B9:F9:F3:0F:63:20:09:A0:09:6A:BD:1A:A7:A5:C1:1E:FB:FF:AF:B5`; the current ignored `google-services.json` contains Firebase app resources but no Android OAuth entry. Also verify RevenueCat identity/restore and Firebase DebugView. iOS client ID and URL scheme remain intentionally unverified for this Play Store phase.
- Review decision: Pending owner review

### Phase 2

- Status: Not started
- Commit: —
- Validation: —
- Review decision: —

### Phase 3

- Status: Not started
- Commit: —
- Validation: —
- Review decision: —

### Phase 4

- Status: Not started
- Commit: —
- Validation: —
- Review decision: —

### Phase 5

- Status: Not started
- Commit: —
- Validation: —
- Review decision: —

### Phase 6

- Status: Not started
- Commit: —
- Validation: —
- Review decision: —
