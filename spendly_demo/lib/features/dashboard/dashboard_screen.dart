import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/auth_provider.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import 'activity_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'heatmap_provider.dart';
import 'heatmap_widget.dart';
import '../filters/filters_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalance = ref.watch(netBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final activityAsync = ref.watch(activityProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Bildirimler',
            onPressed: () => context.push('/notifications'),
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
                _buildNetBalanceCard(ref, netBalance, currency),
                const SizedBox(height: 24),
                const Text(
                  'Aktivite Akışı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildActivityFeed(activityAsync),
                const SizedBox(height: 24),
                const Text(
                  'Kategori Dağılımı (Bu Ay)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPieChart(ref, transactionsAsync, currency),
                const SizedBox(height: 24),
                const HeatmapCard(),
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

  Widget _buildQuickAddWidget(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tutar',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.attach_money, size: 20),
                ),
              ),
            ),
            Container(height: 30, width: 1, color: Colors.grey.shade300),
            Expanded(
              flex: 3,
              child: TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  hintText: 'Kategori',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0 || categoryController.text.isEmpty) return;
                final user = ref.read(authClientProvider).currentUser;
                if (user == null) return;
                final transaction = TransactionModel(
                  userId: user.id,
                  amount: amount,
                  category: categoryController.text,
                  date: DateTime.now(),
                  type: 'expense',
                );
                try {
                  await ref
                      .read(transactionServiceProvider)
                      .addTransaction(transaction);
                  ref.invalidate(transactionsProvider);
                  amountController.clear();
                  categoryController.clear();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(WidgetRef ref, double balance, String currency) {
    final exchanger = ref.watch(exchangeRateProvider);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF3E5F5), // Lighter premium purple
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
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6200EA),
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
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(act.icon, color: Colors.deepPurple, size: 20),
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
      error: (e, st) => Center(child: Text('Hata: $e')),
    );
  }

  Widget _buildPieChart(
    WidgetRef ref,
    AsyncValue<List<TransactionModel>> transactionsAsync,
    String currency,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        final now = DateTime.now();
        final currentMonthExpenses = transactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  t.date.month == now.month &&
                  t.date.year == now.year,
            )
            .toList();

        if (currentMonthExpenses.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text(
                'Bu ay hiç harcamanız yok.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final exchanger = ref.watch(exchangeRateProvider);

        final Map<String, double> categorySums = {};
        for (var t in currentMonthExpenses) {
          final cat = t.category;
          final sanitized = sanitizeCategory(cat);
          if (sanitized.isEmpty) continue;
          categorySums[sanitized] =
              (categorySums[sanitized] ?? 0) +
              exchanger.convertFromTRY(t.amount, currency);
        }

        final List<Color> colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
        ];
        int colorIdx = 0;

        final entries = categorySums.entries.toList();

        final total = categorySums.values.fold<double>(0.0, (p, e) => p + e);

        final List<PieChartSectionData> sections = entries.asMap().entries.map((
          me,
        ) {
          final idx = me.key;
          final e = me.value;
          final color = colors[idx % colors.length];
          final percent = total > 0 ? (e.value / total * 100) : 0.0;
          return PieChartSectionData(
            color: color,
            value: e.value,
            title: '${percent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();
        // Legacy category list (simple vertical list)
        final legacyList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((me) {
            final idx = me.key;
            final e = me.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colors[idx % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

        final chartRow = SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(child: legacyList),
                  ),
                ),
              ),
            ],
          ),
        );

        // simple amounts table to display under the chart
        final amountsCard = Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${e.key}: ${currency}${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [chartRow, const SizedBox(height: 12), amountsCard],
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
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
      error: (e, st) => Center(child: Text('Hata: $e')),
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

  String sanitizeCategory(String raw) {
    final s = raw.trim().replaceAll(RegExp(r"\s+"), ' ');
    if (s.isEmpty) return '';
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
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
                        : const Color(0xFF6200EA),
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

    final user = ref.read(authClientProvider).currentUser;
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
