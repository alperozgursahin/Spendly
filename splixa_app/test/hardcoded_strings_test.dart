import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 2 hardcoded-string audit.
///
/// Scans every widget source for user-visible text that was written inline
/// instead of going through `AppStrings`. New inline copy fails the build; the
/// only way past is to localize it, or to add it to [_justifiedExceptions] with
/// a reason that survives review.
void main() {
  test('no unlocalized user-visible strings outside the catalog', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'run this test from the package root',
    );

    final findings = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/core/l10n/')) continue;
      if (path.endsWith('/core/app_strings.dart')) continue;

      final source = entity.readAsStringSync();
      final lines = source.split('\n');

      for (final match in _literalPattern.allMatches(source)) {
        final value = match.group(2) ?? match.group(4) ?? '';

        // Composed at runtime from data (usernames, counts, amounts) rather
        // than authored copy.
        if (value.contains(r'$')) continue;
        // Punctuation, separators and symbols carry no language.
        if (!RegExp(r'[A-Za-z]').hasMatch(value)) continue;
        if (_justifiedExceptions[path]?.contains(value) ?? false) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length;
        findings.add('$path:${line + 1}  "$value"  →  ${lines[line].trim()}');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Hardcoded user-visible strings found. Move each into '
          'lib/core/l10n/strings_en.dart and read it with tr(ref, key), or '
          'add a justified exception:\n${findings.join('\n')}',
    );
  });
}

final _literalPattern = RegExp(
  r"""(?:Text|SelectableText)\(\s*(?:const\s+)?(['"])((?:[^'"\\]|\\.)*)\1"""
  r"""|(?:labelText|hintText|helperText|errorText|tooltip|semanticLabel)"""
  r"""\s*:\s*(?:const\s+)?(['"])((?:[^'"\\]|\\.)*)\3""",
);

/// Inline strings that must NOT be translated, with the reason each is exempt.
/// Keep this list short and specific — it is the audit's escape hatch.
const _justifiedExceptions = <String, List<String>>{
  // Brand wordmark and logo glyph: the product name is never translated.
  'lib/core/splixa_design.dart': ['S', 'Splixa'],

  // Google's own brand glyph on the federated sign-in button; Google's brand
  // guidelines require the unmodified mark.
  'lib/features/auth/login_screen.dart': ['G'],

  // ISO currency codes shown next to their symbol. Codes are international
  // identifiers, not copy.
  'lib/features/profile/profile_screen.dart': [
    '₺ (TRY)',
    r'\$ (USD)',
    '€ (EUR)',
  ],
  'lib/features/profile/splixa_profile_screen.dart': [
    '₺ (TRY)',
    r'\$ (USD)',
    '€ (EUR)',
    // The literal word the user must type to confirm account deletion. The
    // surrounding instruction (profile_delete_type_confirm) is translated and
    // names this exact word in every locale, so the token itself stays fixed —
    // translating it would change the confirmation contract per language.
    'DELETE',
  ],
};
