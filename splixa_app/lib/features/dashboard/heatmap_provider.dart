import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transactions/transaction_provider.dart';

// Supported ranges: 1M,3M,6M,1Y
final heatmapRangeProvider = StateProvider<String>((ref) => '1M');

final heatmapDataProvider = Provider.autoDispose<Map<DateTime, int>>((ref) {
  final range = ref.watch(heatmapRangeProvider);
  final transactionsAsync = ref.watch(transactionsProvider);

  final Map<DateTime, int> counts = {};

  transactionsAsync.maybeWhen(
    data: (transactions) {
      final now = DateTime.now();
      DateTime since;
      switch (range) {
        case '3M':
          since = DateTime(now.year, now.month - 3, now.day);
          break;
        case '6M':
          since = DateTime(now.year, now.month - 6, now.day);
          break;
        case '1Y':
          since = DateTime(now.year - 1, now.month, now.day);
          break;
        case '1M':
        default:
          since = DateTime(now.year, now.month, 1);
      }

      for (var t in transactions) {
        if (t.date.isBefore(since)) continue;
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        counts[d] = (counts[d] ?? 0) + 1;
      }
    },
    orElse: () {},
  );

  return counts;
});
