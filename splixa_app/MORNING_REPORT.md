# Splixa Phase 2 — Morning Report

Date: 10 September 2026
Scope: Growth, conversion, telemetry, onboarding, paywall, premium entry points, and navigation polish

## Executive outcome

The Phase 2 client implementation is complete and passes static analysis, automated state tests, and a Flutter web release build.

The conversion strategy deliberately avoids a mandatory cold-start paywall. New users first see a four-step value narrative, enter the free product, and encounter Pro at moments of demonstrated intent: creating more groups, opening advanced statistics or reports, and selecting automation controls. This protects activation while still making the paid value visible.

The paywall only claims benefits that exist today. Receipt scanning and custom exchange rates are clearly labeled as upcoming previews; their entry points are conversion/interest probes, not fake working features.

## What was implemented

### Four-screen onboarding

- A new four-screen, bilingual onboarding experience covers:
  1. Personal and shared money in one place.
  2. Clear group splits and approvals.
  3. Reproducible historical FX values.
  4. A free-core/optional-Pro promise with no card required.
- Page transitions, progress indicators, Skip and primary CTAs are implemented.
- Completion is persisted under `splixa_onboarding_completed_v1` using `SharedPreferences`.
- Router redirects prevent completed users from seeing onboarding again and send first-time anonymous users through onboarding before authentication.
- The preference is intentionally only a UX flag, not an authentication or security boundary.

### Firebase Analytics architecture

- `firebase_core` and `firebase_analytics` were added.
- `AnalyticsService` is the single, fault-tolerant event gateway.
- Firebase initialization supports native configuration files or the documented `.env` client configuration.
- Missing Firebase configuration never blocks app startup; analytics becomes a safe no-op and prints a development diagnostic.
- A Firebase navigation observer is attached when initialization succeeds.

### RevenueCat/paywall overhaul

- The paywall was rebuilt around concrete benefits, localized store pricing, monthly/yearly package selection, a visible free exit, Restore Purchases, Terms, Privacy, and renewal/cancellation disclosure.
- Yearly is presented first, but “Best value” appears only when its real store price is lower than twelve monthly payments.
- Purchases update a global `CustomerInfo` provider via RevenueCat's customer-info listener.
- `purchase_success` is emitted only after the configured RevenueCat entitlement is actually active; review-mode access cannot create a false conversion.
- Restore Purchases refreshes both global `CustomerInfo` and premium state.
- The profile exposes the correct store subscription-management destination.

### Premium entry points

- Unlimited-group limit → paywall source `unlimited_groups`.
- Advanced statistics → `advanced_analytics`.
- Monthly PDF report → `advanced_reports`.
- Profile upgrade → `profile`.
- Receipt scan preview → `receipt_scan`.
- Custom exchange-rate preview → `custom_exchange_rate`.
- Existing Pro users receive an explicit “coming soon” message for the two preview features rather than being sent to a paywall.

### Navigation polish

The bottom navigation bar now appears only on the four root destinations (`/dashboard`, `/social`, `/debts`, and `/profile`). Nested task and detail routes use the full viewport without the primary navigation competing for attention.

## UX and conversion principles applied

- **Progressive commitment:** Each onboarding screen asks for a very small commitment and moves from broad relevance to concrete trust before presenting Pro.
- **Dual-job framing:** Splixa is positioned as both a personal money tracker and a shared-expense tool, avoiding the category trap of appearing useful only during trips.
- **Outcome-first copy:** The language sells clarity, saved time, and reproducible balances instead of database or accounting mechanics.
- **Trust before monetization:** Locked FX history and transparent approvals appear before the Pro proposition.
- **Intent-based paywalls:** Paywalls are triggered at feature demand, not immediately after installation.
- **Truthful scarcity and anchoring:** Annual pricing is visually prioritized, but savings language is conditional on actual localized prices. There is no fabricated countdown, trial, or discount.
- **Reversible choice:** Continue Free and Restore Purchases are visible, reducing coercion and aligning with store expectations.
- **Message match:** Every paywall route carries a typed source so the entry intent can be measured and later reflected in experiments.

RevenueCat's 2025 benchmark identifies onboarding/trial activation as a major source of performance separation, while also noting that both hard-paywall and freemium models can work. Splixa uses the freemium path because its social/group loop benefits from broad participation. [RevenueCat State of Subscription Apps 2025](https://www.revenuecat.com/state-of-subscription-apps-2025/)

The pricing and renewal treatment follows Apple's subscription guidance and Google's requirement that price, billing cadence, auto-renewal, and cancellation information be clear. [Apple subscription best practices](https://developer.apple.com/app-store/subscriptions/) · [Google Play subscription policy](https://support.google.com/googleplay/android-developer/answer/9900533?hl=en)

## Instrumented analytics events

| Event | Parameters | Trigger |
|---|---|---|
| `onboarding_start` | — | First onboarding frame |
| `onboarding_step_viewed` | `step`, `step_name` | First view of each step in a session |
| `onboarding_complete` | `completion_method` (`skip` or `cta`) | Persisted onboarding completion |
| `paywall_view` | `source` | Paywall first frame |
| `purchase_attempt` | `source`, `package_id`, `product_id` | Before RevenueCat purchase call |
| `purchase_success` | `source`, `package_id`, `product_id`, `currency`, `value` | Active entitlement returned by RevenueCat |

Source values are strictly typed in Dart: `onboarding`, `unlimited_groups`, `receipt_scan`, `custom_exchange_rate`, `advanced_analytics`, `advanced_reports`, `profile`, and `unknown`.

Firebase event names are case-sensitive and custom parameters must be registered as custom dimensions before they are available in standard reports. [Firebase Analytics event documentation](https://firebase.google.com/docs/analytics/flutter/events)

## Verification performed

- `flutter analyze --no-pub`: **No issues found** (42.4s).
- Focused Flutter tests: **5/5 passed** after the account-deletion follow-up.
  - First launch defaults to incomplete onboarding.
  - Completion persists across controller reloads.
  - Account deletion resets persisted onboarding completion.
  - Every paywall source round-trips correctly.
  - Unknown route values safely map to `unknown`.
- `flutter build web --release --no-pub`: **successful**, output created at `build/web` (117.0s).
- The web compiler reported a non-blocking WebAssembly compatibility warning from `flutter_secure_storage_web` and `purchases_flutter`; the standard JavaScript web release build succeeded.

## Manual morning setup

### Firebase Console

1. Create or select the production Firebase project and enable Google Analytics.
2. Register Android package `net.splixa.app` and iOS bundle ID `net.splixa.app`. If debug builds use `net.splixa.app.debug`, register that Android app separately.
3. Run `flutterfire configure` from the app directory to create native Firebase configuration, or fill the public Firebase client fields documented in `.env.example`. Do not commit a populated `.env`.
4. Verify all six events in Firebase DebugView on a physical Android/iOS device.
5. Register custom dimensions for `source`, `step_name`, `completion_method`, `package_id`, and `product_id` if they are needed in Firebase reports.
6. Decide whether analytics collection needs an explicit consent gate for the launch regions, and update the privacy disclosure/data-safety forms accordingly.

Official FlutterFire setup steps: [Add Firebase to a Flutter app](https://firebase.google.com/docs/flutter/setup)

### RevenueCat and stores

1. Confirm the RevenueCat entitlement identifier is `pro`, or change `REVENUECAT_PREMIUM_ENTITLEMENT_ID`.
2. Confirm the current Offering contains real monthly and annual packages with approved App Store/Play products and localized prices.
3. Populate the platform public SDK keys in the non-committed `.env`.
4. Test purchase, cancellation, renewal, billing issue, and Restore Purchases using Apple/Google sandbox accounts. RevenueCat recommends providing a restore mechanism and notes that the SDK synchronizes `CustomerInfo`. [RevenueCat restore guidance](https://www.revenuecat.com/docs/getting-started/restoring-purchases) · [RevenueCat CustomerInfo](https://www.revenuecat.com/docs/customers/customer-info)
5. Enable the In-App Purchase capability in Xcode. Android's billing permission is now explicit in the manifest.
6. For canonical revenue attribution, configure RevenueCat's Firebase integration or a server-side webhook; the new client event is useful funnel telemetry but should not be the financial source of truth.

### iOS build environment

- The iOS deployment target is now 15.0, matching the current FlutterFire platform requirement.
- This workspace currently has no `ios/Podfile`, while Flutter's generated plugin metadata says Swift Package Manager is disabled. Before the next iOS archive, restore/generate the CocoaPods setup or explicitly enable Flutter Swift Package Manager, then resolve native dependencies on macOS.

### Legal and release operations

- Verify that `https://splixa.net/terms` and `https://splixa.net/privacy` are publicly reachable, final, and accurately disclose Firebase Analytics and RevenueCat processing. They were not verifiable from public search during this pass.
- Google directs users to the Play subscription center for cancellation/management; that destination is wired for Android. [Google Play subscription management](https://developer.android.com/google/play/billing/subscriptions)
- The parent repository ignores `*.lock`, which also ignores Flutter's `pubspec.lock`. For a production application, narrow that rule and commit `pubspec.lock` so dependency resolution is reproducible.

## Known blockers and follow-up work

### P0 release blocker: account deletion — resolved 10 September 2026

The former sign-out-only action has been replaced by the authenticated
`delete-account` Edge Function, a service-role-only transactional database
preparation RPC, strict typed confirmation, and local credential/cache cleanup.
Shared ledger actors are anonymized without changing remaining members'
balances. Production still requires the new migration and function deployment.

### Product follow-ups

- Receipt OCR and editable custom exchange rates are intentionally UI/telemetry stubs. Do not market them as shipped until their workflows, error handling, entitlements, and tests exist.
- Use the new `source` dimension to compare paywall-view → purchase-attempt → purchase-success conversion. Do not optimize on paywall views alone.
- Add `purchase_cancelled` and `purchase_failed` reason classes in the next telemetry iteration, without logging raw exception text or personal data.
- After sufficient volume, experiment with onboarding copy/order and contextual paywall messaging one variable at a time.

## Primary files changed for Phase 2

- `lib/core/analytics_service.dart`
- `lib/features/onboarding/onboarding_screen.dart`
- `lib/features/subscriptions/paywall_screen.dart`
- `lib/features/subscriptions/premium_provider.dart`
- `lib/main.dart`
- `lib/main_scaffold.dart`
- `lib/features/groups/add_expense_sheet.dart`
- `lib/features/profile/currency_selector.dart`
- `lib/features/profile/splixa_profile_screen.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `lib/features/dashboard/splixa_home_screen.dart`
- `lib/features/groups/groups_screen.dart`
- `test/onboarding_and_paywall_state_test.dart`
- `.env.example`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner.xcodeproj/project.pbxproj`
