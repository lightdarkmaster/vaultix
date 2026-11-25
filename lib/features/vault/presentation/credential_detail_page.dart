import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../dashboard/presentation/dashboard_state.dart';
import '../../settings/data/clipboard_provider.dart';
import '../data/vault_providers.dart';
import '../domain/credential.dart';
import 'vault_state.dart';
import 'widgets/credential_avatar.dart';

class CredentialDetailPage extends ConsumerStatefulWidget {
  const CredentialDetailPage({super.key, required this.id});
  final int id;

  @override
  ConsumerState<CredentialDetailPage> createState() =>
      _CredentialDetailPageState();
}

class _CredentialDetailPageState extends ConsumerState<CredentialDetailPage> {
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Opening an entry counts as an access (feeds "Recently accessed" and
    // "Frequently used" on the dashboard).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(credentialRepositoryProvider).markAccessed(widget.id);
      if (!mounted) return;
      ref.invalidate(recentlyAccessedProvider);
      ref.invalidate(frequentlyUsedProvider);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String label, String text, {bool sensitive = true}) async {
    final service = ref.read(clipboardServiceProvider);
    await service.copy(text, sensitive: sensitive);
    if (!mounted) return;
    final secs = service.delaySeconds;
    _snack(sensitive && secs > 0
        ? '$label copied · clears in ${secs}s'
        : '$label copied');
  }

  Future<void> _openWebsite(String raw) async {
    final uri = normalizeWebUrl(raw);
    if (uri == null) {
      _snack('This is not a valid web address');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Could not open the link');
    } catch (_) {
      if (mounted) _snack('Could not open the link');
    }
  }

  Future<void> _toggleFavorite(Credential c) async {
    await ref
        .read(credentialRepositoryProvider)
        .setFavorite(c.id, !c.summary.isFavorite);
    ref.invalidate(credentialDetailProvider(c.id));
    ref.invalidate(credentialListProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  Future<void> _delete(Credential c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${c.summary.title}"?'),
        content: const Text(
            'This permanently removes the entry from your vault. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: AppColors.error.withValues(alpha: 0.18),
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(credentialRepositoryProvider).delete(c.id);
      refreshVault(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Entry deleted')));
    } catch (_) {
      if (mounted) _snack('Could not delete this entry');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(credentialDetailProvider(widget.id));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final cred = detail.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: cred == null
            ? null
            : [
                IconButton(
                  tooltip: cred.summary.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: () => _toggleFavorite(cred),
                  icon: Icon(
                    cred.summary.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        cred.summary.isFavorite ? AppColors.warning : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => context.push('/vault/${cred.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(cred),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not open this entry',
          message: 'It may be damaged or the vault may be locked.',
        ),
        data: (c) {
          if (c == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Entry not found',
              message: 'It may have been deleted.',
            );
          }
          final category =
              categories.where((x) => x.category.id == c.summary.categoryId)
                  .map((x) => x.category)
                  .firstOrNull;
          return _content(context, c, category);
        },
      ),
    );
  }

  Widget _content(BuildContext context, Credential c, Category? category) {
    final scheme = Theme.of(context).colorScheme;
    final s = c.summary;
    final color = category != null ? Color(category.color) : scheme.primary;
    final dateFmt = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            CredentialAvatar(title: s.title, color: color, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (category != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(CategoryIcons.resolve(category.iconKey),
                            size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(category.name,
                            style: TextStyle(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (s.username != null)
          _FieldCard(
            label: 'Username',
            value: Text(s.username!),
            actions: [
              IconButton(
                tooltip: 'Copy username',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () =>
                    _copy('Username', s.username!, sensitive: false),
              ),
            ],
          ),
        _FieldCard(
          label: 'Password',
          value: Text(
            _showPassword ? c.password : '••••••••••••',
            style: TextStyle(
              fontFamily: _showPassword ? 'monospace' : null,
              letterSpacing: _showPassword ? 0.5 : 2,
            ),
          ),
          actions: [
            IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              icon: Icon(_showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            IconButton(
              tooltip: 'Copy password',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copy('Password', c.password),
            ),
          ],
        ),
        if (s.websiteUrl != null)
          _FieldCard(
            label: 'Website',
            value: Text(s.websiteUrl!),
            actions: [
              IconButton(
                tooltip: 'Open website',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () => _openWebsite(s.websiteUrl!),
              ),
              IconButton(
                tooltip: 'Copy website',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () =>
                    _copy('Website', s.websiteUrl!, sensitive: false),
              ),
            ],
          ),
        if (c.notes != null)
          _FieldCard(
            label: 'Notes',
            value: Text(c.notes!),
            actions: [
              IconButton(
                tooltip: 'Copy notes',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy('Notes', c.notes!),
              ),
            ],
          ),
        if (s.tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in s.tags)
                Chip(
                  label: Text('#$t'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        VaultixCard(
          child: Column(
            children: [
              _MetaRow('Created', dateFmt.format(s.createdAt)),
              _MetaRow('Last modified', dateFmt.format(s.updatedAt)),
              _MetaRow('Password changed', dateFmt.format(s.passwordUpdatedAt)),
              if (s.lastAccessedAt != null)
                _MetaRow('Last opened', dateFmt.format(s.lastAccessedAt!)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.value,
    required this.actions,
  });

  final String label;
  final Widget value;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VaultixCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                  const SizedBox(height: 4),
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 16),
                    child: value,
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: muted))),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
