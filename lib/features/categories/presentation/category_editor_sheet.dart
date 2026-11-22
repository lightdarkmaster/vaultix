import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exceptions.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/category.dart';
import 'category_providers.dart';

const _categoryColors = <Color>[
  ...AppColors.accentOptions,
  Color(0xFF4C8DF6),
  Color(0xFFFF7A45),
  Color(0xFF9C6ADE),
  Color(0xFF8A8F9E),
];

/// Bottom sheet for creating (category == null) or editing a category.
class CategoryEditorSheet extends ConsumerStatefulWidget {
  const CategoryEditorSheet({super.key, this.category});
  final Category? category;

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  late final TextEditingController _name;
  late String _icon;
  late int _color;
  String? _error;
  bool _busy = false;

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _icon = c?.iconKey ?? 'folder';
    _color = c?.color ?? _categoryColors.first.toARGB32();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(categoryRepositoryProvider);
    try {
      if (_editing) {
        await repo.update(widget.category!.id,
            name: _name.text, iconKey: _icon, color: _color);
      } else {
        await repo.create(name: _name.text, iconKey: _icon, color: _color);
      }
      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.pop(context);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the category');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_color);
    final isDefault = widget.category?.isDefault ?? false;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 4, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_editing ? 'Edit category' : 'New category',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            enabled: !isDefault,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name',
              helperText: isDefault ? 'Default categories keep their name' : null,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Icon'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in CategoryIcons.all.entries)
                GestureDetector(
                  onTap: () => setState(() => _icon = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: e.key == _icon
                          ? accent.withValues(alpha: 0.2)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: e.key == _icon ? accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(e.value,
                        color: e.key == _icon ? accent : null, size: 24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Color'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in _categoryColors)
                GestureDetector(
                  onTap: () => setState(() => _color = c.toARGB32()),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.toARGB32() == _color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: c.toARGB32() == _color
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _editing ? 'Save changes' : 'Create category',
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
