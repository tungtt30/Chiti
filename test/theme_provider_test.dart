import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/core/theme/autumn_theme.dart';
import 'package:chiti/core/theme/spring_theme.dart';
import 'package:chiti/core/theme/winter_theme.dart';
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
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'autumn'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.autumn);
    });

    test('legacy sakura value migrates to spring', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'sakura'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.spring);
    });

    test('setMode updates and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier).setMode(AppThemeMode.winter);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeProvider), AppThemeMode.winter);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'winter');
    });

    test('isSeasonal flags only the seasonal themes', () {
      expect(AppThemeMode.system.isSeasonal, isFalse);
      expect(AppThemeMode.light.isSeasonal, isFalse);
      expect(AppThemeMode.dark.isSeasonal, isFalse);
      expect(AppThemeMode.spring.isSeasonal, isTrue);
      expect(AppThemeMode.autumn.isSeasonal, isTrue);
      expect(AppThemeMode.winter.isSeasonal, isTrue);
    });
  });

  group('particlesEnabledProvider', () {
    test('defaults to disabled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(particlesEnabledProvider), isFalse);
    });

    test('toggle persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(particlesEnabledProvider.notifier).setEnabled(true);
      expect(container.read(particlesEnabledProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_particles_enabled'), isTrue);
    });

    test('legacy petals toggle migrates', () async {
      SharedPreferences.setMockInitialValues({'app_petals_enabled': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(particlesEnabledProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(particlesEnabledProvider), isTrue);
    });
  });

  group('SpringTheme', () {
    test('palette values match the design spec', () {
      expect(SpringTheme.primaryPink, const Color(0xFFF06292));
      expect(SpringTheme.primaryContainer, const Color(0xFFFFD8E4));
      expect(SpringTheme.softBackground, const Color(0xFFFFF5F7));
      expect(SpringTheme.surfaceCard, const Color(0xFFFFFFFF));
      expect(SpringTheme.petalPink, const Color(0xFFFFB7C5));
      expect(SpringTheme.textDark, const Color(0xFF3E2723));
      expect(SpringTheme.accentRose, const Color(0xFFD81B60));
    });

    test('themeData is Material 3 light with the soft background', () {
      final theme = SpringTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      // Scaffolds are transparent so the app-wide particle layer (which
      // paints softBackground itself) shows through behind all content.
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
      expect(theme.colorScheme.primary, SpringTheme.accentRose);
      expect(theme.colorScheme.onSurface, SpringTheme.textDark);
    });

    test('cards use the white card with rose shadow', () {
      final theme = SpringTheme.themeData;
      expect(theme.cardTheme.color, SpringTheme.surfaceCard);
      expect(theme.cardTheme.elevation, 1);
      expect(theme.cardTheme.shadowColor, const Color(0x1AF06292));
    });
  });

  group('AutumnTheme', () {
    test('palette values match the design spec', () {
      expect(AutumnTheme.primaryAmber, const Color(0xFFD97706));
      expect(AutumnTheme.primaryContainer, const Color(0xFFFEF3C7));
      expect(AutumnTheme.softBackground, const Color(0xFFFFFDF7));
      expect(AutumnTheme.surfaceCard, const Color(0xFFFFFFFF));
      expect(AutumnTheme.cardBorder, const Color(0xFFFDE68A));
      expect(AutumnTheme.textDark, const Color(0xFF451A03));
      expect(AutumnTheme.leafPalette, contains(const Color(0xFFEA580C)));
    });

    test('themeData is Material 3 light with the warm background', () {
      final theme = AutumnTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
      expect(theme.colorScheme.primary, AutumnTheme.primaryAmber);
      expect(theme.colorScheme.onSurface, AutumnTheme.textDark);
    });

    test('cards use the white card with amber border and shadow', () {
      final theme = AutumnTheme.themeData;
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(theme.cardTheme.color, AutumnTheme.surfaceCard);
      expect(shape.side.color, AutumnTheme.cardBorder);
      expect(theme.cardTheme.shadowColor, const Color(0x1AD97706));
    });
  });

  group('WinterTheme', () {
    test('palette values match the design spec', () {
      expect(WinterTheme.primaryFrost, const Color(0xFF0284C7));
      expect(WinterTheme.primaryContainer, const Color(0xFFE0F2FE));
      expect(WinterTheme.softBackground, const Color(0xFFF8FAFC));
      expect(WinterTheme.surfaceCard, const Color(0xFFFFFFFF));
      expect(WinterTheme.cardBorder, const Color(0xFFBAE6FD));
      expect(WinterTheme.textDark, const Color(0xFF0F172A));
    });

    test('themeData is Material 3 light with the snowy background', () {
      final theme = WinterTheme.themeData;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, Colors.transparent);
      expect(theme.colorScheme.primary, WinterTheme.primaryFrost);
      expect(theme.colorScheme.onSurface, WinterTheme.textDark);
    });

    test('cards use the white card with ice border and shadow', () {
      final theme = WinterTheme.themeData;
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(theme.cardTheme.color, WinterTheme.surfaceCard);
      expect(shape.side.color, WinterTheme.cardBorder);
      expect(theme.cardTheme.shadowColor, const Color(0x1A0284C7));
    });
  });
}