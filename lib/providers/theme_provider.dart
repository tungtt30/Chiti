import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefsKey = 'app_theme_mode';
const _petalsPrefsKey = 'app_petals_enabled';

/// App theme choice. `null` follows the device system theme.
enum AppThemeMode {
  system,
  light,
  dark,
  sakura;

  static AppThemeMode fromValue(String? value) => switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    'sakura' => AppThemeMode.sakura,
    _ => AppThemeMode.system,
  };

  String get value => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.sakura => 'sakura',
  };
}

/// Active app theme + falling-petal toggle, persisted in shared_preferences.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>(
      (ref) => ThemeNotifier(),
    );

/// Whether the falling-petal background is enabled (only meaningful while the
/// Sakura theme is active).
final petalsEnabledProvider =
    StateNotifierProvider<PetalsToggleNotifier, bool>(
      (ref) => PetalsToggleNotifier(),
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

class PetalsToggleNotifier extends StateNotifier<bool> {
  PetalsToggleNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_petalsPrefsKey) ?? false;
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_petalsPrefsKey, enabled);
    } catch (_) {
      // Best-effort.
    }
  }
}