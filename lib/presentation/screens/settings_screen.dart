import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

/// App settings: in-app language switching (English / Tiếng Việt), theme
/// selection (System / Light / Dark / Spring / Autumn / Winter) and the
/// seasonal particle toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final selected = locale?.languageCode ?? 'system';
    final themeMode = ref.watch(themeProvider);
    final particlesEnabled = ref.watch(particlesEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListView(
        primary: false,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.languageSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                final notifier = ref.read(localeProvider.notifier);
                switch (value) {
                  case 'en':
                    notifier.setLocale(const Locale('en'));
                  case 'vi':
                    notifier.setLocale(const Locale('vi'));
                  case 'system':
                    notifier.setSystemDefault();
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'system',
                    title: Text(l10n.systemDefault),
                    secondary: const Icon(Icons.phone_android),
                  ),
                  const RadioListTile<String>(
                    value: 'en',
                    title: Text('English'),
                    secondary: Icon(Icons.language),
                  ),
                  const RadioListTile<String>(
                    value: 'vi',
                    title: Text('Tiếng Việt'),
                    secondary: Icon(Icons.language),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.themeSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<AppThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeProvider.notifier).setMode(mode);
                }
              },
              child: Column(
                children: [
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.system,
                    title: Text(l10n.systemDefault),
                    secondary: const Icon(Icons.brightness_auto),
                  ),
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.light,
                    title: Text(l10n.themeLight),
                    secondary: const Icon(Icons.light_mode_outlined),
                  ),
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.dark,
                    title: Text(l10n.themeDark),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.spring,
                    title: Text(l10n.themeSpring),
                    secondary: const Text('🌸'),
                  ),
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.autumn,
                    title: Text(l10n.themeAutumn),
                    secondary: const Text('🍂'),
                  ),
                  RadioListTile<AppThemeMode>(
                    value: AppThemeMode.winter,
                    title: Text(l10n.themeWinter),
                    secondary: const Text('❄️'),
                  ),
                ],
              ),
            ),
          ),
          if (themeMode.isSeasonal) ...[
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                value: particlesEnabled,
                onChanged: (v) =>
                    ref.read(particlesEnabledProvider.notifier).setEnabled(v),
                title: Text(l10n.particlesToggle),
                subtitle: Text(l10n.particlesHint),
                secondary: const Icon(Icons.air),
              ),
            ),
          ],
        ],
      ),
    );
  }
}