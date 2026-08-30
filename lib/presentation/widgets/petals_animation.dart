import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/sakura_theme.dart';

/// A lightweight falling cherry-blossom petal background.
///
/// Pure [CustomPainter] driven by a single repeating [AnimationController].
/// Wrapped in [IgnorePointer] so all gestures, taps and scrolling pass through.
/// The painter draws only a handful of petals (sized to the screen), each
/// drifting down with a sinusoidal sway and slow rotation — cheap enough for
/// 60fps on both Android and iOS.
class PetalField extends StatefulWidget {
  final bool enabled;

  const PetalField({super.key, this.enabled = true});

  @override
  State<PetalField> createState() => _PetalFieldState();
}

class _PetalFieldState extends State<PetalField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Petal> _petals;
  int _petalCount = 20;

  @override
  void initState() {
    super.initState();
    _petals = List.generate(_petalCount, (_) => _Petal.random());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is an inherited widget — only safe to read here / in build.
    final width = MediaQuery.sizeOf(context).width;
    final count = (width / 40).round().clamp(10, 40);
    if (count != _petalCount) {
      _petalCount = count;
      _petals
        ..clear()
        ..addAll(List.generate(_petalCount, (_) => _Petal.random()));
    }
  }

  @override
  void didUpdateWidget(PetalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Paints the pastel backdrop itself — this widget doubles as the Sakura
    // screen background (Scaffolds are transparent in that theme), so it must
    // render the soft pink even when the petals are disabled.
    return ColoredBox(
      color: SakuraTheme.softBackground,
      child: widget.enabled
          ? IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _PetalPainter(
                      progress: _controller.value,
                      petals: _petals,
                      seed: _seed,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  final double _seed = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
}

class _Petal {
  final double x; // 0..1 horizontal start
  final double speed; // petals per second (fraction of height)
  final double phase; // sway phase offset
  final double sway; // sway amplitude (fraction of width)
  final double size; // petal radius
  final double opacity;
  final double rotSpeed; // radians per second

  _Petal.random()
    : x = _rng(),
      speed = 0.02 + _rng() * 0.04,
      phase = _rng() * 2 * math.pi,
      sway = 0.02 + _rng() * 0.04,
      size = 4 + _rng() * 7,
      opacity = 0.5 + _rng() * 0.5,
      rotSpeed = (0.5 + _rng()) * (_rng() < 0.5 ? -1 : 1);

  static double _rng() => math.Random().nextDouble();
}

class _PetalPainter extends CustomPainter {
  final double progress; // 0..1 (one full loop)
  final List<_Petal> petals;
  final double seed;

  _PetalPainter({
    required this.progress,
    required this.petals,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = progress * 40.0; // seconds into the loop
    final t = now + seed * 40.0;

    for (final p in petals) {
      final y = ((p.speed * t + p.yOffset(seed)) % 1.1) * size.height - 20;
      final swayOffset =
          math.sin(t * 1.2 + p.phase) * p.sway * size.width +
          (t * 0.004 * p.sway * size.width);
      final cx = p.x * size.width + swayOffset;
      // Fade in/out at the very top/bottom edges for a softer loop.
      final alpha =
          p.opacity * _edgeFade(y, size.height);

      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(math.sin(t * 0.9 + p.phase) * 0.6 + t * p.rotSpeed * 0.05);
      _drawPetal(canvas, p.size, alpha);
      canvas.restore();
    }
  }

  double _edgeFade(double y, double height) {
    const fade = 40.0;
    if (y < fade) return y / fade;
    if (y > height - fade) return (height - y) / fade;
    return 1.0;
  }

  /// Five-petal cherry blossom drawn with overlapping circles around a center.
  void _drawPetal(Canvas canvas, double r, double opacity) {
    final paint = Paint()
      ..color = SakuraTheme.petalPink.withValues(alpha: opacity);
    final center = Offset.zero;
    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      final petalCenter = center + Offset(math.cos(angle), math.sin(angle)) * (r * 0.55);
      canvas.drawCircle(petalCenter, r * 0.62, paint);
    }
    canvas.drawCircle(center, r * 0.5, paint);
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

extension on _Petal {
  /// Deterministic vertical offset so petals are spread over the screen at
  /// t=0 instead of all starting at the top.
  double yOffset(double seed) => (x * 0.7 + seed * 0.3) % 1.0;
}