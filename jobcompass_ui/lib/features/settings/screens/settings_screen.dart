import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../providers/account_provider.dart';
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
    final currentUser = ref.watch(currentUserProvider);

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
            child: currentUser.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(strings.tr('account')),
                subtitle: Text(strings.tr('failed_load_account')),
                trailing: IconButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  icon: const Icon(Icons.refresh),
                  tooltip: strings.tr('retry'),
                ),
              ),
              data: (user) => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(strings.tr('account')),
                    subtitle: Text(user.fullName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.email_outlined),
                    title: Text(strings.tr('login')),
                    subtitle: SelectableText(user.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.tag),
                    title: Text(strings.tr('account_id')),
                    subtitle: SelectableText(user.id),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(strings.tr('account_status')),
                    subtitle: Text(
                      strings.tr(
                        user.isAdmin ? 'administrator_role' : 'user_role',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                ExpansionTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(strings.tr('privacy')),
                  subtitle: Text(strings.tr('privacy_subtitle')),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PrivacyPoint(text: strings.tr('privacy_passwords')),
                    _PrivacyPoint(text: strings.tr('privacy_profile')),
                    _PrivacyPoint(text: strings.tr('privacy_resume')),
                    _PrivacyPoint(text: strings.tr('privacy_admin')),
                  ],
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

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
