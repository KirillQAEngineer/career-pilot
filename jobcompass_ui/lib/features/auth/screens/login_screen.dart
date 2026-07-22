import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool isRegisterMode = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    if (isRegisterMode) {
      await authNotifier.register(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
      );
    } else {
      await authNotifier.login(
        email: emailController.text,
        password: passwordController.text,
      );
    }
  }

  void toggleMode() {
    ref.read(authProvider.notifier).clearError();
    formKey.currentState?.reset();

    setState(() {
      isRegisterMode = !isRegisterMode;
      obscurePassword = true;
      obscureConfirmPassword = true;
      passwordController.clear();
      confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'JobCompass',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      context.tr(
                        isRegisterMode
                            ? 'sign_up_subtitle'
                            : 'sign_in_subtitle',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 36),

                    if (isRegisterMode) ...[
                      TextFormField(
                        controller: fullNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: context.tr('full_name'),
                          hintText: context.tr('full_name_hint'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          final fullName = value?.trim() ?? '';

                          if (fullName.isEmpty) {
                            return context.tr('enter_full_name');
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: InputDecoration(
                        labelText: context.tr('email'),
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return context.tr('enter_email');
                        }

                        if (!email.contains('@')) {
                          return context.tr('valid_email');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: context.tr('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('enter_password');
                        }

                        if (isRegisterMode && value.length < 12) {
                          return context.tr('password_min_length');
                        }

                        if (value.length > 128) {
                          return context.tr('password_max_length');
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!isRegisterMode && !authState.isLoading) {
                          submit();
                        }
                      },
                    ),

                    if (isRegisterMode) ...[
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: context.tr('confirm_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('confirm_password_required');
                          }

                          if (value != passwordController.text) {
                            return context.tr('passwords_do_not_match');
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!authState.isLoading) {
                            submit();
                          }
                        },
                      ),
                    ],

                    if (authState.error != null) ...[
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          authState.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: authState.isLoading ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.tr(
                                  isRegisterMode ? 'sign_up' : 'sign_in',
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: authState.isLoading ? null : toggleMode,
                      child: Text(
                        context.tr(
                          isRegisterMode
                              ? 'already_have_account'
                              : 'create_account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
