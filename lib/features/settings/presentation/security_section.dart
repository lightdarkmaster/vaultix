import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/security/kdf_params.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../data/auto_lock_provider.dart';
import '../data/clipboard_provider.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final ctrl = ref.read(authControllerProvider.notifier);
    final autoLock = ref.watch(autoLockProvider);

    return VaultixCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_clock_rounded),
            title: const Text('Lock vault now'),
            onTap: ctrl.lock,
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric unlock'),
            subtitle: Text(auth.biometricAvailable
                ? 'Use fingerprint or face to unlock'
                : 'Not available on this device'),
            value: auth.biometricEnabled,
            onChanged: auth.biometricAvailable
                ? (v) async {
                    final ok = await ctrl.setBiometric(v);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Biometric confirmation failed or was cancelled.'),
                      ));
                    }
                  }
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pin_outlined),
            title: const Text('PIN unlock'),
            subtitle: const Text('Quick unlock with a 6-digit PIN'),
            value: auth.pinEnabled,
            onChanged: (v) async {
              if (v) {
                context.push('/pin-setup');
              } else {
                final confirmed = await _confirm(
                  context,
                  title: 'Remove PIN?',
                  message: 'You will need your master password to unlock.',
                  action: 'Remove',
                );
                if (confirmed) await ctrl.disablePin();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('Change master password'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/change-master'),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock'),
            subtitle: Text(autoLockOptions[autoLock] ?? ''),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickAutoLock(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_off_rounded),
            title: const Text('Clear clipboard'),
            subtitle: Text(
                clipboardClearOptions[ref.watch(clipboardClearProvider)] ?? ''),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickClipboard(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Security information'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showInfo(context, ref),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _pickAutoLock(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final current = ref.read(autoLockProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in autoLockOptions.entries)
                ListTile(
                  title: Text(e.value),
                  trailing:
                      e.key == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    ref.read(autoLockProvider.notifier).set(e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _pickClipboard(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final current = ref.read(clipboardClearProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in clipboardClearOptions.entries)
                ListTile(
                  title: Text(e.value),
                  trailing:
                      e.key == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    ref.read(clipboardClearProvider.notifier).set(e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Security information'),
        content: FutureBuilder<KdfParams?>(
          future: ref.read(authServiceProvider).kdfParams(),
          builder: (_, snap) {
            final p = snap.data;
            return Text(
              'Encryption: AES-256-GCM (unique nonce per item)\n'
              'Key derivation: Argon2id'
              '${p == null ? '' : '\n  memory ${p.memoryKiB ~/ 1024} MiB, '
                  '${p.iterations} iterations, ${p.parallelism} lane'}\n'
              'Vault key: random 256-bit, wrapped by your master password\n'
              'Quick unlock keys: Android Keystore-backed storage\n'
              'Network: none. Your data never leaves this device.',
              style: const TextStyle(height: 1.5),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
