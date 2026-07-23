import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/profile_provider.dart';

enum ProfileEditField {
  profession,
  level,
  preferredRoles,
  skills,
  technologies,
  englishLevel,
}

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final ProfileEditField? initialField;

  const EditProfileScreen({
    super.key,
    required this.profile,
    this.initialField,
  });

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
  late final Map<ProfileEditField, FocusNode> _focusNodes;

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

    _focusNodes = {
      for (final field in ProfileEditField.values) field: FocusNode(),
    };
  }

  @override
  void dispose() {
    _professionController.dispose();
    _levelController.dispose();
    _skillsController.dispose();
    _technologiesController.dispose();
    _englishLevelController.dispose();
    _preferredRolesController.dispose();

    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }

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
              focusNode: _focusNodes[ProfileEditField.profession],
              autofocus: widget.initialField == ProfileEditField.profession,
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
              focusNode: _focusNodes[ProfileEditField.level],
              autofocus: widget.initialField == ProfileEditField.level,
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
              focusNode: _focusNodes[ProfileEditField.preferredRoles],
              autofocus: widget.initialField == ProfileEditField.preferredRoles,
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
              focusNode: _focusNodes[ProfileEditField.skills],
              autofocus: widget.initialField == ProfileEditField.skills,
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
              focusNode: _focusNodes[ProfileEditField.technologies],
              autofocus: widget.initialField == ProfileEditField.technologies,
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
              focusNode: _focusNodes[ProfileEditField.englishLevel],
              autofocus: widget.initialField == ProfileEditField.englishLevel,
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
