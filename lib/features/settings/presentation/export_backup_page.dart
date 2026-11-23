import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../../authentication/domain/auth_service.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../authentication/presentation/auto_lock_suspension.dart';
import '../data/backup_providers.dart';

class ExportBackupPage extends ConsumerStatefulWidget {
  const ExportBackupPage({super.key});

  @override
  ConsumerState<ExportBackupPage> createState() => _ExportBackupPageState();
}

class _ExportBackupPageState extends ConsumerState<ExportBackupPage> {
  static const _filePrefix = 'vaultix-backup-';

  final _formKey = GlobalKey<FormState>();
  final _master = TextEditingController();
  final _backup = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String _stage = '';
  String? _masterError;

  @override
  void dispose() {
    _master.dispose();
    _backup.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Removes backup files left in the temp folder by earlier exports. They are
  /// not deleted right after sharing because the receiving app may still be
  /// reading them.
  Future<void> _cleanOldBackups(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.uri.pathSegments.last.startsWith(_filePrefix)) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _masterError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _stage = 'Checking your master password…';
    });

    final outcome = await ref
        .read(authControllerProvider.notifier)
        .verifyMasterPassword(_master.text);
    if (!mounted) return;
    if (outcome.status == UnlockStatus.lockedOut) return; // lock screen shows
    if (!outcome.isSuccess) {
      setState(() {
        _busy = false;
        _masterError = 'Incorrect master password';
      });
      _formKey.currentState!.validate();
      return;
    }

    try {
      setState(() => _stage = 'Encrypting your backup…');
      final bytes =
          await ref.read(backupServiceProvider).createBackup(_backup.text);

      final dir = await getTemporaryDirectory();
      await _cleanOldBackups(dir);
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final name = '$_filePrefix$stamp.vaultix';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _stage = 'Opening share sheet…');
      final result = await runWithoutAutoLock(
        ref,
        () => Share.shareXFiles(
          [XFile(file.path, name: name, mimeType: 'application/octet-stream')],
          subject: 'Vaultix encrypted backup',
        ),
      );
      if (!mounted) return;

      if (result.status == ShareResultStatus.dismissed) {
        setState(() => _busy = false);
        _snack('Sharing was cancelled. No backup was saved.');
        return;
      }
      await ref.read(lastBackupProvider.notifier).markNow();
      _snack('Backup created. Keep the file and its password somewhere safe.');
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Could not create the backup. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Export backup')),
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
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'The backup is encrypted with a backup password you choose '
                    'now. Vaultix cannot recover it, so without that password '
                    'the file cannot be opened.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                VaultixTextField(
                  controller: _master,
                  label: 'Master password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (_masterError != null) return _masterError;
                    return (v ?? '').isEmpty ? 'Required' : null;
                  },
                ),
                const SizedBox(height: 20),
                VaultixTextField(
                  controller: _backup,
                  label: 'Backup password',
                  icon: Icons.key_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < AppConstants.minMasterPasswordLength) {
                      return 'Use at least ${AppConstants.minMasterPasswordLength} characters';
                    }
                    if (!estimatePasswordStrength(value).isAcceptable) {
                      return 'Too easy to guess. Try a longer passphrase.';
                    }
                    return null;
                  },
                ),
                PasswordStrengthMeter(password: _backup.text),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _confirm,
                  label: 'Confirm backup password',
                  icon: Icons.key_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v != _backup.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Create and share backup',
                  icon: Icons.ios_share_rounded,
                  isLoading: _busy,
                  onPressed: _submit,
                ),
                if (_busy) ...[
                  const SizedBox(height: 14),
                  Text(_stage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
