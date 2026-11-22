import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/utils/exceptions.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../domain/category.dart';
import 'category_editor_sheet.dart';
import 'category_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  void _openEditor(BuildContext context, [Category? category]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CategoryEditorSheet(category: category),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CategoryWithCount item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.category.name}"?'),
        content: Text(item.credentialCount == 0
            ? 'This category is empty.'
            : '${item.credentialCount} credential'
                '${item.credentialCount == 1 ? '' : 's'} will move to Other.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoryRepositoryProvider).delete(item.category.id);
      ref.invalidate(categoriesProvider);
    } on ValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load categories',
          message: 'Something went wrong reading the database.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(categoriesProvider),
        ),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = items[i];
            final c = item.category;
            final color = Color(c.color);
            return VaultixCard(
              onTap: () => _openEditor(context, c),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(CategoryIcons.resolve(c.iconKey), color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${item.credentialCount} '
                          '${item.credentialCount == 1 ? 'credential' : 'credentials'}'
                          '${c.isDefault ? ' · default' : ''}',
                          style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  if (!c.isDefault)
                    IconButton(
                      tooltip: 'Delete category',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _delete(context, ref, item),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
