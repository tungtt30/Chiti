import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/main.dart';

void main() {
  testWidgets('Settings screen switches app language to Vietnamese and back',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('My Groups'), findsOneWidget);

    // Open Settings from the dashboard app bar.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    // Switch to Vietnamese: the Settings screen itself re-renders instantly.
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);

    // Persisted choice is only read after the new locale load.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'vi');

    // Back on the dashboard, the title is localized.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Nhóm của tôi'), findsOneWidget);

    // Switch back to English.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(prefs.getString('app_locale'), 'en');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('My Groups'), findsOneWidget);

    // System default clears the saved language.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(prefs.containsKey('app_locale'), isFalse);
  });
}