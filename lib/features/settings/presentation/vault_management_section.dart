import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../data/backup_providers.dart';
import '../data/storage_info.dart';

class VaultManagementSection extends ConsumerWidget {
  const VaultManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastBackup = ref.watch(lastBackupProvider);

    return VaultixCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Export encrypted backup'),
            subtitle: Text(lastBackup == null
                ? 'No backup yet'
                : 'Last backup: ${DateFormat.yMMMd().add_jm().format(lastBackup)}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/backup/export'),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Import encrypted backup'),
            subtitle: const Text('Restore or merge from a backup file'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/backup/import'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: const Text('Storage information'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showStorage(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: const Text('Clear vault data',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Erase everything and start over'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/clear-vault'),
          ),
        ],
      ),
    );
  }

  void _showStorage(BuildContext context, WidgetRef ref) {
    final future = ref.read(storageInfoServiceProvider).load();
    final dateFmt = DateFormat.yMMMd();

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage information'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<StorageInfo>(
            future: future,
            builder: (_, snap) {
              if (snap.hasError) {
                return const Text('Could not read storage information.');
              }
              final i = snap.data;
              if (i == null) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final k = i.kdfParams;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row('Passwords', '${i.credentialCount}'),
                  row('Categories',
                      '${i.categoryCount} (${i.customCategoryCount} custom)'),
                  row('Database size', formatBytes(i.databaseBytes)),
                  if (i.vaultCreatedAt != null)
                    row('Vault created', dateFmt.format(i.vaultCreatedAt!)),
                  if (k != null)
                    row('Key derivation',
                        'Argon2id, ${k.memoryKiB ~/ 1024} MiB × ${k.iterations}'),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
