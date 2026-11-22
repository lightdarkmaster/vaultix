import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/password_strength.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import 'generator_controls.dart';
import 'generator_state.dart';
import 'password_display.dart';

/// Bottom sheet used by the password form. Returns the chosen password, or
/// null if dismissed.
Future<String?> showGeneratorSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _GeneratorSheet(),
  );
}

class _GeneratorSheet extends ConsumerWidget {
  const _GeneratorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generatorProvider);
    final strength = estimatePasswordStrength(state.password);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Generate password',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: PasswordDisplay(password: state.password, fontSize: 20)),
              IconButton(
                tooltip: 'Regenerate',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: ref.read(generatorProvider.notifier).regenerate,
              ),
            ],
          ),
          PasswordStrengthMeter(password: state.password),
          const SizedBox(height: 4),
          Text('≈ ${strength.entropyBits.round()} bits of entropy',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55))),
          const SizedBox(height: 16),
          const GeneratorControls(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Use this password',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context, state.password),
          ),
        ],
      ),
    );
  }
}
