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
