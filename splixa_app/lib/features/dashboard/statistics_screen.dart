import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/friendly_error.dart';
import '../../core/app_strings.dart';
import '../../core/app_formatting.dart';
import '../../core/splixa_loading.dart';
import '../transactions/transaction_provider.dart';
import '../transactions/transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import '../subscriptions/premium_provider.dart';
import '../subscriptions/pro_access.dart';
import 'heatmap_provider.dart';
import 'heatmap_widget.dart';

/// Split out of DashboardScreen so the main tab stays a quick "where do I
/// stand today" summary instead of a long scroll of charts + a heatmap.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    if (!ref.watch(premiumProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'statistics_title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  tr(ref, 'pro_tools_locked'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () =>
                      requirePro(context, ref, ProFeature.advancedAnalytics),
                  child: Text(tr(ref, 'profile_upgrade_pro')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    // Held in a provider, not in this State, so the pie chart and the heatmap
    // can never disagree about which window is on screen.
    final range = ref.watch(heatmapRangeProvider);

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
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded),
              label: Text(
                range == null
                    ? tr(ref, 'statistics_current_month')
                    : '${AppFormat.shortDate(range.start)} – ${AppFormat.shortDate(range.end)}',
              ),
            ),
            const SizedBox(height: 8),
            _buildPieChart(ref, transactionsAsync, currency, range),
            const SizedBox(height: 24),
            HeatmapCard(initialMonth: range?.start),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    WidgetRef ref,
    AsyncValue<List<TransactionModel>> transactionsAsync,
    String currency,
    DateTimeRange? range,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        final now = DateTime.now();
        final effectiveStart = range?.start ?? DateTime(now.year, now.month);
        final effectiveEnd = range?.end ?? DateTime(now.year, now.month + 1, 0);
        final currentMonthExpenses = transactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  !t.date.isBefore(effectiveStart) &&
                  !t.date.isAfter(effectiveEnd),
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
              exchanger.convertFromTRY(t.baseAmount, currency);
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
                    margin: const EdgeInsetsDirectional.only(end: 8),
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
      loading: () =>
          const SplixaSkeletonView(type: SplixaSkeletonType.dashboard),
      error: (e, st) => SplixaErrorState(
        message: friendlyErrorMessage(e),
        onRetry: () => ref.invalidate(transactionsProvider),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          ref.read(heatmapRangeProvider) ??
          DateTimeRange(
            start: DateTime(now.year, now.month),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );
    if (result != null && mounted) {
      ref.read(heatmapRangeProvider.notifier).state = result;
    }
  }

  String sanitizeCategory(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return '';
    final lower = s.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
