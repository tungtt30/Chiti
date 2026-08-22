import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/providers/locale_provider.dart';

Future<void> _settle(ProviderContainer container) async {
  for (var i = 0; i < 20 && container.read(localeProvider) == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to null (system locale) when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _settle(container);
    expect(container.read(localeProvider), isNull);
  });

  test('setLocale persists the choice across provider restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _settle(container);

    await container.read(localeProvider.notifier).setLocale(const Locale('vi'));
    expect(container.read(localeProvider), const Locale('vi'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'vi');

    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    await _settle(restarted);
    expect(restarted.read(localeProvider), const Locale('vi'));

    await restarted
        .read(localeProvider.notifier)
        .setLocale(const Locale('en'));
    final enPrefs = await SharedPreferences.getInstance();
    expect(enPrefs.getString('app_locale'), 'en');
  });

  test('setSystemDefault clears the saved language', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'vi'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _settle(container);
    expect(container.read(localeProvider), const Locale('vi'));

    await container.read(localeProvider.notifier).setSystemDefault();
    expect(container.read(localeProvider), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('app_locale'), isFalse);
  });
}