import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/resume_upload_provider.dart';
import '../../settings/screens/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final uploadState = ref.watch(resumeUploadProvider);
    final isUploading = uploadState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('profile'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) {
              if (profile == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: context.tr('edit_profile'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: isUploading
                    ? null
                    : () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(profile: profile),
                          ),
                        );

                        if (updated == true) {
                          ref.invalidate(profileProvider);
                        }
                      },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: context.tr('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('retry')),
                  ),
                ],
              ),
            ),
          );
        },
        data: (profile) {
          if (profile == null) {
            return _EmptyProfileState(
              isUploading: isUploading,
              onUpload: () async {
                final uploaded = await ref
                    .read(resumeUploadProvider.notifier)
                    .pickAndUploadResume();

                if (!context.mounted) {
                  return;
                }

                if (uploaded) {
                  ref.invalidate(profileProvider);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('resume_created'))),
                  );

                  return;
                }

                final state = ref.read(resumeUploadProvider);

                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('failed_upload'))),
                  );
                }
              },
            );
          }

          final hasResume = profile.resumeText.trim().isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              await ref.read(profileProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    _getProfileInitial(profile.profession),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.profession.isEmpty
                      ? context.tr('profile_not_specified')
                      : profile.profession,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.level.isEmpty
                      ? context.tr('level_not_specified')
                      : profile.level,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),
                _ProfileSection(
                  icon: Icons.badge_outlined,
                  title: context.tr('preferred_roles'),
                  value: profile.preferredRoles,
                  emptyValue: context.tr('no_preferred_roles'),
                ),
                _ProfileSection(
                  icon: Icons.psychology_outlined,
                  title: context.tr('skills'),
                  value: profile.skills,
                  emptyValue: context.tr('no_skills'),
                ),
                _ProfileSection(
                  icon: Icons.code,
                  title: context.tr('technologies'),
                  value: profile.technologies,
                  emptyValue: context.tr('no_technologies'),
                ),
                _ProfileSection(
                  icon: Icons.language,
                  title: context.tr('english_level'),
                  value: profile.englishLevel,
                  emptyValue: context.tr('no_english_level'),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(context.tr('resume')),
                        subtitle: Text(
                          hasResume
                              ? context.tr('resume_uploaded')
                              : context.tr('no_resume'),
                        ),
                        trailing: hasResume
                            ? const Icon(Icons.chevron_right)
                            : null,
                        onTap: hasResume
                            ? () {
                                _showResume(context, profile.resumeText);
                              }
                            : null,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      final uploaded = await ref
                                          .read(resumeUploadProvider.notifier)
                                          .pickAndUploadResume();

                                      if (!context.mounted) {
                                        return;
                                      }

                                      if (uploaded) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              hasResume
                                                  ? context.tr(
                                                      'resume_replaced',
                                                    )
                                                  : context.tr(
                                                      'resume_created',
                                                    ),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final state = ref.read(
                                        resumeUploadProvider,
                                      );

                                      if (state.hasError) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.tr('failed_upload'),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      hasResume
                                          ? Icons.sync_outlined
                                          : Icons.upload_file_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                isUploading
                                    ? context.tr('analyzing_resume')
                                    : hasResume
                                    ? context.tr('replace_resume')
                                    : context.tr('upload_resume'),
                              ),
                            ),
                            if (hasResume)
                              OutlinedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: Text(
                                                context.tr(
                                                  'delete_resume_title',
                                                ),
                                              ),
                                              content: Text(
                                                context.tr(
                                                  'delete_resume_description',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    context.tr('cancel'),
                                                  ),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    context.tr('delete'),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirmed != true ||
                                            !context.mounted) {
                                          return;
                                        }

                                        final deleted = await ref
                                            .read(
                                              profileDeleteProvider.notifier,
                                            )
                                            .deleteProfile();

                                        if (!context.mounted) {
                                          return;
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              deleted
                                                  ? context.tr('resume_deleted')
                                                  : context.tr('failed_delete'),
                                            ),
                                          ),
                                        );
                                      },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: Text(context.tr('delete_resume')),
                              ),
                          ],
                        ),
                      ),
                    ],
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

  void _showResume(BuildContext context, String resumeText) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('resume')),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(child: SelectableText(resumeText)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(context.tr('close')),
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
    final displayValue = value.trim().isEmpty ? emptyValue : value;

    return Card(
      child: ListTile(
        dense: true,
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

class _EmptyProfileState extends StatelessWidget {
  final bool isUploading;
  final Future<void> Function() onUpload;

  const _EmptyProfileState({required this.isUploading, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 52),
              const SizedBox(height: 14),
              Text(
                context.tr('manage_profile'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('step_upload_description'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          await onUpload();
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      isUploading
                          ? context.tr('analyzing_resume')
                          : context.tr('upload_resume'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
