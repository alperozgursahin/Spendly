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
import '../auth/auth_provider.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import '../subscriptions/pro_access.dart';
import '../subscriptions/premium_provider.dart';
import 'financial_models.dart';
import 'group_model.dart';
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
          final members = ref
              .watch(groupMembersProvider(widget.groupId))
              .valueOrNull;
          final balances = ref
              .watch(groupBalancesProvider(widget.groupId))
              .valueOrNull;
          final nameFor = _nameResolver(ref, members);

          // Sorted newest first so the five that fit on the card are the five
          // people actually remember paying for.
          final recent = [...active]
            ..sort(
              (a, b) => b.expense.expenseDate.compareTo(a.expense.expenseDate),
            );

          final transfers = _simplifyDebts(balances ?? const []);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: _SummaryCard(
                  groupName: widget.groupName,
                  total: AppFormat.amountWithSymbol(
                    exchanger.convertFromTRY(totalBase, currency),
                    currency,
                  ),
                  expenseCount: active.length,
                  memberCount: members?.length ?? 0,
                  settledUpLabel: tr(ref, 'trip_summary_settled_up'),
                  owesTitle: tr(ref, 'trip_summary_who_owes'),
                  expensesTitle: tr(ref, 'trip_summary_expenses_title'),
                  peopleLabel: trp(ref, 'trip_summary_people', {
                    'count': '${members?.length ?? 0}',
                  }),
                  expensesLabel: trp(ref, 'trip_summary_expenses_count', {
                    'count': '${active.length}',
                  }),
                  moreLabel: (n) =>
                      trp(ref, 'trip_summary_more', {'count': '$n'}),
                  transfers: transfers
                      .map(
                        (t) => _TransferRow(
                          from: nameFor(t.fromUserId),
                          to: nameFor(t.toUserId),
                          amount: AppFormat.amountWithSymbol(
                            exchanger.convertFromTRY(t.amount, currency),
                            currency,
                          ),
                        ),
                      )
                      .toList(),
                  lines: recent
                      .map(
                        (item) => _ExpenseLine(
                          payer: nameFor(item.expense.payerId),
                          category: categoryLabel(
                            ref,
                            (item.expense.category?.trim().isEmpty ?? true)
                                ? 'Diğer'
                                : item.expense.category!.trim(),
                          ),
                          description: item.expense.description,
                          amount: AppFormat.amountWithSymbol(
                            exchanger.convertFromTRY(
                              item.expense.baseAmount,
                              currency,
                            ),
                            currency,
                          ),
                        ),
                      )
                      .toList(),
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

  /// Display name for a member id, falling back to the shortened id so a row
  /// never renders blank for someone who has left the group.
  String Function(String) _nameResolver(
    WidgetRef ref,
    List<GroupMemberModel>? members,
  ) {
    final byId = {
      for (final m in members ?? const <GroupMemberModel>[])
        m.userId: (m.username?.trim().isNotEmpty ?? false)
            ? m.username!.trim()
            : null,
    };
    final me = ref.watch(currentUserIdProvider);
    return (String id) {
      if (id == me) return tr(ref, 'common_you');
      return byId[id] ?? '@${id.substring(0, 6)}';
    };
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

/// One "A pays B" instruction.
class _Transfer {
  const _Transfer(this.fromUserId, this.toUserId, this.amount);
  final String fromUserId;
  final String toUserId;
  final double amount;
}

/// Turns per-person balances into the fewest payments that clear them.
///
/// Repeatedly matches the largest debtor against the largest creditor. That
/// does not always find the theoretical minimum -- doing so is NP-hard -- but
/// it never produces more than n-1 payments and it is what people expect:
/// nobody wants a summary that tells five friends to make eleven transfers.
/// Amounts under a cent are treated as settled so floating-point dust does not
/// invent a 0.00 payment.
List<_Transfer> _simplifyDebts(List<GroupBalance> balances) {
  final debtors = <MapEntry<String, double>>[];
  final creditors = <MapEntry<String, double>>[];
  for (final balance in balances) {
    if (balance.balance < -0.01) {
      debtors.add(MapEntry(balance.userId, -balance.balance));
    } else if (balance.balance > 0.01) {
      creditors.add(MapEntry(balance.userId, balance.balance));
    }
  }
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <_Transfer>[];
  var i = 0;
  var j = 0;
  var owed = debtors.isEmpty ? 0.0 : debtors.first.value;
  var due = creditors.isEmpty ? 0.0 : creditors.first.value;
  while (i < debtors.length && j < creditors.length) {
    final amount = owed < due ? owed : due;
    if (amount > 0.01) {
      transfers.add(_Transfer(debtors[i].key, creditors[j].key, amount));
    }
    owed -= amount;
    due -= amount;
    if (owed <= 0.01) {
      i++;
      if (i < debtors.length) owed = debtors[i].value;
    }
    if (due <= 0.01) {
      j++;
      if (j < creditors.length) due = creditors[j].value;
    }
  }
  return transfers;
}

class _TransferRow {
  const _TransferRow({
    required this.from,
    required this.to,
    required this.amount,
  });
  final String from;
  final String to;
  final String amount;
}

class _ExpenseLine {
  const _ExpenseLine({
    required this.payer,
    required this.category,
    required this.description,
    required this.amount,
  });
  final String payer;
  final String category;
  final String description;
  final String amount;
}

/// The shareable card.
///
/// It has one job: land in a group chat and answer "are we done?" without
/// anyone opening the app. So the settle-up state comes before the expense
/// list, and when there is nothing left to pay the card says so outright
/// instead of leaving people to infer it from a total.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.groupName,
    required this.total,
    required this.expenseCount,
    required this.memberCount,
    required this.settledUpLabel,
    required this.owesTitle,
    required this.expensesTitle,
    required this.peopleLabel,
    required this.expensesLabel,
    required this.moreLabel,
    required this.transfers,
    required this.lines,
  });

  final String groupName;
  final String total;
  final int expenseCount;
  final int memberCount;
  final String settledUpLabel;
  final String owesTitle;
  final String expensesTitle;
  final String peopleLabel;
  final String expensesLabel;
  final String Function(int) moreLabel;
  final List<_TransferRow> transfers;
  final List<_ExpenseLine> lines;

  /// Five is what fits before the card stops being glanceable in a chat.
  static const _maxLines = 5;

  @override
  Widget build(BuildContext context) {
    final shown = lines.take(_maxLines).toList();
    final remaining = lines.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              const Text(
                _brandName,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                AppFormat.shortDate(DateTime.now()),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            groupName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$expensesLabel · $peopleLabel',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (transfers.isEmpty)
            _Panel(
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF6EE7B7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settledUpLabel,
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(owesTitle),
                  const SizedBox(height: 8),
                  ...transfers.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: t.from),
                                  const TextSpan(
                                    text: '  →  ',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                  TextSpan(text: t.to),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t.amount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(expensesTitle),
                  const SizedBox(height: 8),
                  ...shown.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.description.trim().isEmpty
                                      ? line.category
                                      : line.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${line.payer} · ${line.category}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            line.amount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (remaining > 0)
                    Text(
                      moreLabel(remaining),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Frosted inner block. Keeps the sections legible on the gradient without
/// introducing a second background colour to keep in sync.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}
