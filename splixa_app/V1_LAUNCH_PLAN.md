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
- [x] Confirm the Android OAuth clients and Web client ID are read from ignored Firebase platform configuration.
- [ ] Confirm the iOS URL scheme/configuration before the later iOS release track.
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
- [x] Manually smoke-test successful native Google login with multiple Google accounts on a physical Android device.
- [ ] Manually smoke-test cancellation, sign-out, and relogin before the final release audit.
- [ ] Verify RevenueCat user ID and active entitlement state after login and restore.
- [ ] Verify Firebase DebugView receives the required events without PII.
- [x] Record validation results in this file.
- [x] Commit Phase 1 with a focused conventional commit.
- [x] Stop and wait for Phase 1 review.

---

## Phase 2 — Global Localization & Auto-Locale

### Localization architecture

- [x] Inventory all user-visible strings, including dialogs, snackbars, validation errors, paywalls, notifications, and accessibility labels.
- [x] Choose and document `easy_localization` or Flutter `intl` based on current architecture and testability.
- [x] Define locale file structure, naming conventions, interpolation, pluralization, and fallback behavior.
- [x] Establish English as the complete source locale and fallback locale.
- [x] Add automated validation for missing, unused, and structurally mismatched translation keys.

### Locale behavior and controls

- [x] Detect the system locale on first launch.
- [x] Match regional variants to supported base languages where appropriate.
- [x] Fall back to English when the device language is unsupported.
- [x] Persist an explicit user locale selection across launches and sign-in state changes.
- [x] Add an accessible language selector to onboarding without increasing friction.
- [x] Add the same language selector to Settings/Profile.
- [x] Ensure locale changes update the app immediately without requiring restart.

### Translation coverage

- [x] Finalize the exact launch locale list and locale codes before translation begins.
- [x] Prepare complete dictionary key parity for all target locales, including at minimum EN, TR, ES, PT, DE, and FR.
- [x] Translate core navigation, onboarding, authentication, expense, group, debt, profile, and paywall journeys.
- [x] Localize dates, times, numbers, currencies, and relative-time labels.
- [x] Remove remaining hardcoded user-facing strings from Dart and supported native surfaces.
- [x] Review text expansion and right-to-left readiness; enable RTL behavior for any shipped RTL locale.
- [ ] Arrange native-speaker or professional review for monetization, legal, and destructive-action copy before launch.

### Phase 2 validation gate

- [x] Run the translation key validator with zero missing source keys.
- [x] Run an automated hardcoded-string audit and document justified exceptions.
- [x] Test system auto-detection, unsupported fallback, persistence, and live switching.
- [x] Test representative long-text and RTL locales on small screens.
- [x] Run formatting, tests, and `flutter analyze` with zero errors.
- [x] Build a release Android artifact successfully.
- [x] Record validation results in this file.
- [x] Commit Phase 2 with a focused conventional commit.
- [x] Stop and wait for Phase 2 review.

---

## Phase 3 — Premium UX & UI Polish

### Animated onboarding

- [x] Audit current onboarding completion, skip, back, and auth-routing behavior.
- [x] Rewrite each slide to one concise value proposition with a clear progression.
- [x] Create original, size-efficient Lottie assets aligned with the Splixa visual system.
- [x] Add Lottie loading/error fallbacks so onboarding never blocks on animation rendering.
- [x] Implement smooth, accessible transitions that respect reduced-motion preferences.
- [x] Preserve locale selector access and analytics instrumentation on every step.
- [x] Optimize assets and verify startup size/performance impact.

### Skeleton and shimmer system

- [x] Inventory every `CircularProgressIndicator` and classify full-page, inline-action, refresh, and blocking states.
- [x] Create reusable theme-aware skeleton primitives matching the final content geometry.
- [x] Replace Supabase data-fetch spinners with stable skeleton layouts without introducing layout jumps.
- [x] Keep compact progress indicators where skeletons are inappropriate, such as button submissions or indeterminate actions.
- [x] Respect reduced-motion settings and avoid excessive GPU/battery usage.
- [x] Add polished empty and retryable error states alongside loading states while preserving safely available data.

### Product analytics and experimentation

- [x] Define a privacy-safe measurement plan from acquisition through activation, retention, collaboration, and purchase.
- [x] Give every GoRouter route a stable analytics name that excludes user and group identifiers.
- [x] Instrument onboarding entry, per-step views, interruption, completion method, dwell time, and experiment assignment.
- [x] Instrument login attempts/outcomes, profile completion, group creation, expense creation, and ledger lifecycle actions.
- [x] Instrument paywall views, sources, package selection, dismissal, checkout outcomes, and confirmed subscription activation.
- [x] Set pseudonymous user identity and non-PII properties for language, subscription tier, and experiment variants.
- [x] Add Firebase Remote Config assignments for onboarding and paywall experiments with safe control fallbacks.
- [x] Document GA4 funnels, key events, custom dimensions, BigQuery export, Google Ads linking, and consent prerequisites.
- [x] Add automated tests that reject financial payloads and PII in critical analytics events.

### Phase 3 validation gate

- [x] Test onboarding on small/large Android surfaces, dark/light modes, and representative long/RTL locales.
- [x] Verify no semantic regressions, overflow, or unbounded shimmer loops; reduced motion renders static states.
- [x] Run formatting, tests, and `flutter analyze` with zero errors.
- [ ] Build and smoke-test a release artifact (manual owner validation by explicit preference).
- [x] Record validation results in this file.
- [x] Commit Phase 3 with a focused conventional commit.
- [x] Stop and wait for Phase 3 review.

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

- Status: Implementation complete; physical Android Google login validated; awaiting Phase 2 approval
- Commit: `feat(auth): implement native Google identity and funnel analytics`
- Validation: `flutter analyze` passed with zero issues; 11 unit/widget tests passed; `flutter build apk --release` produced a signed 70.8 MB APK; `git diff --check` passed; release Firebase resources were generated; browser OAuth and `$RCAnonymousID` source references are absent.
- Routing contract: a newly created Supabase Google identity is sent through onboarding unless onboarding was already completed in the same install run; returning identities go to the dashboard. Restored sessions bypass auth according to persisted onboarding state.
- Analytics contract: Firebase owns automatic `app_open`; Splixa emits one privacy-safe `login`, normalized `paywall_view`, `subscription_started` only for a newly activated subscription product, and `expense_added` only after a successful backend write. No amounts, currencies, emails, or tokens are included.
- Post-review fix: native Google authorization no longer launches a second empty-scope consent request; Google and Supabase stages have bounded timeouts; RevenueCat/Analytics post-login work cannot block navigation; Google identities without a valid username are forced through `/complete-profile` before dashboard access.
- Follow-up validation: `flutter analyze` passed with zero issues; 14 unit/widget tests passed, including three Google profile-gate cases; the corrected release APK built successfully at 70.8 MB.
- Runtime QA finding: Firebase CLI confirmed the live `splixa` Android app has all three SHA-1 fingerprints registered and one Web OAuth client, but zero Android OAuth clients. `google_sign_in_android` can report this server-side configuration failure as `canceled` after account selection, so the client now surfaces that result instead of silently ignoring it. The ignored local `google-services.json` was refreshed from the live Firebase app and the release APK rebuilt.
- Device validation: Google Cloud now has Android OAuth clients for the local and Play signing identities, the OAuth audience/branding was prepared for production, and the owner confirmed successful native sign-in with multiple Gmail accounts. The remaining login blocker was in the Supabase signup function and was corrected by the owner.
- Startup hardening: Android release packaging omitted the dot-prefixed `.env` asset and produced `FileNotFoundError` before `runApp()`. Runtime configuration now uses the ignored, non-dot-prefixed `env.config` asset so APK/AAB packaging retains it.
- Deferred final-release checks: verify RevenueCat identity/restore, Firebase DebugView, Google cancellation/sign-out/relogin, and iOS URL scheme configuration in their applicable release tracks.
- Review decision: Phase 1 implementation accepted on Android; explicit approval is still required before Phase 2 begins.

### Phase 2

- Status: Complete and device-validated. Every gate item passes except the native-speaker copy review, which is a pre-launch task rather than a code task and is tracked as a residual risk below.
- Commit: `e74f8cc feat(i18n): ship 12-locale global localization with RTL and locale-aware formatting`
- Scope decision: the owner chose **12 fully translated launch locales** — EN, TR, ES, PT, DE, FR, IT, NL, RU, AR, HI, ID — instead of translating all 30+ catalogued locales at once. This covers the largest Play Store markets and ships one RTL locale (AR) so right-to-left layout is genuinely exercised. The remaining 23 locales stay catalogued in `AppLanguage` and resolve through the English fallback; each becomes shippable by adding one dictionary file and flipping `translationReady`.
- Architecture: Flutter's own `flutter_localizations` + `intl` (already in `pubspec.yaml`) with a typed Dart catalog — no new dependency, no build-time codegen, and the dictionaries are unit-testable without a widget tree. `lib/core/l10n/strings_<code>.dart` holds one `const Map<String, String>` per locale; `AppStrings` (lib/core/app_strings.dart) composes them and resolves per key, so a missing translation renders English rather than a blank or a raw key.
- Key conventions: `<feature>_<element>` snake_case, English is the source of truth for which keys exist (437 keys), interpolation uses `{name}` placeholders resolved by `AppStrings.format` / `trp(ref, key, values)`. Legacy `%s` placeholders were preserved where the call site already used `replaceFirst`.
- Pluralization: launch copy uses count-agnostic phrasing (`{count} members`) rather than ICU plural forms. This keeps every locale structurally identical and testable; languages with richer plural rules (RU, AR, PL) read slightly flat in the few affected strings. Listed as a residual risk below.
- Locale behavior: first launch walks the device's preferred-locale list, collapsing regional variants (`pt-BR` → `pt`, `zh_Hans` → `zh`, legacy `no` → `nb`), selects the first locale with a complete dictionary and otherwise English. An explicit selection is persisted in `SharedPreferences` and always wins over the device. The picker (`AppLanguageSelector`) appears in onboarding, the dashboard header and Profile; changes apply immediately through Riverpod without a restart.
- RTL: `AppLanguage.textDirection` drives a `Directionality` wrapper in `MaterialApp.router`'s builder alongside `GlobalWidgetsLocalizations`, so Arabic is correct even on the first frame after a live switch. Directional layout was swept across the app: `EdgeInsets.only(left/right)` → `EdgeInsetsDirectional`, `Alignment.center{Left,Right}` → `AlignmentDirectional` (chat bubbles, balances, split rows), and avatar edit badges → `PositionedDirectional`.
- Formatting: new `lib/core/app_formatting.dart` (`AppFormat`) routes every user-visible number, date and relative-time label through `intl` for the active locale. Currency symbols are never inferred from the locale — the user's selected symbol is passed in, so only grouping/decimal marks follow the language. The monthly PDF export now takes a `DateTime` and the user's currency symbol instead of a pre-formatted Turkish month string and a hardcoded `₺`.
- Hardcoded-copy removal: onboarding and the paywall carried their own hand-written English/Turkish copy classes (`_OnboardingCopy`, `_PaywallCopy` with an `isTurkish` flag); both now read from the shared catalog, which is what brings those journeys into all 12 locales. Two currency leaks were removed from notification and activity-feed templates (`Amount: {amount} TL`, `{amount}₺`) — the amount is now locale-formatted and currency-neutral.
- Validation performed in this session: a round-trip parser re-read all 12 generated dictionaries and confirmed 437/437 keys present, no empty values, no orphaned keys and identical placeholder sets against English; a Dart-aware bracket/lexer check passed on all 75 `lib/` and `test/` sources; the hardcoded-string scan found 8 remaining inline literals, all brand marks, ISO currency codes or the `DELETE` confirmation token, each now recorded as a justified exception.
- Tests added/updated: `test/localization_catalog_test.dart` (key parity, orphan keys, placeholder parity, fallback resolution, RTL metadata), `test/locale_provider_test.dart` (detection, regional variants, RTL detection, list-walking, persistence precedence, retired-locale fallback, live switching), `test/app_formatting_test.dart` (locale separators, caller-supplied currency symbol, date order, translated month names, relative-time buckets), `test/hardcoded_strings_test.dart` (automated inline-copy audit with a documented exception list).
- Toolchain gate (owner-run, first attempt): `flutter analyze` reported 4 errors and `flutter test` could not compile. Root causes and fixes:
  1. `package:intl/intl.dart` exports its own `TextDirection` class, which shadowed Flutter's `dart:ui` enum inside `locale_provider.dart`. This produced both `undefined_getter` errors on `TextDirection.rtl`/`.ltr` and the `argument_type_not_assignable` error where `main.dart` passed the result to `Directionality`. Fixed with `import 'package:intl/intl.dart' hide TextDirection;` — one import change closed all three errors.
  2. `PdfExportService.generateAndShareMonthlyReport` gained a `DateTime` parameter and a caller-supplied currency symbol, but only one of its two call sites was updated; the legacy `profile_screen.dart` still passed a preformatted `'M/yyyy'` string.
  3. Found by inspection rather than by the analyzer: `DateFormat` throws `LocaleDataException` for any locale whose symbols are not loaded, and `GlobalMaterialLocalizations` loads only the locale currently on screen. Formatting for a different language — the PDF export, a background notification, any unit test — would have failed at runtime with a clean analyze. Added `AppFormat.ensureInitialized()` (wraps `initializeDateFormatting()`), called once in `main()` and from the formatting test's `setUpAll`. This bundles `intl` date symbols for all locales, a small APK size cost accepted for 12 launch languages.
- Toolchain gate (owner-run, after fixes): `dart format lib test` reported 0 changed files; `flutter analyze` reported **No issues found**; `flutter test` passed **43/43** tests; `flutter build apk --release` produced `app-release.apk` at **71.7 MB**, up 0.9 MB from Phase 1's 70.8 MB — the 12 dictionaries plus `intl`'s all-locale date symbols. Reducible later with `date_symbol_data_custom` if APK size becomes a constraint.
- Device validation: the owner installed the release build and confirmed Arabic RTL layout, the long-text locales, the language picker and the restored onboarding flow all behave correctly.
- Post-device fixes (round 2): four defects the automated gate could not see were found on device and corrected.
  1. `splixa_profile_screen.dart` requested `profile_edit`, `profile_change_password` and `profile_currency`, but the catalog defines those keys with a `_tile` suffix. `AppStrings.of` degrades to returning the key, so raw identifiers were rendered to the user instead of crashing. Call sites corrected, and `test/localization_key_usage_test.dart` now scans every `tr` / `trp` / `AppStrings.of` / `AppStrings.format` call site and fails the build when a requested key is not defined — the mirror of the catalog test, which only proved that *defined* keys resolve. A full-tree run found no other occurrences (443 keys, 399 call sites, 0 missing).
  2. The language control was a `DropdownButton`, whose menu inherits the button's width; inside a 62 px header pill every entry truncated to "Eng…", "Esp…". Replaced with `showLanguagePicker` — a full-height sheet listing each language by native and English name with the active one checked. Removed from the dashboard and home header and surfaced in Profile → Preferences, where a user who picked the wrong language can actually find it.
  3. The profile screen was one undifferentiated menu card. Split into labelled sections (Subscription, Account, Preferences, Support, Legal, Danger zone) and the settings bottom sheet was inlined into Preferences, so theme, language and currency are reachable without a second modal.
  4. A fresh install skipped onboarding and opened the login screen. The router logic was correct; the cause was Android auto-backup, which defaults to on and had no rules file, so Google Drive restored `FlutterSharedPreferences.xml` — including the onboarding-completed flag — onto a reinstall. Added `backup_rules.xml` and `data_extraction_rules.xml` excluding shared preferences and secure storage (the latter also restores unusable ciphertext, since its Keystore key does not survive reinstall) and wired both into the manifest. Separately, the login screen's back arrow navigated to `/onboarding` and was bounced straight back by the redirect; deliberate replays now pass through via `?replay=1`, and the onboarding language control is limited to the first slide.
- Paywall currency audit (owner question): every amount on the paywall comes from RevenueCat's `StoreProduct.priceString` / `pricePerMonthString`, and the app's own expense-currency selector never reaches subscription UI. The only raw numeric price use is an internal comparison for the Best Value badge and is never rendered. Google Play returns prices in the currency of the buyer's Play billing country, so a Turkish account correctly sees TRY regardless of app language; verifying the other 176 countries needs a licence-tester account in the target country, not a language change.
- Residual risks: (1) the 10 newly added locales are machine-assisted translations and still need native-speaker review before launch, especially paywall, legal and destructive-action copy — the one open Phase 2 item; (2) no ICU plural forms, so count-bearing strings read flat in RU/AR/PL; (3) Play Store listing translations have not been added for the new locales, so the store page stays in its existing languages while the app itself is localized.
- Release: shipped as `0.6.0-alpha` (versionCode 6).
- Review decision: Accepted by the owner; Phase 3 explicitly approved.

### Phase 3

- Status: Implementation complete; automated quality gates passed. Awaiting the owner's manual release build/device smoke test and Phase 3 review.
- Commit: `feat(ux): complete onboarding polish and product experiments`
- UX delivery: four concise localized onboarding steps use four original bundled Lottie compositions with static error/reduced-motion fallbacks. A Remote Config `focused` variant removes the FX step for a stable three-step experiment without allowing assignments to change mid-flow.
- Loading delivery: `SplixaSkeletonView` provides compact, list, cards, dashboard, profile, chat, and paywall geometries. All Supabase data-fetch spinners were replaced; the 16 remaining `CircularProgressIndicator` instances are deliberate inline/blocking actions such as sign-in, purchase, upload, mutation, and account deletion.
- Accessibility/device evidence: widget tests traverse all four German steps on a 320x568 surface and verify Arabic RTL, dark mode, and reduced motion on 430x932. The responsive header collapses its wordmark/skip label on constrained layouts, and primary buttons safely accommodate long or scaled labels.
- Analytics delivery: Firebase Analytics covers stable `screen_view`, onboarding progression/interruption/completion, login outcomes, profile setup, group/expense activation, ledger lifecycle, paywall source/package/dismissal, purchase outcomes, and confirmed subscriptions. Supabase IDs are pseudonymous; no email, username, group name, description, receipt content, balance, debt, or expense amount is sent.
- Experiment delivery: Firebase Remote Config keys are `onboarding_flow_variant` (`control` / `focused`) and `paywall_layout_variant` (`control` / `plans_first`). Missing, offline, or unknown values fail closed to `control`; active values are also attached as Analytics user properties.
- Operations: `PRODUCT_ANALYTICS_PLAYBOOK.md` documents the event dictionary, GA4 funnel explorations, key events/custom dimensions, BigQuery export, Google Ads attribution, DebugView, and consent prerequisites. Console configuration remains an owner-side action before paid acquisition.
- Automated validation: `flutter test` passed 56/56 tests; `flutter analyze` reported `No issues found`; all four Lottie JSON files parse as animated compositions; `git diff --check` passed.
- Release: source version advanced to `0.7.0-alpha+7`. Per owner preference, APK/AAB generation is intentionally not run by the agent; the owner will build and smoke-test the release artifact.
- Review decision: Awaiting owner review. Phase 4 must not begin without explicit approval.

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
