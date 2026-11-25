import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../../authentication/domain/auth_service.dart';
import '../../authentication/presentation/auth_controller.dart';

class ClearVaultPage extends ConsumerStatefulWidget {
  const ClearVaultPage({super.key});

  @override
  ConsumerState<ClearVaultPage> createState() => _ClearVaultPageState();
}

class _ClearVaultPageState extends ConsumerState<ClearVaultPage> {
  final _formKey = GlobalKey<FormState>();
  final _master = TextEditingController();
  bool _understood = false;
  bool _busy = false;
  String? _masterError;

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  Future<void> _erase() async {
    setState(() => _masterError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_understood) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please confirm that you understand this cannot be undone.'),
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
            'All passwords, categories and your master password will be '
            'permanently deleted from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final outcome = await ref
          .read(authControllerProvider.notifier)
          .clearVaultData(_master.text);
      if (!mounted) return;
      if (outcome.status == UnlockStatus.lockedOut) return; // lock screen shows
      if (!outcome.isSuccess) {
        setState(() {
          _busy = false;
          _masterError = 'Incorrect master password';
        });
        _formKey.currentState!.validate();
      }
      // On success the app returns to first-time setup automatically.
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not erase the vault. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clear vault data')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This permanently deletes every password, category, '
                          'your master password, PIN and biometric unlock. '
                          'Export a backup first if you might need your data.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                VaultixTextField(
                  controller: _master,
                  label: 'Master password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _erase(),
                  validator: (v) {
                    if (_masterError != null) return _masterError;
                    return (v ?? '').isEmpty ? 'Required' : null;
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _understood,
                  onChanged:
                      _busy ? null : (v) => setState(() => _understood = v ?? false),
                  title: const Text('I understand this cannot be undone.',
                      style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.18),
                    foregroundColor: AppColors.error,
                    disabledBackgroundColor: AppColors.error.withValues(alpha: 0.10),
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  onPressed: _busy ? null : _erase,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: AppColors.error),
                        )
                      : const Text('Erase everything'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
