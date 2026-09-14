import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics_service.dart';
import '../../core/app_formatting.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_loading.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import '../subscriptions/pro_access.dart';
import '../subscriptions/premium_provider.dart';
import 'group_provider.dart';

const _brandName = 'Splixa';

class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });
  final String groupId;
  final String groupName;

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(premiumProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'pro_trip_summary'))),
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
                      requirePro(context, ref, ProFeature.tripSummary),
                  child: Text(tr(ref, 'profile_upgrade_pro')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final expenses = ref.watch(groupExpensesStreamProvider(widget.groupId));
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'pro_trip_summary'))),
      body: expenses.when(
        loading: () => const SplixaSkeletonView(
          type: SplixaSkeletonType.cards,
          itemCount: 3,
        ),
        error: (error, _) => SplixaErrorState(
          message: friendlyErrorMessage(error),
          onRetry: () =>
              ref.invalidate(groupExpensesStreamProvider(widget.groupId)),
        ),
        data: (items) {
          final active = items
              .where((item) => item.expense.archivedAt == null)
              .toList();
          final totalBase = active.fold<double>(
            0,
            (sum, item) => sum + item.expense.baseAmount,
          );
          final displayTotal = exchanger.convertFromTRY(totalBase, currency);
          final categoryTotals = <String, double>{};
          for (final item in active) {
            final category = item.expense.category?.trim();
            if (category == null || category.isEmpty) continue;
            categoryTotals[category] =
                (categoryTotals[category] ?? 0) + item.expense.baseAmount;
          }
          final topCategory = categoryTotals.entries.isEmpty
              ? tr(ref, 'category_other')
              : (categoryTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .first
                    .key;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: _SummaryCard(
                  groupName: widget.groupName,
                  expenseCount: active.length,
                  total: AppFormat.amountWithSymbol(displayTotal, currency),
                  topCategory: categoryLabel(ref, topCategory),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr(ref, 'pro_trip_privacy_note'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(tr(ref, 'pro_trip_share')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Summary is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Summary encoding failed');
      final filename =
          'Splixa_Trip_${DateTime.now().millisecondsSinceEpoch}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
        ),
      );
      await ref
          .read(analyticsServiceProvider)
          .proFeatureCompleted(feature: ProFeature.tripSummary.analyticsValue);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.groupName,
    required this.expenseCount,
    required this.total,
    required this.topCategory,
  });
  final String groupName;
  final int expenseCount;
  final String total;
  final String topCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7490), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            _brandName,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            total,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _Metric(icon: Icons.receipt_long_rounded, value: '$expenseCount'),
              const SizedBox(width: 18),
              Expanded(
                child: _Metric(
                  icon: Icons.local_offer_outlined,
                  value: topCategory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
