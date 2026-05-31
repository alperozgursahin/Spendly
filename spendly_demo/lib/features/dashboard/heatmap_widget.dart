import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'heatmap_provider.dart';

class HeatmapCard extends ConsumerWidget {
  const HeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapDataProvider);

    // flutter_heatmap_calendar expects a Map<DateTime, int>
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aktivasyon Isı Haritası', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            HeatMapCalendar(
              datasets: data,
              colorsets: const {
                1: Color(0xFFE9E0FB),
                2: Color(0xFFBDA4FF),
                3: Color(0xFF6F2DBD),
              },
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
                          Text('${data[value] ?? 0} aktivite'),
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
