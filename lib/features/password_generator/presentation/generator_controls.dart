import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/vaultix_card.dart';
import '../domain/password_generator.dart';
import 'generator_state.dart';

/// Length slider and character-type switches shared by the Generator tab and
/// the "Generate" sheet in the password form.
class GeneratorControls extends ConsumerWidget {
  const GeneratorControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(generatorProvider).options;
    final notifier = ref.read(generatorProvider.notifier);

    // The last remaining character type can't be switched off.
    bool? lockedOn(bool value) => value && options.activePoolCount == 1;

    Widget toggle(
      String title,
      String subtitle,
      bool value,
      GeneratorOptions Function(bool) apply,
    ) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: lockedOn(value) == true
            ? null
            : (v) => notifier.update(apply(v)),
      );
    }

    return VaultixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Length')),
              Text('${options.length}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Slider(
            min: GeneratorOptions.minLength.toDouble(),
            max: GeneratorOptions.maxLength.toDouble(),
            divisions: GeneratorOptions.maxLength - GeneratorOptions.minLength,
            value: options.length.toDouble(),
            label: '${options.length}',
            onChanged: (v) => notifier.update(options.copyWith(length: v.round())),
          ),
          toggle('Uppercase', 'A–Z', options.upper,
              (v) => options.copyWith(upper: v)),
          toggle('Lowercase', 'a–z', options.lower,
              (v) => options.copyWith(lower: v)),
          toggle('Numbers', '0–9', options.digits,
              (v) => options.copyWith(digits: v)),
          toggle('Special characters', r'!@#$%^&*',
              options.symbols, (v) => options.copyWith(symbols: v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exclude similar characters'),
            subtitle: const Text('Skips I, l, 1, L, |, O, 0, o'),
            value: options.excludeSimilar,
            onChanged: (v) => notifier.update(options.copyWith(excludeSimilar: v)),
          ),
        ],
      ),
    );
  }
}
