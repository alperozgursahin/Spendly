import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import 'activity_provider.dart';
import '../filters/filters_provider.dart';
import '../notifications/notification_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'İstatistikler',
            onPressed: () => context.push('/dashboard/statistics'),
          ),
          Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(unreadNotificationCount.toString()),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Bildirimler',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuickAddWidget(),
                const SizedBox(height: 16),
                _buildNetBalanceCard(context, ref, netBalance, currency),
                const SizedBox(height: 24),
                const Text(
                  'Aktivite Akışı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildActivityFeed(activityAsync),
                const SizedBox(height: 24),
                const Text(
                  'Son İşlemler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDashboardFilterBar(context, ref, transactionsAsync),
                const SizedBox(height: 8),
                _buildStaticDateTransactions(ref, transactionsAsync, currency),
              ],
            ),
          ),
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
        padding: const EdgeInsets.all(8.0),
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Hepsi'),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
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
                        segments: const [
                          ButtonSegment(value: '', label: Text('Hepsi')),
                          ButtonSegment(value: 'expense', label: Text('Gider')),
                          ButtonSegment(value: 'income', label: Text('Gelir')),
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
                              : 'Tarih seç',
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
                    label: const Text('Filtrele'),
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
            const Text(
              'Net Bakiye',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currency${exchanger.convertFromTRY(balance, currency).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(AsyncValue<List<ActivityItem>> activityAsync) {
    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Henüz sosyal aktivite yok.',
                style: TextStyle(color: Colors.grey),
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
            if (t.date.isBefore(filters.start!) || t.date.isAfter(filters.end!))
              return false;
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
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('Henüz işlem bulunmuyor.')),
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
                          _monthAbbr(t.date.month),
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
                          t.category,
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

  String _monthAbbr(int month) {
    const abbrs = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    if (month >= 1 && month <= 12) return abbrs[month - 1];
    return '';
  }
}

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
    final currency = ref.watch(currencyProvider);

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
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Gider', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Gelir', style: TextStyle(fontSize: 12)),
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
                      hintText: 'Tutar',
                      isDense: true,
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
            Row(
              children: [
                Expanded(
                  child: isOther
                      ? TextField(
                          controller: customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'Özel kategori girin...',
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isDense: true,
                              isExpanded: true,
                              items: predefinedCategories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedCategory = val);
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
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final finalCategory = selectedCategory == 'Diğer'
        ? customCategoryController.text.trim()
        : selectedCategory;

    if (amount <= 0 || finalCategory.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final selectedCurrency = ref.read(currencyProvider);
    final exchanger = ref.read(exchangeRateProvider);
    final amountInTRY = exchanger.convertToTRY(amount, selectedCurrency);

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
          const SnackBar(
            content: Text('İşlem eklendi!'),
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
