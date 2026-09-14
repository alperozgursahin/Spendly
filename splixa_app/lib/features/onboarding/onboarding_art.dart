/// Hand-built vector scenes for the onboarding slides.
///
/// These replace four ~3 KB Lottie files that contained, between them, a circle
/// orbiting a tick — placeholder geometry standing in for artwork that was never
/// made. The style here is deliberately *object* illustration rather than
/// character illustration: cards, receipts, coins, badges. Characters drawn in
/// code look like characters drawn in code; objects built from rounded
/// rectangles, discs and arcs are what vector tooling would produce anyway, so
/// they hold up.
///
/// Every scene is authored against a fixed 300x220 design canvas and scaled by
/// the caller with a [FittedBox], so proportions never depend on screen size.
/// Colour comes from the slide's accent plus the theme's surface, so each scene
/// is one hue against paper and dark mode is a real variant rather than an
/// inversion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

const Size kOnboardingArtCanvas = Size(300, 220);

/// Slow vertical drift applied to the whole scene, plus a counter-drift on the
/// decorative layer, so the composition breathes instead of sitting still.
/// A single controller drives everything: independent tweens on each element
/// would beat against each other and read as jitter.
class OnboardingArt extends StatefulWidget {
  const OnboardingArt({
    super.key,
    required this.scene,
    required this.accent,
    required this.reduceMotion,
  });

  final OnboardingScene scene;
  final Color accent;
  final bool reduceMotion;

  @override
  State<OnboardingArt> createState() => _OnboardingArtState();
}

enum OnboardingScene { personalAndShared, clearSplits, trustedCurrency, pro }

class _OnboardingArtState extends State<OnboardingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(OnboardingArt old) {
    super.didUpdateWidget(old);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // "Paper" is the surface the objects are drawn on. In dark mode it lifts
    // slightly above the panel instead of going black, so edges stay readable.
    final paper = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: .10), scheme.surface)
        : scheme.surface;
    final ink = isDark
        ? Colors.white.withValues(alpha: .82)
        : const Color(0xFF1E293B);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox.fromSize(
        size: kOnboardingArtCanvas,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = widget.reduceMotion ? 0.0 : _controller.value;
            // One full sine per cycle: the scene rises, falls and returns to
            // exactly where it started, so the loop has no visible seam.
            final drift = math.sin(t * 2 * math.pi);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _Backdrop(accent: widget.accent, drift: drift),
                Transform.translate(
                  offset: Offset(0, drift * 5),
                  child: _scene(paper, ink, drift),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scene(Color paper, Color ink, double drift) {
    switch (widget.scene) {
      case OnboardingScene.personalAndShared:
        return _PersonalAndSharedScene(
          accent: widget.accent,
          paper: paper,
          ink: ink,
          drift: drift,
        );
      case OnboardingScene.clearSplits:
        return _ClearSplitsScene(
          accent: widget.accent,
          paper: paper,
          ink: ink,
          drift: drift,
        );
      case OnboardingScene.trustedCurrency:
        return _TrustedCurrencyScene(
          accent: widget.accent,
          paper: paper,
          ink: ink,
          drift: drift,
        );
      case OnboardingScene.pro:
        return _ProScene(
          accent: widget.accent,
          paper: paper,
          ink: ink,
          drift: drift,
        );
    }
  }
}

/// Soft accent disc plus two small satellites. Gives every scene the same
/// depth cue without the scenes having to agree on anything else.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.accent, required this.drift});

  final Color accent;
  final double drift;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accent.withValues(alpha: .26),
                accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 30 - drift * 4,
          child: _Dot(color: accent, size: 10, opacity: .45),
        ),
        Positioned(
          right: 26,
          bottom: 34 + drift * 4,
          child: _Dot(color: accent, size: 7, opacity: .35),
        ),
        Positioned(
          right: 46,
          top: 22 + drift * 3,
          child: _Dot(color: accent, size: 5, opacity: .55),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

/// Shared card chrome: rounded, on paper, with one soft shadow tinted by the
/// accent rather than neutral grey, which is what stops the objects looking
/// like grey UI screenshots.
class _Card extends StatelessWidget {
  const _Card({
    required this.width,
    required this.height,
    required this.paper,
    required this.accent,
    this.padding = const EdgeInsets.all(12),
    this.child,
  });

  final double width;
  final double height;
  final Color paper;
  final Color accent;
  final EdgeInsets padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: paper,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .22),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

/// A line of "text". Illustrated copy, not real copy — real strings here would
/// need translating and would fight the slide's own title for attention.
class _Line extends StatelessWidget {
  const _Line({
    required this.width,
    required this.color,
    this.height = 6,
    this.opacity = 1,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(height),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.color,
    required this.paper,
    this.size = 26,
    this.opacity = 1,
  });

  final Color color;
  final Color paper;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      shape: BoxShape.circle,
      border: Border.all(color: paper, width: 2),
    ),
    child: Icon(Icons.person_rounded, size: size * .58, color: paper),
  );
}

// ---------------------------------------------------------------------------
// Scene 1 — one ledger, two lives: a personal balance card with a shared group
// card peeling off it.
// ---------------------------------------------------------------------------

class _PersonalAndSharedScene extends StatelessWidget {
  const _PersonalAndSharedScene({
    required this.accent,
    required this.paper,
    required this.ink,
    required this.drift,
  });

  final Color accent;
  final Color paper;
  final Color ink;
  final double drift;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kOnboardingArtCanvas,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Back card, rotated and dimmed: the "other" ledger, present but not
          // competing with the one in focus.
          Positioned(
            left: 42,
            top: 44,
            child: Transform.rotate(
              angle: -0.14,
              child: _Card(
                width: 118,
                height: 116,
                paper: paper,
                accent: accent,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Avatar(
                          color: accent,
                          paper: paper,
                          size: 20,
                          opacity: .55,
                        ),
                        Transform.translate(
                          offset: const Offset(-7, 0),
                          child: _Avatar(
                            color: accent,
                            paper: paper,
                            size: 20,
                            opacity: .35,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _Line(width: 58, color: ink, opacity: .22),
                    const SizedBox(height: 7),
                    _Line(width: 40, color: ink, opacity: .14),
                  ],
                ),
              ),
            ),
          ),
          // Front card: the balance the slide is about.
          Positioned(
            right: 36,
            bottom: 34 - drift * 3,
            child: _Card(
              width: 136,
              height: 132,
              paper: paper,
              accent: accent,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(width: 44, color: ink, opacity: .3, height: 5),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: paper,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Line(width: 52, color: ink, opacity: .75, height: 10),
                    ],
                  ),
                  const Spacer(),
                  // Two ledger rows, one in accent to read as "settled".
                  Row(
                    children: [
                      _Dot(color: accent, size: 6, opacity: 1),
                      const SizedBox(width: 6),
                      _Line(width: 40, color: ink, opacity: .28, height: 5),
                      const Spacer(),
                      _Line(width: 18, color: accent, opacity: .9, height: 5),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _Dot(color: ink, size: 6, opacity: .2),
                      const SizedBox(width: 6),
                      _Line(width: 32, color: ink, opacity: .2, height: 5),
                      const Spacer(),
                      _Line(width: 14, color: ink, opacity: .2, height: 5),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scene 2 — a receipt with a torn edge, splitting into equal shares.
// ---------------------------------------------------------------------------

class _ClearSplitsScene extends StatelessWidget {
  const _ClearSplitsScene({
    required this.accent,
    required this.paper,
    required this.ink,
    required this.drift,
  });

  final Color accent;
  final Color paper;
  final Color ink;
  final double drift;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kOnboardingArtCanvas,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 16,
            child: CustomPaint(
              size: const Size(112, 136),
              painter: _ReceiptPainter(paper: paper, accent: accent, ink: ink),
            ),
          ),
          // The divide badge sits on the tear, where the single bill becomes
          // several — the one moment the whole product is about.
          Positioned(
            top: 128 + drift * 2,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.call_split_rounded, size: 20, color: paper),
            ),
          ),
          // Three equal shares fanned below.
          Positioned(
            bottom: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final lift = math.sin((drift * math.pi) + index) * 3;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Transform.translate(
                    offset: Offset(0, lift),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Avatar(
                          color: accent,
                          paper: paper,
                          size: 26,
                          opacity: 1 - index * .18,
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 34,
                          height: 14,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: _Line(
                              width: 16,
                              color: accent,
                              height: 4,
                              opacity: .9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt body with a zigzag bottom edge and printed lines. A path rather than
/// stacked widgets because the tear has to be a single continuous silhouette
/// for the shadow to follow it.
class _ReceiptPainter extends CustomPainter {
  _ReceiptPainter({
    required this.paper,
    required this.accent,
    required this.ink,
  });

  final Color paper;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 12.0;
    const teeth = 7;
    const toothHeight = 9.0;
    final tearTop = size.height - toothHeight;
    final toothWidth = size.width / teeth;

    final path = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, tearTop);
    for (var i = teeth - 1; i >= 0; i--) {
      path
        ..lineTo(toothWidth * i + toothWidth / 2, size.height)
        ..lineTo(toothWidth * i, tearTop);
    }
    path.close();

    canvas.drawShadow(path, accent.withValues(alpha: .7), 8, false);
    canvas.drawPath(path, Paint()..color = paper);

    // Printed content: a header block in accent, then fading line pairs.
    final header = Paint()..color = accent.withValues(alpha: .18);
    canvas.drawRRect(
      RRect.fromLTRBR(14, 16, 58, 26, const Radius.circular(5)),
      header,
    );
    final line = Paint();
    for (var i = 0; i < 4; i++) {
      final y = 42.0 + i * 16;
      line.color = ink.withValues(alpha: .18 - i * .03);
      canvas.drawRRect(
        RRect.fromLTRBR(
          14,
          y,
          14 + 54 - i * 6,
          y + 6,
          const Radius.circular(3),
        ),
        line,
      );
      line.color = ink.withValues(alpha: .12);
      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width - 34,
          y,
          size.width - 14,
          y + 6,
          const Radius.circular(3),
        ),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_ReceiptPainter old) =>
      old.paper != paper || old.accent != accent || old.ink != ink;
}

// ---------------------------------------------------------------------------
// Scene 3 — two currencies, one locked rate.
// ---------------------------------------------------------------------------

class _TrustedCurrencyScene extends StatelessWidget {
  const _TrustedCurrencyScene({
    required this.accent,
    required this.paper,
    required this.ink,
    required this.drift,
  });

  final Color accent;
  final Color paper;
  final Color ink;
  final double drift;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kOnboardingArtCanvas,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(220, 120),
            painter: _ConversionArcPainter(accent: accent),
          ),
          Positioned(
            left: 42,
            top: 68 + drift * 4,
            child: _Coin(
              glyph: '₺',
              accent: accent,
              paper: paper,
              ink: ink,
              filled: true,
            ),
          ),
          Positioned(
            right: 42,
            top: 68 - drift * 4,
            child: _Coin(
              glyph: '\$',
              accent: accent,
              paper: paper,
              ink: ink,
              filled: false,
            ),
          ),
          // The lock is the point of the slide: the rate is pinned at the moment
          // of the expense, not recalculated later.
          Positioned(
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .24),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: accent),
                  const SizedBox(width: 7),
                  _Line(width: 40, color: ink, opacity: .3, height: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({
    required this.glyph,
    required this.accent,
    required this.paper,
    required this.ink,
    required this.filled,
  });

  final String glyph;
  final Color accent;
  final Color paper;
  final Color ink;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: filled ? accent : paper,
      shape: BoxShape.circle,
      border: filled
          ? null
          : Border.all(color: accent.withValues(alpha: .45), width: 2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Text(
      glyph,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: filled ? paper : accent,
      ),
    ),
  );
}

/// Dashed arc with an arrowhead, arcing over the two coins.
class _ConversionArcPainter extends CustomPainter {
  _ConversionArcPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: .55);

    final path = Path()
      ..moveTo(size.width * .22, size.height * .78)
      ..cubicTo(
        size.width * .3,
        size.height * .14,
        size.width * .7,
        size.height * .14,
        size.width * .78,
        size.height * .78,
      );

    // Dashes are measured along the path so they stay evenly spaced around the
    // curve; a repeating gradient or a dotted border cannot follow an arc.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 9, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 7;
      }
    }

    final tip = Offset(size.width * .78, size.height * .78);
    final arrow = Path()
      ..moveTo(tip.dx - 7, tip.dy - 9)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 8, tip.dy - 6);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_ConversionArcPainter old) => old.accent != accent;
}

// ---------------------------------------------------------------------------
// Scene 4 — Pro: one card, the features orbiting it.
// ---------------------------------------------------------------------------

class _ProScene extends StatelessWidget {
  const _ProScene({
    required this.accent,
    required this.paper,
    required this.ink,
    required this.drift,
  });

  final Color accent;
  final Color paper;
  final Color ink;
  final double drift;

  static const _orbit = <IconData>[
    Icons.insights_rounded,
    Icons.document_scanner_rounded,
    Icons.autorenew_rounded,
    Icons.lock_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kOnboardingArtCanvas,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Feature pills placed on an ellipse rather than a circle: the canvas
          // is wider than it is tall, and a true circle would crowd the top and
          // bottom while leaving the sides empty.
          for (var i = 0; i < _orbit.length; i++)
            Builder(
              builder: (context) {
                final angle =
                    (i / _orbit.length) * 2 * math.pi + drift * .12 - .4;
                return Transform.translate(
                  offset: Offset(math.cos(angle) * 108, math.sin(angle) * 74),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .20),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(_orbit[i], size: 19, color: accent),
                  ),
                );
              },
            ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, Color.lerp(accent, Colors.black, .30)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .45),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 40, color: paper),
                const SizedBox(height: 10),
                _Line(width: 46, color: paper, opacity: .9, height: 6),
                const SizedBox(height: 6),
                _Line(width: 30, color: paper, opacity: .55, height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
