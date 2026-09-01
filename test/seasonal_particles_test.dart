import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/theme/autumn_theme.dart';
import 'package:chiti/core/theme/spring_theme.dart';
import 'package:chiti/core/theme/winter_theme.dart';
import 'package:chiti/core/widgets/seasonal_particles.dart';

void main() {
  testWidgets(
    'SeasonalBackgroundWrapper renders each particle type without exceptions',
    (tester) async {
      for (final type in ParticleType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SeasonalBackgroundWrapper(
                      type: type,
                      enabled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        // Ignores pointer events so the UI underneath stays interactive.
        expect(find.byType(IgnorePointer), findsWidgets);
        expect(find.byType(CustomPaint), findsWidgets);

        // Advancing frames keeps the animation ticking without errors.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('renders the themed backdrop behind the particles', (
    tester,
  ) async {
    final backgroundColors = {
      ParticleType.springPetal: SpringTheme.softBackground,
      ParticleType.autumnLeaf: AutumnTheme.softBackground,
      ParticleType.winterSnow: WinterTheme.softBackground,
    };
    for (final entry in backgroundColors.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonalBackgroundWrapper(
              type: entry.key,
              enabled: true,
            ),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == entry.value,
        ),
        findsWidgets,
      );
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('renders nothing particle-wise when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SeasonalBackgroundWrapper(
            type: ParticleType.autumnLeaf,
            enabled: false,
          ),
        ),
      ),
    );

    // No exceptions; the disabled wrapper keeps painting the themed backdrop
    // but builds no pointer-ignoring overlay and no custom painter of its own.
    expect(tester.takeException(), isNull);
    expect(find.byType(SeasonalBackgroundWrapper), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SeasonalBackgroundWrapper),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  test('SeasonalParticle.random respects per-type ranges', () {
    final rng = math.Random(42);
    for (final type in ParticleType.values) {
      final p = SeasonalParticle.random(type, rng);
      expect(p.x, inInclusiveRange(0.0, 1.0));
      expect(p.y, inInclusiveRange(-0.1, 1.0));
      expect(p.opacity, inInclusiveRange(0.0, 1.0));
      expect(p.size, greaterThan(0));
    }
  });

  test('SeasonalParticle.tick falls, sways and wraps', () {
    final rng = math.Random(1);
    final p = SeasonalParticle.random(ParticleType.springPetal, rng);
    final startY = p.y;
    p.tick(1.0);
    expect(p.y, greaterThan(startY));

    // A fast-falling particle wraps back above the screen.
    final fast = SeasonalParticle(
      x: 0.5,
      y: 1.05,
      size: 5,
      speed: 1.0,
      swaySpeed: 1.0,
      swayAmplitude: 0.0,
      rotation: 0,
      rotationSpeed: 0,
      opacity: 1,
    );
    fast.tick(1.0);
    expect(fast.y, lessThan(0));
  });
}