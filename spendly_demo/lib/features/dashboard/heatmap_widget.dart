import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../core/app_strings.dart';
import 'heatmap_provider.dart';

class HeatmapCard extends ConsumerWidget {
  const HeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapDataProvider);
    final primary = Theme.of(context).colorScheme.primary;
    // Tints derived from the actual theme color instead of a separately
    // hand-picked purple palette, so this matches the rest of the app.
    final colorsets = {
      1: Color.lerp(Colors.white, primary, 0.25)!,
      2: Color.lerp(Colors.white, primary, 0.55)!,
      3: primary,
    };

    // flutter_heatmap_calendar expects a Map<DateTime, int>
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ref, 'statistics_heatmap_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            HeatMapCalendar(
              datasets: data,
              colorsets: colorsets,
              colorMode: ColorMode.color,
              size: 18,
              flexible: true,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              showColorTip: true,
              monthFontSize: 12,
              weekFontSize: 12,
              fontSize: 10,
              onClick: (value) {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${value.year}-${value.month.toString().padLeft(2,'0')}-${value.day.toString().padLeft(2,'0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('${data[value] ?? 0} ${tr(ref, 'statistics_heatmap_activity_count')}'),
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
