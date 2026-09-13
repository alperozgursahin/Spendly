import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_strings.dart';

/// Content-shaped loading placeholders used while remote data is resolving.
///
/// A single shimmer drives the complete placeholder tree, keeping the number
/// of tickers low. The animation automatically becomes static when the device
/// requests reduced motion or accessible navigation.
enum SplixaSkeletonType {
  compact,
  list,
  cards,
  dashboard,
  profile,
  chat,
  paywall,
}

class SplixaSkeletonView extends ConsumerStatefulWidget {
  const SplixaSkeletonView({
    super.key,
    this.type = SplixaSkeletonType.list,
    this.itemCount = 3,
    this.padding = EdgeInsets.zero,
  });

  final SplixaSkeletonType type;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<SplixaSkeletonView> createState() => _SplixaSkeletonViewState();
}

class _SplixaSkeletonViewState extends ConsumerState<SplixaSkeletonView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final shouldAnimate =
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false);
    if (shouldAnimate == _motionEnabled) return;
    _motionEnabled = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF263449) : const Color(0xFFE7ECF2);
    final highlight = isDark
        ? const Color(0xFF3A4A61)
        : const Color(0xFFF8FAFC);
    final placeholder = _SkeletonLayout(
      type: widget.type,
      itemCount: widget.itemCount,
      color: base,
    );

    return Semantics(
      label: tr(ref, 'common_loading'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: widget.padding,
          child: _motionEnabled
              ? AnimatedBuilder(
                  animation: _controller,
                  child: placeholder,
                  builder: (context, child) => ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      final travel = bounds.width * 2;
                      final left = -bounds.width + travel * _controller.value;
                      return LinearGradient(
                        colors: [base, highlight, base],
                        stops: const [0.28, 0.5, 0.72],
                      ).createShader(
                        Rect.fromLTWH(
                          left,
                          bounds.top,
                          bounds.width * 1.35,
                          bounds.height,
                        ),
                      );
                    },
                    child: child,
                  ),
                )
              : placeholder,
        ),
      ),
    );
  }
}

class SplixaErrorState extends ConsumerWidget {
  const SplixaErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: compact ? 28 : 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(tr(ref, 'common_retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLayout extends StatelessWidget {
  const _SkeletonLayout({
    required this.type,
    required this.itemCount,
    required this.color,
  });

  final SplixaSkeletonType type;
  final int itemCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      SplixaSkeletonType.compact => _rows(1, compact: true),
      SplixaSkeletonType.list => _rows(itemCount),
      SplixaSkeletonType.cards => _cards(itemCount),
      SplixaSkeletonType.dashboard => _dashboard(),
      SplixaSkeletonType.profile => _profile(),
      SplixaSkeletonType.chat => _chat(itemCount),
      SplixaSkeletonType.paywall => _plans(),
    };
  }

  Widget _rows(int count, {bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 14),
          child: Row(
            children: [
              _box(compact ? 38 : 46, compact ? 38 : 46, radius: 99),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? .64 : .78,
                      child: _box(double.infinity, 13),
                    ),
                    const SizedBox(height: 9),
                    FractionallySizedBox(
                      widthFactor: index.isEven ? .42 : .55,
                      child: _box(double.infinity, 10),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[const SizedBox(width: 14), _box(42, 12)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cards(int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(18),
            ),
            child: _rows(1),
          ),
        ),
      ),
    );
  }

  Widget _dashboard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(double.infinity, 132, radius: 22),
        const SizedBox(height: 22),
        FractionallySizedBox(
          widthFactor: .48,
          alignment: AlignmentDirectional.centerStart,
          child: _box(double.infinity, 18),
        ),
        const SizedBox(height: 14),
        _rows(3),
      ],
    );
  }

  Widget _profile() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(88, 88, radius: 99),
        const SizedBox(height: 14),
        _box(146, 18),
        const SizedBox(height: 8),
        _box(104, 12),
        const SizedBox(height: 26),
        _cards(3),
      ],
    );
  }

  Widget _chat(int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        count,
        (index) => Align(
          alignment: index.isEven
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _box(index.isEven ? 210 : 168, index.isEven ? 54 : 44),
          ),
        ),
      ),
    );
  }

  Widget _plans() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(128, 18),
        const SizedBox(height: 12),
        _box(double.infinity, 78, radius: 18),
        const SizedBox(height: 10),
        _box(double.infinity, 78, radius: 18),
        const SizedBox(height: 10),
        _box(double.infinity, 78, radius: 18),
      ],
    );
  }

  Widget _box(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
