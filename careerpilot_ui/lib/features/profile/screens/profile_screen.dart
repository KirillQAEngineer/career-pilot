import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (profile) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              await ref.read(profileProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                CircleAvatar(
                  radius: 46,
                  child: Text(
                    _getProfileInitial(profile.profession),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  profile.profession.isEmpty
                      ? 'Profession not specified'
                      : profile.profession,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  profile.level.isEmpty
                      ? 'Level not specified'
                      : profile.level,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 30),

                _ProfileSection(
                  icon: Icons.badge_outlined,
                  title: 'Preferred Roles',
                  value: profile.preferredRoles,
                  emptyValue: 'No preferred roles specified',
                ),

                _ProfileSection(
                  icon: Icons.psychology_outlined,
                  title: 'Skills',
                  value: profile.skills,
                  emptyValue: 'No skills specified',
                ),

                _ProfileSection(
                  icon: Icons.code,
                  title: 'Technologies',
                  value: profile.technologies,
                  emptyValue: 'No technologies specified',
                ),

                _ProfileSection(
                  icon: Icons.language,
                  title: 'English Level',
                  value: profile.englishLevel,
                  emptyValue: 'English level not specified',
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                    ),
                    title: const Text('Resume'),
                    subtitle: Text(
                      profile.resumeText.isEmpty
                          ? 'Resume is empty'
                          : 'View resume text',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: profile.resumeText.isEmpty
                        ? null
                        : () {
                            _showResume(
                              context,
                              profile.resumeText,
                            );
                          },
                  ),
                ),

                const SizedBox(height: 32),

                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(authProvider.notifier)
                        .logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getProfileInitial(String profession) {
    final value = profession.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value[0].toUpperCase();
  }

  void _showResume(
    BuildContext context,
    String resumeText,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resume'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: SelectableText(resumeText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String emptyValue;

  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.value,
    required this.emptyValue,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty
        ? emptyValue
        : value;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(displayValue),
        ),
      ),
    );
  }
}