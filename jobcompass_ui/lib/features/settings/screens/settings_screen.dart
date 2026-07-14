import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.tr('logout_title')),
        content: Text(strings.tr('logout_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.tr('logout')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final theme = ref.watch(themeProvider);
    final language = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.tr('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(strings.tr('dark_theme')),
                  subtitle: Text(strings.tr('dark_theme_subtitle')),
                  value: theme == ThemeMode.dark,
                  onChanged: (_) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(strings.tr('language')),
                  subtitle: Text(
                    language == AppLanguage.russian
                        ? strings.tr('russian')
                        : strings.tr('english'),
                  ),
                  trailing: DropdownButton<AppLanguage>(
                    value: language,
                    underline: const SizedBox.shrink(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(localeProvider.notifier).setLanguage(value);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: AppLanguage.english,
                        child: Text(strings.tr('english')),
                      ),
                      DropdownMenuItem(
                        value: AppLanguage.russian,
                        child: Text(strings.tr('russian')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(strings.tr('notifications')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(strings.tr('privacy')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(strings.tr('about')),
                  subtitle: Text(strings.tr('version')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings.tr('logout')),
              onTap: () => _logout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
