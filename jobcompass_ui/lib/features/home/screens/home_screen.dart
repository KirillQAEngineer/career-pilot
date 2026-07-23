import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenFeed;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSaved;

  const HomeScreen({
    super.key,
    required this.onOpenFeed,
    required this.onOpenProfile,
    required this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JobCompass',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: profileAsync.when(
        loading: () => const _LoadingHome(),
        error: (error, stackTrace) => _HomeMessage(
          icon: Icons.cloud_off_outlined,
          title: strings.tr('failed_load_profile'),
          description: strings.tr('failed_load_profile_description'),
          buttonLabel: strings.tr('retry'),
          onPressed: () => ref.invalidate(profileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return _NewUserHome(onOpenProfile: onOpenProfile);
          }

          return _ReadyUserHome(
            profession: profile.profession,
            level: profile.level,
            onOpenFeed: onOpenFeed,
            onOpenSaved: onOpenSaved,
            onOpenProfile: onOpenProfile,
          );
        },
      ),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 10),
        _IntroCard(
          icon: Icons.flight_takeoff_outlined,
          title: strings.tr('platform_title'),
          description: strings.tr('platform_description'),
        ),
        _HowToCard(),
      ],
    );
  }
}

class _NewUserHome extends StatelessWidget {
  final VoidCallback onOpenProfile;

  const _NewUserHome({required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _IntroCard(
          icon: Icons.flight_takeoff_outlined,
          title: strings.tr('platform_title'),
          description: strings.tr('platform_description'),
        ),
        _HowToCard(),
        FilledButton.icon(
          onPressed: onOpenProfile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(strings.tr('upload_resume')),
          ),
        ),
      ],
    );
  }
}

class _ReadyUserHome extends StatelessWidget {
  final String profession;
  final String level;
  final VoidCallback onOpenFeed;
  final VoidCallback onOpenSaved;
  final VoidCallback onOpenProfile;

  const _ReadyUserHome({
    required this.profession,
    required this.level,
    required this.onOpenFeed,
    required this.onOpenSaved,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final professionText = profession.trim().isEmpty
        ? strings.tr('profile_not_specified')
        : profession;
    final levelText = level.trim().isEmpty
        ? strings.tr('level_not_specified')
        : level;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _IntroCard(
          icon: Icons.waving_hand_outlined,
          title: strings.tr('welcome_back'),
          description: strings.tr('workspace_ready'),
        ),
        Card(
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(
              professionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(levelText),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenProfile,
          ),
        ),
        const SizedBox(height: 10),
        _HowToCard(),
        _ActionCard(
          icon: Icons.work_outline,
          title: strings.tr('open_feed'),
          description: strings.tr('step_discover_description'),
          onTap: onOpenFeed,
        ),
        _ActionCard(
          icon: Icons.bookmark_outline,
          title: strings.tr('open_saved'),
          description: strings.tr('step_save_description'),
          onTap: onOpenSaved,
        ),
        _ActionCard(
          icon: Icons.person_outline,
          title: strings.tr('manage_profile'),
          description: strings.tr('step_upload_description'),
          onTap: onOpenProfile,
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _IntroCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final steps = [
      (
        Icons.upload_file_outlined,
        strings.tr('step_upload'),
        strings.tr('step_upload_description'),
      ),
      (
        Icons.work_outline,
        strings.tr('step_discover'),
        strings.tr('step_discover_description'),
      ),
      (
        Icons.bookmark_outline,
        strings.tr('step_save'),
        strings.tr('step_save_description'),
      ),
      (
        Icons.view_kanban_outlined,
        strings.tr('step_track'),
        strings.tr('step_track_description'),
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
              child: Text(
                strings.tr('how_to_use'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final step in steps)
              ListTile(
                dense: true,
                leading: Icon(step.$1),
                title: Text(step.$2),
                subtitle: Text(step.$3),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _HomeMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
