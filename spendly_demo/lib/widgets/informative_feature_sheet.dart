import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import '../core/splixa_design.dart';

class InformativeFeatureSheet extends StatelessWidget {
  const InformativeFeatureSheet({
    super.key,
    required this.title,
    required this.description,
    required this.content,
    this.closeLabel = 'Close',
  });

  final String title;
  final String description;
  final Widget content;
  final String closeLabel;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String description,
    required Widget content,
    String closeLabel = 'Close',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InformativeFeatureSheet(
        title: title,
        description: description,
        closeLabel: closeLabel,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SplixaSpace.page,
        12,
        SplixaSpace.page,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? SplixaColors.slate900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? const Border(top: BorderSide(color: SplixaColors.slate700))
            : null,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            content,
            const SizedBox(height: 32),
            SplixaPrimaryButton(
              label: closeLabel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentFlowExample extends ConsumerWidget {
  const PaymentFlowExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personA = tr(ref, 'minimize_person_a');
    final personB = tr(ref, 'minimize_person_b');
    final personC = tr(ref, 'minimize_person_c');
    return Column(
      children: [
        _FlowSection(
          title: tr(ref, 'minimize_without_title'),
          description: tr(ref, 'minimize_without_description'),
          people: [personA, personB, personC],
          paymentLabel: tr(ref, 'minimize_pays_100'),
          savingsLabel: tr(ref, 'minimize_one_fewer'),
          optimized: false,
        ),
        const SizedBox(height: 16),
        _FlowSection(
          title: tr(ref, 'minimize_with_title'),
          description: tr(ref, 'minimize_with_description'),
          people: [personA, personC],
          paymentLabel: tr(ref, 'minimize_pays_100'),
          savingsLabel: tr(ref, 'minimize_one_fewer'),
          optimized: true,
        ),
      ],
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection({
    required this.title,
    required this.description,
    required this.people,
    required this.paymentLabel,
    required this.savingsLabel,
    required this.optimized,
  });

  final String title;
  final String description;
  final List<String> people;
  final String paymentLabel;
  final String savingsLabel;
  final bool optimized;

  @override
  Widget build(BuildContext context) {
    final accent = optimized
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return SplixaCard(
      color: optimized
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .28)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  optimized
                      ? Icons.auto_awesome_rounded
                      : Icons.sync_alt_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  for (var index = 0; index < people.length; index++) ...[
                    _PersonNode(name: people[index], highlighted: optimized),
                    if (index != people.length - 1)
                      _PaymentArrow(color: accent, label: paymentLabel),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (optimized) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
                const SizedBox(width: 7),
                Text(
                  savingsLabel,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonNode extends StatelessWidget {
  const _PersonNode({required this.name, required this.highlighted});

  final String name;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: highlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_rounded,
              color: highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _PaymentArrow extends StatelessWidget {
  const _PaymentArrow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: color, size: 28),
        ],
      ),
    );
  }
}
