import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transactions/transaction_provider.dart';

/// The window the heatmap counts activity over.
///
/// `null` means "everything on record". That is deliberately the default: the
/// heatmap renders one month at a time and lets the user page backwards, so a
/// rolling window silently blanked out every month before it — activity from
/// July was simply missing when July was on screen. The range is only ever
/// narrowed when the statistics screen's date-range picker sets it.
final heatmapRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Day -> number of transactions on that day, keyed by midnight local time
/// because `HeatMapCalendar` matches its dataset keys by exact `DateTime`.
final heatmapDataProvider = Provider.autoDispose<Map<DateTime, int>>((ref) {
  final range = ref.watch(heatmapRangeProvider);
  final transactionsAsync = ref.watch(transactionsProvider);

  final Map<DateTime, int> counts = {};

  DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  transactionsAsync.maybeWhen(
    data: (transactions) {
      // Compare whole days. A range picker hands back midnight for both ends,
      // so an expense recorded at 14:00 on the last day would otherwise fall
      // outside its own range.
      final start = range == null ? null : dayOf(range.start);
      final end = range == null ? null : dayOf(range.end);

      for (final t in transactions) {
        final d = dayOf(t.date);
        if (start != null && d.isBefore(start)) continue;
        if (end != null && d.isAfter(end)) continue;
        counts[d] = (counts[d] ?? 0) + 1;
      }
    },
    orElse: () {},
  );

  return counts;
});
