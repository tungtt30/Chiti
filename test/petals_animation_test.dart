import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/presentation/widgets/petals_animation.dart';

void main() {
  testWidgets('PetalField renders without exceptions when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [Positioned.fill(child: PetalField(enabled: true))],
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
  });

  testWidgets('PetalField renders nothing when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PetalField(enabled: false)),
      ),
    );

    // No exceptions; the disabled field builds no pointer-ignoring overlay
    // and no custom painter of its own.
    expect(tester.takeException(), isNull);
    expect(find.byType(PetalField), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PetalField),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}