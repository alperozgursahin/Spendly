import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/analytics_service.dart';
import '../../core/app_formatting.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/locale_provider.dart';
import '../../core/splixa_loading.dart';
import '../profile/currency_provider.dart';
import '../profile/currency_selector.dart';
import '../profile/exchange_rate_provider.dart';
import '../profile/services/pdf_export_service.dart';
import '../transactions/transaction_provider.dart';
import 'app_lock_service.dart';
import 'home_widget_service.dart';
import 'premium_provider.dart';
import 'pro_access.dart';
import 'pro_features_provider.dart';

class ProToolsScreen extends ConsumerWidget {
  const ProToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'pro_tools_title'))),
      body: isPro
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _UsageCard(),
                const SizedBox(height: 12),
                _SecurityAndWidgetCard(),
                const SizedBox(height: 12),
                _CustomCategoriesCard(),
                const SizedBox(height: 12),
                _RecurringExpensesCard(),
                const SizedBox(height: 12),
                _ExportsCard(),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      tr(ref, 'pro_tools_locked'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => context.push(
                        '/paywall?source=${PaywallSource.profile.analyticsValue}',
                      ),
                      child: Text(tr(ref, 'profile_upgrade_pro')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _UsageCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(proUsageProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: usage.when(
          loading: () =>
              const SplixaSkeletonView(type: SplixaSkeletonType.compact),
          error: (error, _) => Text(friendlyErrorMessage(error)),
          data: (value) => Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF0E7490)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value?.isPro == true
                      ? tr(ref, 'pro_server_verified')
                      : tr(ref, 'pro_sync_pending'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityAndWidgetCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: Text(tr(ref, 'pro_biometric_lock')),
            subtitle: Text(tr(ref, 'pro_biometric_lock_body')),
            value: lock.enabled,
            onChanged: (value) async {
              final success = await lock.setEnabled(value);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(ref, 'pro_biometric_unavailable'))),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.widgets_rounded),
            title: Text(tr(ref, 'pro_home_widget')),
            subtitle: Text(tr(ref, 'pro_home_widget_body')),
            trailing: const Icon(Icons.add_to_home_screen_rounded),
            onTap: () async {
              await SplixaHomeWidgetService.update(isPro: true);
              final supported = await HomeWidget.isRequestPinWidgetSupported();
              if (supported == true) {
                await HomeWidget.requestPinWidget(
                  name: SplixaHomeWidgetService.androidProviderName,
                  androidName: SplixaHomeWidgetService.androidProviderName,
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(ref, 'pro_home_widget_manual'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CustomCategoriesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(customCategoriesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(ref, 'pro_custom_categories'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr(ref, 'pro_category_add'),
                  onPressed: () => _addCategory(context, ref),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            categories.when(
              loading: () =>
                  const SplixaSkeletonView(type: SplixaSkeletonType.compact),
              error: (error, _) => Text(friendlyErrorMessage(error)),
              data: (items) => items.isEmpty
                  ? Text(tr(ref, 'pro_categories_empty'))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items
                          .map(
                            (item) => InputChip(
                              label: Text(item.name),
                              onPressed: () =>
                                  _editCategory(context, ref, item),
                              onDeleted: () => ref
                                  .read(proFeaturesServiceProvider)
                                  .deleteCustomCategory(item.id),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final saved = await _showCategoryEditor(context, ref);
    if (saved) {
      await ref
          .read(analyticsServiceProvider)
          .proFeatureCompleted(
            feature: ProFeature.customCategories.analyticsValue,
          );
    }
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    CustomCategory category,
  ) async {
    await _showCategoryEditor(context, ref, category: category);
  }

  /// Name-only editor. The colour palette and the separate emoji box are gone:
  /// people were typing an emoji into the name anyway, and two extra decisions
  /// per category bought nothing the list did not already convey.
  Future<bool> _showCategoryEditor(
    BuildContext context,
    WidgetRef ref, {
    CustomCategory? category,
  }) async {
    final name = TextEditingController(text: category?.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(ref, 'pro_category_add')),
        content: TextField(
          controller: name,
          maxLength: 40,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: tr(ref, 'pro_category_name'),
            helperText: tr(ref, 'pro_category_name_helper'),
          ),
          onSubmitted: (_) => _saveCategory(dialogContext, ref, category, name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(ref, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () => _saveCategory(dialogContext, ref, category, name),
            child: Text(tr(ref, 'common_save')),
          ),
        ],
      ),
    );
    name.dispose();
    return saved == true;
  }

  Future<void> _saveCategory(
    BuildContext dialogContext,
    WidgetRef ref,
    CustomCategory? category,
    TextEditingController name,
  ) async {
    if (name.text.trim().isEmpty) return;
    try {
      final service = ref.read(proFeaturesServiceProvider);
      if (category == null) {
        await service.createCustomCategory(name: name.text);
      } else {
        await service.updateCustomCategory(id: category.id, name: name.text);
      }
      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    }
  }
}

class _RecurringExpensesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringExpensesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(ref, 'pro_recurring_expenses'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr(ref, 'pro_recurring_add'),
                  onPressed: () => _addRecurring(context, ref),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            recurring.when(
              loading: () =>
                  const SplixaSkeletonView(type: SplixaSkeletonType.compact),
              error: (error, _) => Text(friendlyErrorMessage(error)),
              data: (items) => items.isEmpty
                  ? Text(tr(ref, 'pro_recurring_empty'))
                  : Column(
                      children: items
                          .map(
                            (item) => SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.title),
                              subtitle: Text(
                                '${AppFormat.amount(item.originalAmount)} ${item.currencyCode} · ${AppFormat.shortDate(item.nextRunAt.toLocal())}',
                              ),
                              value: item.isActive,
                              onChanged: (value) => ref
                                  .read(proFeaturesServiceProvider)
                                  .setRecurringActive(item.id, value),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => ref
                                    .read(proFeaturesServiceProvider)
                                    .deleteRecurringExpense(item.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRecurring(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    var frequency = 'monthly';
    var currency = ref.read(currencyProvider);
    // Defaults to today so the common case -- "start this now" -- is one tap,
    // while still letting a bill that starts next month say so. The previous
    // version silently hard-coded tomorrow at 09:00 and told the user nothing,
    // which is why nobody could work out when anything would happen.
    var startDate = DateUtils.dateOnly(DateTime.now());
    var category = kPredefinedExpenseCategories.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr(ref, 'pro_recurring_add')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'pro_recurring_name'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: tr(ref, 'dashboard_amount_hint'),
                  ),
                ),
                const SizedBox(height: 12),
                CurrencySelector(
                  value: currency,
                  onChanged: (value) => setState(() => currency = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'groups_expense_category_label'),
                  ),
                  items: kPredefinedExpenseCategories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(categoryLabel(ref, c)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'weekly',
                      label: Text(tr(ref, 'pro_frequency_weekly')),
                    ),
                    ButtonSegment(
                      value: 'monthly',
                      label: Text(tr(ref, 'pro_frequency_monthly')),
                    ),
                  ],
                  selected: {frequency},
                  onSelectionChanged: (value) =>
                      setState(() => frequency = value.first),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr(ref, 'pro_recurring_start_date'),
                    border: const OutlineInputBorder(),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final today = DateUtils.dateOnly(DateTime.now());
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: today,
                        lastDate: DateTime(
                          today.year + 2,
                          today.month,
                          today.day,
                        ),
                      );
                      if (picked != null) {
                        setState(() => startDate = DateUtils.dateOnly(picked));
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(child: Text(AppFormat.shortDate(startDate))),
                        const Icon(Icons.event_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // States the rule in words. A recurring expense the user cannot
                // predict is one they will not trust.
                Text(
                  trp(
                    ref,
                    frequency == 'weekly'
                        ? 'pro_recurring_explainer_weekly'
                        : 'pro_recurring_explainer_monthly',
                    {'date': AppFormat.shortDate(startDate)},
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(ref, 'common_cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final parsed = double.tryParse(
                  amount.text.trim().replaceAll(',', '.'),
                );
                if (title.text.trim().isEmpty ||
                    parsed == null ||
                    parsed <= 0) {
                  return;
                }
                try {
                  final exchanger = ref.read(exchangeRateProvider);
                  final option = currencyOptionForSymbol(currency);
                  final isTry = option.code == 'TRY';
                  if (!isTry && !await exchanger.ensureFresh()) return;
                  final rate = isTry ? 1.0 : 1 / exchanger.rateFor(currency);
                  final timezone = await FlutterTimezone.getLocalTimezone();
                  final now = DateTime.now();
                  // Starting today means starting now: the server charges the
                  // first occurrence inline when this moment has passed, so the
                  // expense appears in the balance as soon as the sheet closes.
                  // Anchoring today to 09:00 instead would either skip the
                  // charge (before 09:00) or date it to hours ago (after), and
                  // either way the user would see nothing happen. Future start
                  // dates keep the 09:00 anchor, which is when later runs fire.
                  final isToday = DateUtils.isSameDay(startDate, now);
                  final next = isToday
                      ? now
                      : DateTime(
                          startDate.year,
                          startDate.month,
                          startDate.day,
                          9,
                        );
                  await ref
                      .read(proFeaturesServiceProvider)
                      .createRecurringExpense(
                        title: title.text,
                        category: category,
                        originalAmount: parsed,
                        currencyCode: option.code,
                        exchangeRate: rate,
                        rateSource: isTry
                            ? 'identity'
                            : exchanger.currentRateSource,
                        rateLockedAt: isTry
                            ? now.toUtc()
                            : exchanger.lastUpdatedAt!,
                        frequency: frequency,
                        timezone: timezone.identifier,
                        nextRunAt: next,
                      );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(friendlyErrorMessage(error))),
                    );
                  }
                }
              },
              child: Text(tr(ref, 'common_save')),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    amount.dispose();
    if (saved == true) {
      await ref
          .read(analyticsServiceProvider)
          .proFeatureCompleted(
            feature: ProFeature.recurringExpenses.analyticsValue,
          );
    }
  }
}

class _ExportsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.table_view_rounded),
            title: Text(tr(ref, 'pro_export_csv')),
            onTap: () async {
              try {
                final transactions = await ref.read(
                  transactionsProvider.future,
                );
                await PdfExportService.generateAndShareCsv(
                  transactions,
                  language: ref.read(appLanguageProvider),
                );
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(friendlyErrorMessage(error))),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: Text(tr(ref, 'pro_advanced_analytics')),
            onTap: () => context.push('/statistics'),
          ),
        ],
      ),
    );
  }
}
