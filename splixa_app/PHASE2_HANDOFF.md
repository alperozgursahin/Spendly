# Splixa — Phase 2 handoff (Global Localization & Auto-Locale)

## What shipped

**Scope decision:** 12 fully translated launch locales — EN, TR, ES, PT, DE, FR, IT, NL, RU, AR, HI, ID. The other 23 locales stay catalogued in `AppLanguage` and resolve through the English fallback; each becomes shippable by adding one dictionary file and setting `translationReady: true`.

**Architecture:** Flutter `flutter_localizations` + `intl` (already in pubspec) with a typed Dart catalog. No new dependency, no codegen.

```
lib/core/l10n/strings_<code>.dart   one const Map<String,String> per locale (437 keys each)
lib/core/app_strings.dart           composes them; tr(ref,key), trp(ref,key,values), AppStrings.of/format
lib/core/app_formatting.dart        AppFormat — locale-aware numbers, dates, relative time
lib/core/locale_provider.dart       AppLanguage enum, detection, persistence, textDirection
```

English is the source of truth for which keys exist. A missing translation renders English, never a blank or a raw key.

## Files changed (42)

- **New:** 12 locale dictionaries, `lib/core/app_formatting.dart`, `test/app_formatting_test.dart`, `test/hardcoded_strings_test.dart`
- **Rewritten:** `app_strings.dart`, `locale_provider.dart`, `test/localization_catalog_test.dart`, `test/locale_provider_test.dart`
- **Rewired to the catalog:** `onboarding_screen.dart` and `paywall_screen.dart` — both carried their own hand-written EN/TR copy classes (`_OnboardingCopy`, `_PaywallCopy` with an `isTurkish` flag). That is what brings those journeys into all 12 locales.
- **RTL sweep:** `EdgeInsets.only(left/right)` → `EdgeInsetsDirectional`, `Alignment.center{Left,Right}` → `AlignmentDirectional`, avatar badges → `PositionedDirectional` across dashboard, debts, groups, social, auth and profile.
- **Currency/date fixes:** notification and activity templates no longer hardcode `TL` / `₺`; the monthly PDF takes a `DateTime` and the user's currency symbol instead of a Turkish month string and a hardcoded `₺`.

## Verified in this session

- Round-trip parser re-read all 12 dictionaries: **437/437 keys** each, no empty values, no orphaned keys, placeholder sets identical to English.
- Dart-aware lexer/bracket check passed on all **75** `lib/` and `test/` sources.
- Hardcoded-string scan: **8** inline literals remain — brand marks (`Splixa`, `S`, Google's `G`), ISO currency codes (`₺ (TRY)`, `€ (EUR)`, `$ (USD)`) and the `DELETE` confirmation token. All recorded as justified exceptions in `test/hardcoded_strings_test.dart`.

## NOT verified — you need to run these

The Windows folder mount was down this session (8 September Windows update), so no Flutter toolchain was reachable.

```powershell
cd "C:\Flutter Projects\Spendly\splixa_app"
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

Then, on a device, check Arabic end-to-end (RTL layout, digit shaping) and a long-text locale (German/French) on a small screen.

## Open items before Phase 2 can be signed off

1. Native-speaker review of the 10 new locales — priority: paywall, legal and destructive-action copy.
2. No ICU plural forms. Launch copy uses count-agnostic phrasing (`{count} members`); RU/AR/PL read slightly flat in the few affected strings.
3. Text expansion and RTL not yet verified on a physical small screen.
4. Arabic digit shaping depends on `intl`'s numbering system for `ar` — eyeball it on device.

## Adding a locale later

1. Copy `lib/core/l10n/strings_en.dart` to `strings_<code>.dart`, rename the map variable, translate the values.
2. Add it to `AppStrings.catalog` in `app_strings.dart`.
3. Set `translationReady: true` on that `AppLanguage` value.
4. Add it to `launchLocales` in `test/localization_catalog_test.dart`.

`flutter test` then enforces key parity and placeholder compatibility for it.

---

# Round 2 — device-testing fixes (after the first handoff)

Four defects surfaced only on a real device. All fixed, all verified; `flutter analyze` clean, 44 tests pass, `0.6.0-alpha (6)` shipped.

1. **Raw keys rendered to the user.** `splixa_profile_screen.dart` asked for `profile_edit`, `profile_change_password`, `profile_currency`; the catalog defines those with a `_tile` suffix. `AppStrings.of` returns the key when it misses, so nothing crashed — the literal `profile_edit` just appeared on screen. Predates Phase 2.
   **Systemic fix:** `test/localization_key_usage_test.dart` scans every `tr` / `trp` / `AppStrings.of` / `AppStrings.format` call site and fails if the key is not in `strings_en.dart`. The catalog test proves defined keys resolve; this proves requested keys exist. Full-tree run: 443 keys, 399 call sites, 0 missing.
   *Known gap:* dynamic keys (`'${page.keyPrefix}_title'` in onboarding) are invisible to this scan; they are covered by the catalog parity test instead.

2. **Language dropdown truncated every entry.** `DropdownButton`'s menu inherits the button width — in a 62 px header pill everything became "Eng…". Replaced with `showLanguagePicker` (full sheet, native + English name, check mark). Removed from dashboard and home; lives in Profile › Preferences. `AppLanguageButton` (compact pill) is used on the onboarding first slide only.

3. **Profile restructured** into labelled sections — Subscription, Account, Preferences, Support, Legal, Danger zone — and the settings bottom sheet was inlined into Preferences.

4. **Onboarding skipped on a fresh install.** Router logic was correct; Android auto-backup (`allowBackup` defaults true, no rules file) restored `FlutterSharedPreferences.xml` from Google Drive including the onboarding flag. Added `android/app/src/main/res/xml/backup_rules.xml` + `data_extraction_rules.xml` excluding shared preferences and secure storage, wired into the manifest. Also: the login back arrow navigated to `/onboarding` and was bounced back by the redirect — deliberate replays now pass via `?replay=1`.

## Paywall currency — checked, no change needed

Every paywall amount comes from RevenueCat `StoreProduct.priceString` / `pricePerMonthString`. The app's own expense-currency selector (₺/$/€) never touches subscription UI. The one raw numeric price use is an internal Best Value comparison, never rendered.

Google Play returns prices in the currency of the **buyer's Play billing country** — not device language, not app locale. A Turkish account always sees TRY; that is correct. To verify other countries, use a licence-tester account registered in that country (Play Console › Setup › License testing).

## Open for Phase 3 / pre-launch

- **Native-speaker review** of the 10 machine-assisted locales — paywall, legal and destructive-action copy first. Only open Phase 2 item.
- **No ICU plural forms.** Count strings use count-agnostic phrasing; reads flat in RU/AR/PL.
- **Play Store listing translations** not yet added for the new locales — the app is localized but the store page is not.

## Conventions Phase 3 must keep

- New user-facing text goes into `lib/core/l10n/strings_en.dart` first, then every other dictionary (tests enforce parity).
- Read it with `tr(ref, 'key')`, or `trp(ref, 'key', {...})` for `{placeholder}` substitution.
- Numbers, dates and relative time go through `AppFormat` — never `DateFormat`/`NumberFormat` directly, and never a hardcoded currency symbol.
- Layout uses `EdgeInsetsDirectional` / `AlignmentDirectional` / `PositionedDirectional` so Arabic stays correct.
