import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/profile.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/admin_provider.dart';

class AdminUserScreen extends ConsumerWidget {
  const AdminUserScreen({super.key, required this.userId});

  final String userId;

  Future<void> _changeRole({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAdmin,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(isAdmin ? 'revoke_admin' : 'grant_admin')),
        content: Text(context.tr('change_role_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await ref
        .read(adminDashboardProvider.notifier)
        .updateRole(userId: userId, isAdmin: !isAdmin);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(success ? 'admin_role_updated' : 'failed_admin_role'),
        ),
      ),
    );

    if (success) {
      ref.invalidate(adminUserProvider(userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetail = ref.watch(adminUserProvider(userId));
    final currentUserId = ref.watch(currentUserProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('user_details'))),
      body: userDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(adminUserProvider(userId)),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final user = detail.user;
          final profile = detail.profile;
          final canChangeRole =
              currentUserId != null && currentUserId != user.id;

          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Card(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: context.tr('full_name'),
                      value: user.fullName,
                    ),
                    const Divider(height: 1),
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: context.tr('email'),
                      value: user.email,
                    ),
                    const Divider(height: 1),
                    _DetailRow(
                      icon: Icons.tag,
                      label: context.tr('account_id'),
                      value: user.id,
                    ),
                    const Divider(height: 1),
                    _DetailRow(
                      icon: Icons.verified_user_outlined,
                      label: context.tr('account_status'),
                      value: context.tr(
                        user.isAdmin ? 'administrator_role' : 'user_role',
                      ),
                    ),
                    if (user.createdAt != null) ...[
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: context.tr('registered_at'),
                        value: _formatDate(user.createdAt!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ProfileCard(profile: profile),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: canChangeRole
                    ? () => _changeRole(
                        context: context,
                        ref: ref,
                        isAdmin: user.isAdmin,
                      )
                    : null,
                icon: Icon(
                  user.isAdmin
                      ? Icons.person_remove_outlined
                      : Icons.admin_panel_settings_outlined,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    context.tr(user.isAdmin ? 'revoke_admin' : 'grant_admin'),
                  ),
                ),
              ),
              if (!canChangeRole)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('cannot_change_own_role'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day.$month.${local.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: SelectableText(value.isEmpty ? '—' : value),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.person_off_outlined),
          title: Text(context.tr('profile_data')),
          subtitle: Text(context.tr('profile_not_created')),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.badge_outlined),
        title: Text(context.tr('profile_data')),
        subtitle: Text(
          profile!.resumeText.trim().isEmpty
              ? context.tr('resume_absent')
              : context.tr('resume_present'),
        ),
        children: [
          _DetailRow(
            icon: Icons.work_outline,
            label: context.tr('profession'),
            value: profile!.profession,
          ),
          _DetailRow(
            icon: Icons.stairs_outlined,
            label: context.tr('level'),
            value: profile!.level,
          ),
          _DetailRow(
            icon: Icons.psychology_outlined,
            label: context.tr('skills'),
            value: profile!.skills,
          ),
          _DetailRow(
            icon: Icons.code,
            label: context.tr('technologies'),
            value: profile!.technologies,
          ),
          _DetailRow(
            icon: Icons.language,
            label: context.tr('english_level'),
            value: profile!.englishLevel,
          ),
          _DetailRow(
            icon: Icons.badge_outlined,
            label: context.tr('preferred_roles'),
            value: profile!.preferredRoles,
          ),
        ],
      ),
    );
  }
}
