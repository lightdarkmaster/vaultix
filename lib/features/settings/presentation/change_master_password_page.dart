import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../../authentication/domain/auth_service.dart';
import '../../authentication/presentation/auth_controller.dart';

class ChangeMasterPasswordPage extends ConsumerStatefulWidget {
  const ChangeMasterPasswordPage({super.key});

  @override
  ConsumerState<ChangeMasterPasswordPage> createState() =>
      _ChangeMasterPasswordPageState();
}

class _ChangeMasterPasswordPageState
    extends ConsumerState<ChangeMasterPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final outcome = await ref
        .read(authControllerProvider.notifier)
        .changeMasterPassword(current: _current.text, next: _new.text);
    if (!mounted) return;
    switch (outcome.status) {
      case UnlockStatus.success:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Master password changed')));
        context.pop();
        return;
      case UnlockStatus.lockedOut:
        // Lock screen takes over; it shows the countdown.
        ref.read(authControllerProvider.notifier).lock();
        return;
      default:
        setState(() {
          _busy = false;
          _currentError = 'Current password is incorrect';
        });
        _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change master password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VaultixTextField(
                  controller: _current,
                  label: 'Current master password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (_currentError != null) return _currentError;
                    return (v ?? '').isEmpty ? 'Required' : null;
                  },
                ),
                const SizedBox(height: 20),
                VaultixTextField(
                  controller: _new,
                  label: 'New master password',
                  icon: Icons.key_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < AppConstants.minMasterPasswordLength) {
                      return 'Use at least ${AppConstants.minMasterPasswordLength} characters';
                    }
                    if (value == _current.text) {
                      return 'Must differ from the current password';
                    }
                    if (!estimatePasswordStrength(value).isAcceptable) {
                      return 'Too easy to guess. Try a longer passphrase.';
                    }
                    return null;
                  },
                ),
                PasswordStrengthMeter(password: _new.text),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _confirm,
                  label: 'Confirm new master password',
                  icon: Icons.key_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v != _new.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Change password',
                  icon: Icons.check_rounded,
                  isLoading: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
