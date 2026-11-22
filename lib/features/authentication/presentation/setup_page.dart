import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import 'auth_controller.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acknowledged = false;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < AppConstants.minMasterPasswordLength) {
      return 'Use at least ${AppConstants.minMasterPasswordLength} characters';
    }
    if (!estimatePasswordStrength(value).isAcceptable) {
      return 'Too easy to guess. Try a longer passphrase.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please confirm you understand there is no recovery.'),
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .setupMasterPassword(_password.text);
      // Router redirects to /home once the vault is unlocked.
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not create the vault. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.shield_rounded,
                            size: 36, color: scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Create your\nmaster password',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      'It protects everything in your vault and is never '
                      'stored on this device.',
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 28),
                    VaultixTextField(
                      controller: _password,
                      label: 'Master password',
                      icon: Icons.key_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      onChanged: (_) => setState(() {}),
                    ),
                    PasswordStrengthMeter(password: _password.text),
                    const SizedBox(height: 16),
                    VaultixTextField(
                      controller: _confirm,
                      label: 'Confirm master password',
                      icon: Icons.key_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _acknowledged,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _acknowledged = v ?? false),
                      title: const Text(
                        'I understand Vaultix cannot recover a forgotten '
                        'master password.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Create vault',
                      icon: Icons.lock_rounded,
                      isLoading: _busy,
                      onPressed: _submit,
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
