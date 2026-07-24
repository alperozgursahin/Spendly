import 'package:flutter/material.dart';

abstract final class SplixaColors {
  static const cyan = Color(0xFF0E7490);
  static const cyanBright = Color(0xFF22D3EE);
  static const cyanSoft = Color(0xFFCFFAFE);
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const canvas = Color(0xFFF8FAFC);
}

abstract final class SplixaSpace {
  static const page = 20.0;
  static const card = 20.0;
  static const radius = 20.0;
  static const buttonRadius = 16.0;
}

class SplixaLogo extends StatelessWidget {
  const SplixaLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 44.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          child: Image.asset(
            'assets/images/splixa_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
              ),
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 21 : 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Splixa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class SplixaCard extends StatelessWidget {
  const SplixaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SplixaSpace.card),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(SplixaSpace.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? (isDark ? SplixaColors.slate800 : Colors.white),
        borderRadius: borderRadius,
        border: Border.all(
          color: isDark ? SplixaColors.slate700 : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SplixaPrimaryButton extends StatelessWidget {
  const SplixaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
