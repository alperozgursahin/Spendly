import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/app_strings.dart';

/// Guards against a key that is *asked for* but never *defined*.
///
/// `AppStrings.of` degrades to returning the key itself, so a typo or a renamed
/// key does not crash — it silently ships raw text like "profile_edit" to the
/// user. The catalog test proves every defined key resolves; this one proves
/// every requested key is defined, which is the other half.
void main() {
  test('every requested localization key exists in the source catalog', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    final missing = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/core/l10n/')) continue;

      final source = entity.readAsStringSync();
      for (final match in _keyPattern.allMatches(source)) {
        // The pattern has two alternatives: tr/trp put the key in group 2,
        // AppStrings.of/format in group 4. Exactly one is non-null per match.
        final key = match.group(2) ?? match.group(4)!;
        if (AppStrings.source.containsKey(key)) continue;

        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        missing.add('$path:$line  "$key"');
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'These call sites request keys that do not exist in '
          'lib/core/l10n/strings_en.dart, so the raw key would be shown to the '
          'user:\n${missing.join('\n')}',
    );
  });
}

/// Matches `tr(ref, 'key')`, `trp(ref, 'key', …)`, `AppStrings.of('key', …)`
/// and `AppStrings.format('key', …)`, including the line-wrapped forms
/// `dart format` produces.
final _keyPattern = RegExp(
  r"""\b(?:tr|trp)\(\s*\w+\s*,\s*(['"])([a-z0-9_]+)\1"""
  r"""|\bAppStrings\.(?:of|format)\(\s*(['"])([a-z0-9_]+)\3""",
);
