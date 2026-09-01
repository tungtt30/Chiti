import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefsKey = 'app_theme_mode';
const _particlesPrefsKey = 'app_particles_enabled';
const _legacyParticlesPrefsKey = 'app_petals_enabled';

/// App theme choice. `null` follows the device system theme.
enum AppThemeMode {
  system,
  light,
  dark,
  spring,
  autumn,
  winter;

  /// Whether this mode is a seasonal (light, particle-background) theme.
  bool get isSeasonal =>
      this == AppThemeMode.spring ||
      this == AppThemeMode.autumn ||
      this == AppThemeMode.winter;

  static AppThemeMode fromValue(String? value) => switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    // Legacy key: the former "Sakura" theme is now "Spring".
    'sakura' => AppThemeMode.spring,
    'spring' => AppThemeMode.spring,
    'autumn' => AppThemeMode.autumn,
    'winter' => AppThemeMode.winter,
    _ => AppThemeMode.system,
  };

  String get value => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.spring => 'spring',
    AppThemeMode.autumn => 'autumn',
    AppThemeMode.winter => 'winter',
  };
}

/// Active app theme + falling-particle toggle, persisted in shared_preferences.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>(
      (ref) => ThemeNotifier(),
    );

/// Whether the seasonal particle background is enabled (only meaningful while
/// a seasonal theme is active).
final particlesEnabledProvider =
    StateNotifierProvider<ParticlesToggleNotifier, bool>(
      (ref) => ParticlesToggleNotifier(),
    );

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppThemeMode.fromValue(prefs.getString(_themePrefsKey));
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefsKey, mode.value);
    } catch (_) {
      // Best-effort.
    }
  }
}

class ParticlesToggleNotifier extends StateNotifier<bool> {
  ParticlesToggleNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Migrate the legacy petals toggle so existing users keep their choice.
      state =
          prefs.getBool(_particlesPrefsKey) ??
          prefs.getBool(_legacyParticlesPrefsKey) ??
          false;
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_particlesPrefsKey, enabled);
    } catch (_) {
      // Best-effort.
    }
  }
}