import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _professionController;
  late final TextEditingController _levelController;
  late final TextEditingController _skillsController;
  late final TextEditingController _technologiesController;
  late final TextEditingController _englishLevelController;
  late final TextEditingController _preferredRolesController;

  @override
  void initState() {
    super.initState();

    _professionController = TextEditingController(
      text: widget.profile.profession,
    );

    _levelController = TextEditingController(text: widget.profile.level);

    _skillsController = TextEditingController(text: widget.profile.skills);

    _technologiesController = TextEditingController(
      text: widget.profile.technologies,
    );

    _englishLevelController = TextEditingController(
      text: widget.profile.englishLevel,
    );

    _preferredRolesController = TextEditingController(
      text: widget.profile.preferredRoles,
    );
  }

  @override
  void dispose() {
    _professionController.dispose();
    _levelController.dispose();
    _skillsController.dispose();
    _technologiesController.dispose();
    _englishLevelController.dispose();
    _preferredRolesController.dispose();

    super.dispose();
  }

  List<String> _parseList(String value) {
    final result = <String>[];
    final seen = <String>{};

    for (final item in value.split(',')) {
      final normalized = item.trim();

      if (normalized.isEmpty) {
        continue;
      }

      final key = normalized.toLowerCase();

      if (seen.add(key)) {
        result.add(normalized);
      }
    }

    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(profileUpdateProvider.notifier)
        .updateProfile(
          profession: _professionController.text.trim(),
          level: _levelController.text.trim(),
          skills: _parseList(_skillsController.text),
          technologies: _parseList(_technologiesController.text),
          englishLevel: _englishLevelController.text.trim(),
          preferredRoles: _parseList(_preferredRolesController.text),
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_profile'))));

      return;
    }

    Navigator.pop(context, true);
  }

  String? _validateRequired(
    String? value,
    String fieldName,
    BuildContext context,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${context.tr('required')}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(profileUpdateProvider);
    final isSaving = updateState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('edit_profile'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            TextFormField(
              controller: _professionController,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: context.tr('profession'),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _validateRequired(
                  value,
                  context.tr('profession'),
                  context,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _levelController,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: context.tr('level'),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _validateRequired(value, context.tr('level'), context);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _preferredRolesController,
              enabled: !isSaving,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('preferred_roles'),
                hintText: context.tr('roles_hint'),
                helperText: context.tr('separate_commas'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skillsController,
              enabled: !isSaving,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('skills'),
                hintText: context.tr('api_hint'),
                helperText: context.tr('separate_commas'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _technologiesController,
              enabled: !isSaving,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('technologies'),
                hintText: context.tr('tech_hint'),
                helperText: context.tr('separate_commas'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _englishLevelController,
              enabled: !isSaving,
              decoration: InputDecoration(
                labelText: context.tr('english_level'),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                return _validateRequired(
                  value,
                  context.tr('english_level'),
                  context,
                );
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: isSaving ? null : _save,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  isSaving ? context.tr('saving') : context.tr('save_changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
