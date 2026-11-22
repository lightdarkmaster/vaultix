import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/default_categories.dart';
import '../../../core/utils/exceptions.dart';
import '../../../core/utils/url_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../data/vault_providers.dart';
import '../domain/credential.dart';
import 'vault_state.dart';

/// Add (editId == null) or edit a credential.
class CredentialFormPage extends ConsumerStatefulWidget {
  const CredentialFormPage({super.key, this.editId});
  final int? editId;

  @override
  ConsumerState<CredentialFormPage> createState() => _CredentialFormPageState();
}

class _CredentialFormPageState extends ConsumerState<CredentialFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();

  List<Category> _categories = const [];
  int? _categoryId;
  bool _favorite = false;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _url, _username, _password, _tags, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await ref.read(categoriesProvider.future);
      _categories = [for (final c in cats) c.category];
      final otherId = _categories
          .where((c) => c.name == DefaultCategories.otherName)
          .map((c) => c.id)
          .firstOrNull;

      if (_editing) {
        final cred =
            await ref.read(credentialRepositoryProvider).get(widget.editId!);
        if (cred == null) {
          throw const ValidationException('This entry no longer exists');
        }
        final s = cred.summary;
        _title.text = s.title;
        _url.text = s.websiteUrl ?? '';
        _username.text = s.username ?? '';
        _password.text = cred.password;
        _tags.text = s.tags.join(', ');
        _notes.text = cred.notes ?? '';
        _categoryId = s.categoryId ?? otherId;
        _favorite = s.isFavorite;
      } else {
        _categoryId = otherId;
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e is ValidationException
            ? e.message
            : 'Could not load this entry.';
      });
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final url = normalizeWebUrl(_url.text);
    final draft = CredentialDraft(
      title: _title.text,
      password: _password.text,
      websiteUrl: url?.toString(),
      username: _username.text,
      categoryId: _categoryId,
      notes: _notes.text,
      tags: parseTagInput(_tags.text),
      isFavorite: _favorite,
    );
    try {
      final repo = ref.read(credentialRepositoryProvider);
      if (_editing) {
        await repo.update(widget.editId!, draft);
        ref.invalidate(credentialDetailProvider(widget.editId!));
      } else {
        await repo.add(draft);
      }
      refreshVault(ref);
      if (!mounted) return;
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pop();
        // Root messenger outlives this page.
      });
    } on ValidationException catch (e) {
      _showError(e.message);
    } on VaultLockedException {
      _showError('The vault is locked.');
    } catch (_) {
      _showError('Could not save this entry. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  void _pickCategory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final c in _categories)
            ListTile(
              leading: Icon(CategoryIcons.resolve(c.iconKey),
                  color: Color(c.color)),
              title: Text(c.name),
              trailing:
                  c.id == _categoryId ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                setState(() => _categoryId = c.id);
                _markDirty();
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  Widget _categoryField() {
    final selected = _categories.where((c) => c.id == _categoryId).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickCategory,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category',
          suffixIcon: Icon(Icons.expand_more_rounded),
        ),
        child: Row(
          children: [
            Icon(CategoryIcons.resolve(selected?.iconKey ?? 'other'),
                size: 20, color: Color(selected?.color ?? 0xFF8A8F9E)),
            const SizedBox(width: 10),
            Text(selected?.name ?? 'Choose a category'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Edit password' : 'Add password';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          message: _loadError!,
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                VaultixTextField(
                  controller: _title,
                  label: 'Website or app name',
                  icon: Icons.apps_rounded,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _markDirty(),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _url,
                  label: 'Website URL (optional)',
                  icon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _markDirty(),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    return normalizeWebUrl(t) == null
                        ? 'Enter a valid web address'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _username,
                  label: 'Username or email',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.key_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    _markDirty();
                    setState(() {}); // update the strength meter
                  },
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Enter a password' : null,
                ),
                PasswordStrengthMeter(password: _password.text),
                const SizedBox(height: 16),
                _categoryField(),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _tags,
                  label: 'Tags (comma separated)',
                  icon: Icons.sell_outlined,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 16),
                VaultixTextField(
                  controller: _notes,
                  label: 'Notes (encrypted)',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as favorite'),
                  value: _favorite,
                  onChanged: (v) {
                    setState(() => _favorite = v);
                    _markDirty();
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _editing ? 'Save changes' : 'Save password',
                  icon: Icons.check_rounded,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
