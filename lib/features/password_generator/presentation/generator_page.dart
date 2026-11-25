import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../settings/data/clipboard_provider.dart';
import 'generator_controls.dart';
import 'generator_state.dart';
import 'password_display.dart';

class GeneratorPage extends ConsumerWidget {
  const GeneratorPage({super.key});

  Future<void> _copy(BuildContext context, WidgetRef ref, String password) async {
    final service = ref.read(clipboardServiceProvider);
    await service.copy(password);
    if (!context.mounted) return;
    final secs = service.delaySeconds;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(secs > 0
            ? 'Password copied · clears in ${secs}s'
            : 'Password copied'),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generatorProvider);
    final notifier = ref.read(generatorProvider.notifier);
    final strength = estimatePasswordStrength(state.password);
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generator', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Random passwords made on this device.',
                    style: TextStyle(color: muted)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              cacheExtent: 300,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                AppConstants.floatingNavReserved + bottomPad,
              ),
              children: [
        VaultixCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordDisplay(password: state.password),
              const SizedBox(height: 8),
              PasswordStrengthMeter(password: state.password),
              const SizedBox(height: 6),
              Text('≈ ${strength.entropyBits.round()} bits of entropy',
                  style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copy(context, ref, state.password),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: notifier.regenerate,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Regenerate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const GeneratorControls(),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save to vault',
          icon: Icons.lock_rounded,
          onPressed: () => context.push('/vault/new', extra: state.password),
        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
