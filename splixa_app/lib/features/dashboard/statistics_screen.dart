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
            _StatTiles(range: range),
            const SizedBox(height: 24),
            _MonthlySpendCard(range: range),
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

/// Expenses in [range] (or the trailing six months when none is picked),
/// bucketed by calendar month and sorted oldest first.
List<MapEntry<DateTime, double>> _monthlyTotals(
  List<TransactionModel> transactions,
  DateTimeRange? range,
  ExchangeRateService exchanger,
  String currency,
) {
  final now = DateTime.now();
  final start = range == null
      ? DateTime(now.year, now.month - 5)
      : DateTime(range.start.year, range.start.month);
  final end = range == null ? DateTime(now.year, now.month + 1, 0) : range.end;

  final totals = <DateTime, double>{};
  // Every month in the window is seeded at zero first, so a quiet month shows
  // as a gap in the series rather than vanishing and making the axis lie about
  // how much time passed.
  for (var m = start; !m.isAfter(end); m = DateTime(m.year, m.month + 1)) {
    totals[DateTime(m.year, m.month)] = 0;
  }
  for (final t in transactions) {
    if (t.type != 'expense') continue;
    if (t.date.isBefore(start) || t.date.isAfter(end)) continue;
    final key = DateTime(t.date.year, t.date.month);
    if (!totals.containsKey(key)) continue;
    totals[key] =
        totals[key]! + exchanger.convertFromTRY(t.baseAmount, currency);
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

/// Spend per month.
///
/// A single series, so it takes one hue rather than a categorical palette and
/// needs no legend -- the title names it. The tallest month is labelled and the
/// rest are not, because a number over every bar is noise when the shape is the
/// point.
class _MonthlySpendCard extends ConsumerWidget {
  const _MonthlySpendCard({required this.range});
  final DateTimeRange? range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'statistics_monthly_trend'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            transactionsAsync.when(
              loading: () =>
                  const SplixaSkeletonView(type: SplixaSkeletonType.compact),
              error: (e, _) => Text(friendlyErrorMessage(e)),
              data: (transactions) {
                final entries = _monthlyTotals(
                  transactions,
                  range,
                  ref.watch(exchangeRateProvider),
                  currency,
                );
                final maxValue = entries.fold<double>(
                  0,
                  (m, e) => e.value > m ? e.value : m,
                );
                if (maxValue <= 0) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        tr(ref, 'statistics_no_expenses_this_month'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 170,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue * 1.25,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 2,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: scheme.outlineVariant.withValues(alpha: .5),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  AppFormat.monthYear(entries[index].key),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${AppFormat.monthYear(entries[group.x].key)}\n'
                            '${AppFormat.amountWithSymbol(rod.toY, currency)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < entries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: entries[i].value,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                color: entries[i].value == maxValue
                                    ? scheme.primary
                                    : scheme.primary.withValues(alpha: .45),
                              ),
                            ],
                            showingTooltipIndicators:
                                entries[i].value == maxValue ? [0] : const [],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Three headline numbers. Deliberately not a chart: "how much, how fast, what
/// was the worst one" are single values, and a plot of three points would say
/// less than the numbers themselves.
class _StatTiles extends ConsumerWidget {
  const _StatTiles({required this.range});
  final DateTimeRange? range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);

    return transactionsAsync.maybeWhen(
      data: (transactions) {
        final now = DateTime.now();
        final start = range?.start ?? DateTime(now.year, now.month);
        final end = range?.end ?? DateTime(now.year, now.month + 1, 0);
        final inRange = transactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  !t.date.isBefore(start) &&
                  !t.date.isAfter(end),
            )
            .toList();
        if (inRange.isEmpty) return const SizedBox.shrink();

        final total = inRange.fold<double>(
          0,
          (sum, t) => sum + exchanger.convertFromTRY(t.baseAmount, currency),
        );
        // At least one day, so a single-day range does not divide by zero and
        // report an infinite daily average.
        final days = end.difference(start).inDays + 1;
        final largest = inRange
            .map((t) => exchanger.convertFromTRY(t.baseAmount, currency))
            .reduce((a, b) => a > b ? a : b);

        return Row(
          children: [
            _Tile(
              label: tr(ref, 'statistics_total'),
              value: AppFormat.amountWithSymbol(total, currency),
            ),
            const SizedBox(width: 8),
            _Tile(
              label: tr(ref, 'statistics_daily_average'),
              value: AppFormat.amountWithSymbol(total / days, currency),
            ),
            const SizedBox(width: 8),
            _Tile(
              label: tr(ref, 'statistics_largest'),
              value: AppFormat.amountWithSymbol(largest, currency),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
