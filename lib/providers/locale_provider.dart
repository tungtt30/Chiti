import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePrefsKey = 'app_locale';

/// Active app locale.
///
/// `null` means "follow the device system locale". A non-null value is
/// persisted via `shared_preferences` so the user's choice survives restarts.
final localeProvider = StateNotifierProvider<AppLocaleNotifier, Locale?>(
  (ref) => AppLocaleNotifier(),
);

class AppLocaleNotifier extends StateNotifier<Locale?> {
  AppLocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code != null) {
      await initializeDateFormatting(code);
      state = Locale(code);
    }
  }

  /// Switches the app language and persists the choice.
  Future<void> setLocale(Locale locale) async {
    await initializeDateFormatting(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, locale.languageCode);
    state = locale;
  }

  /// Returns to following the device system locale.
  Future<void> setSystemDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localePrefsKey);
    state = null;
  }
}