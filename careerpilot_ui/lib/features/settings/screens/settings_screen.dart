import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Theme"),
            subtitle: const Text("Use dark appearance"),
            value: theme == ThemeMode.dark,
            onChanged: (_) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
            subtitle: Text("English"),
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text("Notifications"),
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text("Privacy"),
          ),

          const Divider(),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("About CareerPilot"),
            subtitle: Text("Version 1.0"),
          ),
        ],
      ),
    );
  }
}