import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_strings.dart';
import 'locale_provider.dart';

/// Opens the full language list as a modal sheet.
///
/// A dropdown was previously used inline, but its menu inherits the button's
/// width — inside a compact header that truncated every entry to "Eng…",
/// "Esp…". A sheet gives each language its full native and English name at any
/// screen size, which matters most for the locales a user cannot read yet.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _LanguagePickerSheet(),
  );
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appLanguageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                tr(ref, 'language_picker_title'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: supportedAppLanguages.length,
                itemBuilder: (context, index) {
                  final language = supportedAppLanguages[index];
                  final isSelected = language == selected;
                  return ListTile(
                    title: Text(
                      language.nativeName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: language.nativeName == language.englishName
                        ? null
                        : Text(language.englishName),
                    // The language's own script is always shown left-to-right
                    // here, independent of the app's current direction.
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      child: Text(
                        language.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      ref
                          .read(appLanguageProvider.notifier)
                          .setLanguage(language);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill showing the active language code; opens [showLanguagePicker].
/// Used where header space is tight, such as the onboarding first slide.
class AppLanguageButton extends ConsumerWidget {
  const AppLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appLanguageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: tr(ref, 'language_selector_label'),
      button: true,
      child: InkWell(
        onTap: () => showLanguagePicker(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 17),
              const SizedBox(width: 6),
              Text(
                selected.code.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings row showing the active language and opening the full picker.
class AppLanguageTile extends ConsumerWidget {
  const AppLanguageTile({super.key, this.contentPadding});

  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appLanguageProvider);

    return ListTile(
      contentPadding: contentPadding,
      leading: const Icon(Icons.language_rounded),
      title: Text(tr(ref, 'language_selector_label')),
      subtitle: Text(selected.nativeName),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showLanguagePicker(context),
    );
  }
}
