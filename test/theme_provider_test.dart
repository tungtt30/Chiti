import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/core/theme/sakura_theme.dart';
import 'package:chiti/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('themeProvider', () {
    test('defaults to system', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier).setMode(AppThemeMode.system);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.system);
    });

    test('persists and restores the chosen theme', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'sakura'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.sakura);
    });

    test('setMode updates and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier).setMode(AppThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');
    });
  });

  group('petalsEnabledProvider', () {
    test('defaults to disabled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(petalsEnabledProvider), isFalse);
    });

    test('toggle persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(petalsEnabledProvider.notifier).setEnabled(true);
      expect(container.read(petalsEnabledProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_petals_enabled'), isTrue);
    });
  });

  group('SakuraTheme', () {
    test('palette values match the design spec', () {
      expect(SakuraTheme.primaryPink, const Color(0xFFF06292));
      expect(SakuraTheme.primaryContainer, const Color(0xFFFFD8E4));
      expect(SakuraTheme.softBackground, const Color(0xFFFFF5F7));
      expect(SakuraTheme.surfaceCard, const Color(0xFFFFFFFF));
      expect(SakuraTheme.petalPink, const Color(0xFFFFB7C5));
      expect(SakuraTheme.textDark, const Color(0xFF3E2723));
      expect(SakuraTheme.accentRose, const Color(0xFFD81B60));
    });

    test('themeData is Material 3 light with the soft background', () {
      final theme = SakuraTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      // Scaffolds are transparent so the app-wide PetalField layer (which
      // paints softBackground itself) shows through behind all content.
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
      expect(theme.colorScheme.primary, SakuraTheme.accentRose);
      expect(theme.colorScheme.onSurface, SakuraTheme.textDark);
    });

    test('cards use the white card with rose shadow', () {
      final theme = SakuraTheme.themeData;
      expect(theme.cardTheme.color, SakuraTheme.surfaceCard);
      expect(theme.cardTheme.elevation, 1);
      expect(theme.cardTheme.shadowColor, const Color(0x1AF06292));
    });
  });
}