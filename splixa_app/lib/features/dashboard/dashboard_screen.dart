import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/friendly_error.dart';
import '../../core/app_strings.dart';
import '../../core/locale_provider.dart';
import '../../core/app_theme_provider.dart';
import '../auth/auth_provider.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/currency_selector.dart';
import '../profile/exchange_rate_provider.dart';
import 'activity_provider.dart';
import '../filters/filters_provider.dart';
import '../notifications/notification_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    this.embedded = false,
    this.includeQuickAdd = true,
    this.showEmbeddedTools = true,
    this.showBalance = true,
    this.showActivity = true,
    this.showRecentTransactions = true,
  });

  /// Renders the legacy data-rich dashboard sections without a nested
  /// Scaffold/scroll view so the modern Splixa home can compose them safely.
  final bool embedded;
  final bool includeQuickAdd;
  final bool showEmbeddedTools;
  final bool showBalance;
  final bool showActivity;
  final bool showRecentTransactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalance = ref.watch(netBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final activityAsync = ref.watch(activityProvider);
    final currency = ref.watch(currencyProvider);
    final userId = ref.watch(currentUserIdProvider);
    final unreadNotificationCount = userId == null
        ? 0
        : ref.watch(unreadNotificationCountProvider(userId));

    final dashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (embedded && showEmbeddedTools) ...[
          Row(
            children: [
              Text(
                tr(ref, 'dashboard_title'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _buildLanguageToggle(context, ref),
              const SizedBox(width: 8),
              _buildThemeToggle(context, ref),
              IconButton(
                icon: const Icon(Icons.insights_outlined),
                tooltip: tr(ref, 'dashboard_statistics'),
                onPressed: () => context.push('/dashboard/statistics'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (includeQuickAdd) ...[
          const QuickAddWidget(),
          const SizedBox(height: 16),
        ],
        if (showBalance)
          _buildNetBalanceCard(context, ref, netBalance, currency),
        if (showActivity) ...[
          if (showBalance || includeQuickAdd) const SizedBox(height: 24),
          Text(
            tr(ref, 'dashboard_activity_feed'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildActivityFeed(ref, activityAsync),
        ],
        if (showRecentTransactions) ...[
          if (showBalance || showActivity || includeQuickAdd)
            const SizedBox(height: 24),
          Text(
            tr(ref, 'dashboard_recent_transactions'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildDashboardFilterBar(context, ref, transactionsAsync),
          const SizedBox(height: 8),
          _buildStaticDateTransactions(ref, transactionsAsync, currency),
        ],
      ],
    );

    if (embedded) return dashboardContent;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 132,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageToggle(context, ref),
              const SizedBox(width: 8),
              _buildThemeToggle(context, ref),
            ],
          ),
        ),
        title: Text(tr(ref, 'dashboard_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: tr(ref, 'dashboard_statistics'),
            onPressed: () => context.push('/dashboard/statistics'),
          ),
          Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(unreadNotificationCount.toString()),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: tr(ref, 'dashboard_notifications'),
              onPressed: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(activityProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: dashboardContent,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Widget option(String label, AppLanguage value) {
      final isSelected = language == value;
      return GestureDetector(
        onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('TR', AppLanguage.tr), option('EN', AppLanguage.en)],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => ref.read(appThemeModeProvider.notifier).toggle(),
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDashboardFilterBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
    final filters = ref.watch(transactionFilterProvider);
    final txs = transactionsAsync.maybeWhen(
      data: (txs) => txs,
      orElse: () => <TransactionModel>[],
    );
    final cats = txs.map((t) => t.category).toSet().toList()..sort();
    var selectedType = filters.type;
    var selectedCategory = filters.category;
    DateTime? selectedStart = filters.start;
    DateTime? selectedEnd = filters.end;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            if (selectedCategory.isNotEmpty &&
                !cats.contains(selectedCategory)) {
              selectedCategory = '';
            }
            if (selectedType.isNotEmpty &&
                !{'income', 'expense'}.contains(selectedType)) {
              selectedType = '';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    tr(ref, 'common_category'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(tr(ref, 'common_all')),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(categoryLabel(ref, c)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setLocalState(() => selectedCategory = value ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: '',
                            label: _fittedLabel(tr(ref, 'common_all')),
                          ),
                          ButtonSegment(
                            value: 'expense',
                            label: _fittedLabel(tr(ref, 'common_expense')),
                          ),
                          ButtonSegment(
                            value: 'income',
                            label: _fittedLabel(tr(ref, 'common_income')),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (newSelection) {
                          setLocalState(() {
                            selectedType = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final r = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 3650),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (r != null) {
                            setLocalState(() {
                              selectedStart = r.start;
                              selectedEnd = r.end;
                            });
                          }
                        },
                        child: Text(
                          selectedStart != null && selectedEnd != null
                              ? '${selectedStart!.day}.${selectedStart!.month}.${selectedStart!.year} - ${selectedEnd!.day}.${selectedEnd!.month}.${selectedEnd!.year}'
                              : tr(ref, 'dashboard_pick_date'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final notifier = ref.read(
                        transactionFilterProvider.notifier,
                      );
                      notifier.setCategory(selectedCategory);
                      notifier.setType(selectedType);
                      notifier.setDateRange(selectedStart, selectedEnd);
                    },
                    icon: const Icon(Icons.filter_alt),
                    label: Text(tr(ref, 'common_filter')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(
    BuildContext context,
    WidgetRef ref,
    double balance,
    String currency,
  ) {
    final exchanger = ref.watch(exchangeRateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              tr(ref, 'dashboard_net_balance'),
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currency${exchanger.convertFromTRY(balance, currency).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colorScheme.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(
    WidgetRef ref,
    AsyncValue<List<ActivityItem>> activityAsync,
  ) {
    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                tr(ref, 'dashboard_no_activity'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final act = activities[index];
            final colorScheme = Theme.of(context).colorScheme;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(act.icon, color: colorScheme.primary, size: 20),
              ),
              title: Text(
                act.description,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                act.createdAt.toLocal().toString().split('.')[0],
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }

  Widget _buildStaticDateTransactions(
    WidgetRef ref,
    AsyncValue<List<TransactionModel>> transactionsAsync,
    String currency,
  ) {
    final filters = ref.watch(transactionFilterProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // apply client-side filters
        final filtered = transactions.where((t) {
          if (filters.start != null && filters.end != null) {
            if (t.date.isBefore(filters.start!) ||
                t.date.isAfter(filters.end!)) {
              return false;
            }
          }
          if (filters.category.isNotEmpty) {
            if (t.category != filters.category) return false;
          }
          if (filters.type.isNotEmpty) {
            if (t.type != filters.type) return false;
          }
          if (filters.personId.isNotEmpty) {
            if (t.userId != filters.personId) return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(child: Text(tr(ref, 'dashboard_no_transactions'))),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.take(10).length,
          itemBuilder: (context, index) {
            final t = filtered[index];
            final isIncome = t.type == 'income';
            final exchanger = ref.watch(exchangeRateProvider);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.date.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          _monthAbbr(ref, t.date.month),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Transaction Details
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isIncome
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          categoryLabel(ref, t.category),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}$currency${exchanger.convertFromTRY(t.amount, currency).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isIncome ? Colors.green : Colors.red,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }

  String _monthAbbr(WidgetRef ref, int month) {
    if (month >= 1 && month <= 12) return tr(ref, _monthKeys[month - 1]);
    return '';
  }
}

/// Shrinks a segmented-button label to fit instead of wrapping/overflowing —
/// English translations ("Expense"/"Income") are noticeably wider than the
/// Turkish originals ("Gider"/"Gelir") they were sized for.
Widget _fittedLabel(String text) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}

const _monthKeys = [
  'month_jan',
  'month_feb',
  'month_mar',
  'month_apr',
  'month_may',
  'month_jun',
  'month_jul',
  'month_aug',
  'month_sep',
  'month_oct',
  'month_nov',
  'month_dec',
];

class QuickAddWidget extends ConsumerStatefulWidget {
  const QuickAddWidget({super.key});

  @override
  ConsumerState<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends ConsumerState<QuickAddWidget> {
  final amountController = TextEditingController();
  final customCategoryController = TextEditingController();

  String transactionType = 'expense';
  String selectedCategory = 'Market';
  String? selectedCurrency;

  final List<String> predefinedCategories = [
    'Market',
    'Yemek',
    'Ulaşım',
    'Eğlence',
    'Maaş',
    'Aidat',
    'Fatura',
    'Diğer',
  ];

  @override
  void dispose() {
    amountController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = selectedCategory == 'Diğer';
    final isIncome = transactionType == 'income';
    final profileCurrency = ref.watch(currencyProvider);
    final currency = selectedCurrency ?? profileCurrency;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'expense',
                        label: _fittedLabel(tr(ref, 'common_expense')),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: _fittedLabel(tr(ref, 'common_income')),
                      ),
                    ],
                    selected: {transactionType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        transactionType = newSelection.first;
                        if (transactionType == 'income') {
                          selectedCategory = 'Maaş';
                        } else {
                          selectedCategory = 'Market';
                        }
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: isIncome
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: tr(ref, 'dashboard_amount_hint'),
                      isDense: true,
                      prefixText: '$currency ',
                      prefixStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CurrencySelector(
              value: currency,
              labelText: tr(ref, 'common_currency'),
              compact: true,
              onChanged: (value) {
                setState(() => selectedCurrency = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isOther
                      ? TextField(
                          controller: customCategoryController,
                          decoration: InputDecoration(
                            hintText: tr(ref, 'dashboard_custom_category_hint'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() {
                                selectedCategory = predefinedCategories.first;
                                customCategoryController.clear();
                              }),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: Theme.of(context).cardTheme.color,
                              items: predefinedCategories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    categoryLabel(ref, c),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveTransaction,
                  child: const Icon(Icons.send, size: 20, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amount =
        double.tryParse(amountController.text.trim().replaceAll(',', '.')) ??
        0.0;
    final finalCategory = selectedCategory == 'Diğer'
        ? customCategoryController.text.trim()
        : selectedCategory;

    if (amount <= 0 || finalCategory.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final String entryCurrency = selectedCurrency ?? ref.read(currencyProvider);
    final exchanger = ref.read(exchangeRateProvider);
    final canConvert = entryCurrency == '₺' || await exchanger.ensureFresh();
    if (!canConvert) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'exchange_rate_unavailable'))),
        );
      }
      return;
    }
    final amountInTRY = double.parse(
      exchanger.convertToTRY(amount, entryCurrency).toStringAsFixed(2),
    );

    final transaction = TransactionModel(
      userId: user.id,
      amount: amountInTRY,
      category: finalCategory,
      date: DateTime.now(),
      type: transactionType,
    );

    try {
      await ref.read(transactionServiceProvider).addTransaction(transaction);
      ref.invalidate(transactionsProvider);

      amountController.clear();
      if (selectedCategory == 'Diğer') customCategoryController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'dashboard_transaction_added')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
