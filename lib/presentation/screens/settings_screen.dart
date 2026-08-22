import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// App settings: in-app language switching (English / Tiếng Việt).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final selected = locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListView(
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
        ],
      ),
    );
  }
}