import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/splixa_design.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: SplixaLogo()),
              const SizedBox(height: 28),
              const Expanded(child: _SharingIllustration()),
              const SizedBox(height: 32),
              Text(
                'Effortless Expense Sharing',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Split group costs, settle up clearly, and keep your personal budget on track—all in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SplixaPrimaryButton(
                label: 'Sign In / Sign Up',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharingIllustration extends StatelessWidget {
  const _SharingIllustration();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 410),
        decoration: BoxDecoration(
          color: isDark ? SplixaColors.slate800 : SplixaColors.cyanSoft,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: 28,
              top: 34,
              child: _bubble(context, Icons.receipt_long_rounded, 62),
            ),
            Positioned(
              left: 26,
              bottom: 38,
              child: _bubble(context, Icons.pie_chart_rounded, 68),
            ),
            Container(
              width: 156,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? SplixaColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(color: Color(0x180E7490), blurRadius: 30),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: SplixaColors.cyan,
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: SplixaColors.cyanBright,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 9),
                  FractionallySizedBox(
                    widthFactor: .65,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: SplixaColors.slate500.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(BuildContext context, IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: SplixaColors.cyanBright.withValues(alpha: .5),
        ),
      ),
      child: Icon(icon, color: SplixaColors.cyan),
    );
  }
}
