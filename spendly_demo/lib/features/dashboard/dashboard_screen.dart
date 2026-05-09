import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../auth/auth_provider.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/streak_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalance = ref.watch(netBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          streakAsync.when(
            data: (streak) => streak > 0
                ? Chip(
                    label: Text(
                      '🔥 $streak',
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                    backgroundColor: Colors.orange.shade50,
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Gruplar',
            onPressed: () {
              context.push('/groups');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNetBalanceCard(netBalance),
                const SizedBox(height: 24),
                const Text(
                  'Aktivite Haritası',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildHeatmap(transactionsAsync),
                const SizedBox(height: 24),
                const Text(
                  'Son İşlemler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRecentTransactions(transactionsAsync),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNetBalanceCard(double balance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Net Bakiye',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '₺${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(AsyncValue<List<TransactionModel>> transactionsAsync) {
    return transactionsAsync.when(
      data: (transactions) {
        // Prepare data for the heatmap
        final Map<DateTime, int> datasets = {};
        for (var t in transactions) {
          // Normalize date to remove time portion
          final date = DateTime(t.date.year, t.date.month, t.date.day);
          datasets[date] = (datasets[date] ?? 0) + 1;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: HeatMap(
              datasets: datasets,
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable: true,
              colorsets: const {1: Colors.deepPurpleAccent},
              onClick: (value) {
                // Future use: Filter transactions by date
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Hata: $e')),
    );
  }

  Widget _buildRecentTransactions(
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('Henüz işlem bulunmuyor.')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.take(5).length, // Sadece son 5 işlem
          itemBuilder: (context, index) {
            final t = transactions[index];
            final isIncome = t.type == 'income';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(t.category),
                subtitle: Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                trailing: Text(
                  '${isIncome ? '+' : '-'}₺${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Hata: $e')),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    String type = 'expense';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni İşlem Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Gider')),
                      DropdownMenuItem(value: 'income', child: Text('Gelir')),
                    ],
                    onChanged: (value) => setState(() => type = value!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Miktar (₺)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori (Örn: Market)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;
                    if (amount <= 0 || categoryController.text.isEmpty) return;

                    final user = ref.read(authClientProvider).currentUser;
                    if (user == null) return;

                    final transaction = TransactionModel(
                      userId: user.id,
                      amount: amount,
                      category: categoryController.text,
                      date: DateTime.now(),
                      type: type,
                    );

                    try {
                      await ref
                          .read(transactionServiceProvider)
                          .addTransaction(transaction);
                      ref.invalidate(transactionsProvider); // Listeyi yenile
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                      }
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
