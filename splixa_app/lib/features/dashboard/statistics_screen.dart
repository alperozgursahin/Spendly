import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/friendly_error.dart';
import '../../core/app_strings.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import 'heatmap_widget.dart';

/// Split out of DashboardScreen so the main tab stays a quick "where do I
/// stand today" summary instead of a long scroll of charts + a heatmap.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'statistics_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref, 'statistics_category_distribution'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPieChart(ref, transactionsAsync, currency),
            const SizedBox(height: 24),
            const HeatmapCard(),
          ],
        ),
      ),
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
          return SizedBox(
            height: 150,
            child: Center(
              child: Text(
                tr(ref, 'statistics_no_expenses_this_month'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final exchanger = ref.watch(exchangeRateProvider);

        final Map<String, double> categorySums = {};
        for (var t in currentMonthExpenses) {
          final sanitized = sanitizeCategory(t.category);
          if (sanitized.isEmpty) continue;
          categorySums[sanitized] =
              (categorySums[sanitized] ?? 0) +
              exchanger.convertFromTRY(t.amount, currency);
        }

        // Validated categorical palette (dataviz skill's references/palette.md):
        // fixed hue order chosen so adjacent slices stay distinguishable even
        // under color-blindness. Shares hues with group_detail_screen.dart's
        // status chips (blue/green/amber/red) so the whole app reads as one
        // cohesive color family.
        const colors = [
          Color(0xFF2563EB), // blue
          Color(0xFF059669), // green
          Color(0xFFD97706), // amber
          Color(0xFF7C3AED), // violet
          Color(0xFFDC2626), // red
          Color(0xFFDB2777), // pink
        ];

        final entries = categorySums.entries.toList();
        final total = categorySums.values.fold<double>(0.0, (p, e) => p + e);

        final sections = entries.asMap().entries.map((me) {
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

        // A single list doing double duty as the chart's legend AND the
        // amount breakdown, instead of two separate cards repeating the
        // same category names.
        final categoryList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((me) {
            final idx = me.key;
            final e = me.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
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
                      categoryLabel(ref, e.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currency${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: categoryList,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
    );
  }

  String sanitizeCategory(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return '';
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
