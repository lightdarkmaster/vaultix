import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../../authentication/presentation/auto_lock_suspension.dart';
import '../../vault/data/vault_providers.dart';
import '../../vault/presentation/vault_state.dart';
import '../data/backup_codec.dart';
import '../data/backup_providers.dart';
import '../domain/backup_models.dart';

class ImportBackupPage extends ConsumerStatefulWidget {
  const ImportBackupPage({super.key});

  @override
  ConsumerState<ImportBackupPage> createState() => _ImportBackupPageState();
}

class _ImportBackupPageState extends ConsumerState<ImportBackupPage> {
  final _password = TextEditingController();

  Uint8List? _bytes;
  String? _fileName;
  BackupContents? _contents;
  ImportResult? _result;
  ImportMode _mode = ImportMode.merge;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final picked = await runWithoutAutoLock(
        ref,
        () => FilePicker.platform.pickFiles(type: FileType.any, withData: true),
      );
      if (picked == null || picked.files.isEmpty) {
        return;
      }
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = 'Could not read that file.');
        return;
      }
      if (bytes.length > BackupCodec.maxFileBytes) {
        setState(() => _error = 'That file is too large to be a Vaultix backup.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the file picker.');
    } finally {
      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (_) {}
    }
  }

  Future<void> _openBackup() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the backup password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final contents =
          await ref.read(backupCodecProvider).decode(_bytes!, _password.text);
      if (!mounted) return;
      setState(() {
        _contents = contents;
        _busy = false;
      });
    } on BackupException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not open this backup.';
        });
      }
    }
  }

  Future<void> _import() async {
    final contents = _contents!;
    if (_mode == ImportMode.replace) {
      final current = await ref.read(credentialRepositoryProvider).count();
      if (!mounted) {
        return;
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace your vault?'),
          content: Text(
            'This permanently deletes your $current current '
            '${current == 1 ? 'entry' : 'entries'} and custom categories, then '
            'restores ${contents.credentials.length} from the backup. '
            'It cannot be undone.',
          ),
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
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(backupServiceProvider).importBackup(contents, _mode);
      refreshVault(ref);
      if (!mounted) return;
      setState(() {
        _result = result;
        _contents = null; // drop the plaintext as soon as it is imported
        _bytes = null;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The import failed and nothing was changed.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);

    Widget body;
    if (_result != null) {
      final r = _result!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VaultixCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 48, color: AppColors.success),
                const SizedBox(height: 12),
                Text('Import complete',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  '${r.added} ${r.added == 1 ? 'entry' : 'entries'} added'
                  '${r.skipped > 0 ? '\n${r.skipped} duplicate${r.skipped == 1 ? '' : 's'} skipped' : ''}'
                  '${r.categoriesAdded > 0 ? '\n${r.categoriesAdded} new categor${r.categoriesAdded == 1 ? 'y' : 'ies'}' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Done', onPressed: () => context.pop()),
        ],
      );
    } else if (_contents != null) {
      final c = _contents!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VaultixCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backup unlocked',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '${c.credentials.length} '
                  '${c.credentials.length == 1 ? 'entry' : 'entries'} Â· '
                  '${c.categories.length} '
                  '${c.categories.length == 1 ? 'category' : 'categories'}',
                ),
                const SizedBox(height: 4),
                Text('Created ${DateFormat.yMMMd().add_jm().format(c.exportedAt)}',
                    style: TextStyle(color: muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ImportMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ImportMode.merge,
                    icon: Icon(Icons.merge_rounded),
                    label: Text('Merge')),
                ButtonSegment(
                    value: ImportMode.replace,
                    icon: Icon(Icons.swap_horiz_rounded),
                    label: Text('Replace')),
              ],
              selected: {_mode},
              onSelectionChanged:
                  _busy ? null : (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _mode == ImportMode.merge
                ? 'Adds the backup to your vault. Entries with the same name, '
                    'username and website are skipped.'
                : 'Deletes everything in your vault first, then restores the backup.',
            style: TextStyle(color: muted, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _mode == ImportMode.merge ? 'Merge backup' : 'Replace vault',
            icon: Icons.download_rounded,
            isLoading: _busy,
            onPressed: _import,
          ),
        ],
      );
    } else if (_bytes != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VaultixCard(
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_fileName ?? 'Backup file',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _bytes = null;
                            _fileName = null;
                            _error = null;
                            _password.clear();
                          }),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          VaultixTextField(
            controller: _password,
            label: 'Backup password',
            icon: Icons.key_rounded,
            isPassword: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _openBackup(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Unlock backup',
            icon: Icons.lock_open_rounded,
            isLoading: _busy,
            onPressed: _openBackup,
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a Vaultix backup file (.vaultix). You will need the backup '
            'password that was set when it was created.',
            style: TextStyle(color: muted, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Choose backup file',
            icon: Icons.folder_open_rounded,
            onPressed: _pickFile,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import backup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: body,
        ),
      ),
    );
  }
}


