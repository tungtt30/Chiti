import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/autumn_theme.dart';
import '../theme/spring_theme.dart';
import '../theme/winter_theme.dart';

/// The kind of falling particle a [SeasonalBackgroundWrapper] renders.
enum ParticleType { springPetal, autumnLeaf, winterSnow }

/// A single falling particle (petal, leaf or snowflake).
///
/// Position is stored as a fraction of the canvas (x in 0..1, y in 0..1.1)
/// so the same field adapts to any screen size. [tick] advances the particle
/// with simple, cheap physics: a constant fall speed, a sinusoidal sway and
/// continuous tumbling rotation.
class SeasonalParticle {
  double x;
  double y;
  double size;
  double speed;
  double swaySpeed;
  double swayAmplitude;
  double rotation;
  double rotationSpeed;
  double opacity;

  final double _baseX;
  double _phase;

  SeasonalParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swaySpeed,
    required this.swayAmplitude,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
  }) : _baseX = x,
       _phase = x * 2 * math.pi;

  /// Randomly parametrized particle for the given [type].
  factory SeasonalParticle.random(ParticleType type, math.Random rng) {
    switch (type) {
      case ParticleType.springPetal:
        return SeasonalParticle(
          x: rng.nextDouble(),
          y: rng.nextDouble() * 1.1 - 0.1,
          size: 4 + rng.nextDouble() * 7,
          speed: 0.02 + rng.nextDouble() * 0.04,
          swaySpeed: 0.8 + rng.nextDouble() * 0.8,
          swayAmplitude: 0.02 + rng.nextDouble() * 0.04,
          rotation: rng.nextDouble() * 2 * math.pi,
          rotationSpeed: (0.5 + rng.nextDouble()) * (rng.nextBool() ? 1 : -1),
          opacity: 0.5 + rng.nextDouble() * 0.5,
        );
      case ParticleType.autumnLeaf:
        return SeasonalParticle(
          x: rng.nextDouble(),
          y: rng.nextDouble() * 1.1 - 0.1,
          size: 6 + rng.nextDouble() * 8,
          speed: 0.018 + rng.nextDouble() * 0.028,
          swaySpeed: 0.6 + rng.nextDouble() * 0.7,
          swayAmplitude: 0.03 + rng.nextDouble() * 0.05,
          rotation: rng.nextDouble() * 2 * math.pi,
          rotationSpeed: (0.8 + rng.nextDouble() * 0.8) *
              (rng.nextBool() ? 1 : -1),
          opacity: 0.6 + rng.nextDouble() * 0.4,
        );
      case ParticleType.winterSnow:
        return SeasonalParticle(
          x: rng.nextDouble(),
          y: rng.nextDouble() * 1.1 - 0.1,
          size: 2 + rng.nextDouble() * 4,
          speed: 0.008 + rng.nextDouble() * 0.012,
          swaySpeed: 0.5 + rng.nextDouble() * 0.5,
          swayAmplitude: 0.015 + rng.nextDouble() * 0.03,
          rotation: rng.nextDouble() * 2 * math.pi,
          rotationSpeed: (0.2 + rng.nextDouble() * 0.4) *
              (rng.nextBool() ? 1 : -1),
          opacity: 0.35 + rng.nextDouble() * 0.55,
        );
    }
  }

  /// Advances the particle by [dt] seconds. Wraps back to the top once it
  /// falls past the bottom edge, keeping the loop seamless.
  void tick(double dt) {
    _phase += swaySpeed * dt;
    x = _baseX + math.sin(_phase) * swayAmplitude;
    y += speed * dt;
    if (y > 1.1) y = -0.15;
    rotation += rotationSpeed * dt;
  }
}

/// Unified seasonal particle background.
///
/// Renders falling petals (Spring), tumbling leaves (Autumn) or soft
/// snowflakes (Winter) behind the app. A single repeating ticker advances
/// cheap physics per frame; the painter draws only a handful of particles
/// sized to the screen, so it stays comfortably under 2% CPU at 60fps.
///
/// Wrapped in [IgnorePointer] so all gestures, taps and scrolling pass
/// through. Also paints its own themed backdrop so the seasonal themes can
/// keep transparent Scaffolds (the layer sits behind the Navigator).
class SeasonalBackgroundWrapper extends StatefulWidget {
  final ParticleType type;
  final bool enabled;
  final Color? backgroundColor;

  const SeasonalBackgroundWrapper({
    super.key,
    required this.type,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  State<SeasonalBackgroundWrapper> createState() =>
      _SeasonalBackgroundWrapperState();
}

class _SeasonalBackgroundWrapperState extends State<
    SeasonalBackgroundWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final math.Random _rng;
  late List<SeasonalParticle> _particles;
  Duration? _lastElapsed;
  int _count = 20;

  @override
  void initState() {
    super.initState();
    _rng = math.Random();
    _particles = List.generate(_count, (_) => SeasonalParticle.random(widget.type, _rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..addListener(_onTick);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is an inherited widget — only safe to read here / in build.
    final width = MediaQuery.sizeOf(context).width;
    final count = _densityFor(widget.type, width);
    if (count != _count) {
      _count = count;
      _particles = List.generate(
        _count,
        (_) => SeasonalParticle.random(widget.type, _rng),
      );
    }
  }

  @override
  void didUpdateWidget(SeasonalBackgroundWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type) {
      _particles = List.generate(
        _count,
        (_) => SeasonalParticle.random(widget.type, _rng),
      );
    }
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

  void _onTick() {
    final now = _controller.lastElapsedDuration;
    if (_lastElapsed != null && now != null) {
      // Clamp to non-negative: restarting the controller resets the elapsed
      // clock, which would otherwise produce a negative dt on the first frame.
      final dt = math.max(
        0.0,
        (now - _lastElapsed!).inMicroseconds / 1e6,
      );
      for (final p in _particles) {
        p.tick(dt);
      }
    }
    _lastElapsed = now;
    setState(() {});
  }

  /// Particle density tuned per season: fewer, slower particles for snow,
  /// denser ones for petals.
  int _densityFor(ParticleType type, double width) {
    final perWidth = switch (type) {
      ParticleType.springPetal => 40.0,
      ParticleType.autumnLeaf => 45.0,
      ParticleType.winterSnow => 55.0,
    };
    return (width / perWidth).round().clamp(8, 40);
  }

  @override
  Widget build(BuildContext context) {
    // Paints the seasonal backdrop itself — this widget doubles as the
    // theme background (Scaffolds are transparent in seasonal themes), so it
    // must render the soft color even when the particles are disabled.
    return ColoredBox(
      color: widget.backgroundColor ?? _defaultBackground(widget.type),
      child: widget.enabled
          ? IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SeasonalParticlePainter(
                    particles: _particles,
                    type: widget.type,
                    animationProgress: _controller.value,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Color _defaultBackground(ParticleType type) => switch (type) {
    ParticleType.springPetal => SpringTheme.softBackground,
    ParticleType.autumnLeaf => AutumnTheme.softBackground,
    ParticleType.winterSnow => WinterTheme.softBackground,
  };
}

/// Paints the current particle field. Particles hold their own live state
/// (advanced each frame by the wrapper's ticker), so painting is a pure
/// read of their positions.
class SeasonalParticlePainter extends CustomPainter {
  final List<SeasonalParticle> particles;
  final ParticleType type;
  final double animationProgress;

  SeasonalParticlePainter({
    required this.particles,
    required this.type,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final alpha = p.opacity * _edgeFade(p.y);
      final paint = Paint()
        ..color = _getParticleColor(p, i, alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);

      switch (type) {
        case ParticleType.springPetal:
          _drawPetal(canvas, p.size, paint);
        case ParticleType.autumnLeaf:
          _drawLeaf(canvas, p.size, paint);
        case ParticleType.winterSnow:
          _drawSnowflake(canvas, p.size, paint);
      }
      canvas.restore();
    }
  }

  /// Fades particles in/out at the very top/bottom edges for a softer loop.
  double _edgeFade(double y) {
    const fade = 0.06;
    if (y < fade) return (y / fade).clamp(0.0, 1.0);
    if (y > 1.0 - fade) return ((1.0 - y) / fade).clamp(0.0, 1.0);
    return 1.0;
  }

  Color _getParticleColor(SeasonalParticle p, int index, double alpha) {
    final base = switch (type) {
      ParticleType.springPetal => SpringTheme.petalPink,
      ParticleType.autumnLeaf =>
        AutumnTheme.leafPalette[index % AutumnTheme.leafPalette.length],
      ParticleType.winterSnow =>
        WinterTheme.snowPalette[index % WinterTheme.snowPalette.length],
    };
    return base.withValues(alpha: alpha);
  }

  /// Five-petal cherry blossom drawn with overlapping circles around a center.
  void _drawPetal(Canvas canvas, double r, Paint paint) {
    final center = Offset.zero;
    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      final petalCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * (r * 0.55);
      canvas.drawCircle(petalCenter, r * 0.62, paint);
    }
    canvas.drawCircle(center, r * 0.5, paint);
  }

  /// Smooth leaf path (gentle teardrop outline with a faint central vein).
  void _drawLeaf(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(size * 0.8, 0, 0, size);
    path.quadraticBezierTo(-size * 0.8, 0, 0, -size);
    canvas.drawPath(path, paint);

    final vein = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, size * 0.08);
    canvas.drawLine(Offset(0, -size * 0.75), Offset(0, size * 0.75), vein);
  }

  /// Soft snowflake: a crisp core circle with a faint halo for a gentle glow.
  void _drawSnowflake(Canvas canvas, double size, Paint paint) {
    final halo = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size * 0.8, halo);
    canvas.drawCircle(Offset.zero, size / 2, paint);
  }

  @override
  bool shouldRepaint(SeasonalParticlePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.particles != particles ||
      oldDelegate.animationProgress != animationProgress;
}