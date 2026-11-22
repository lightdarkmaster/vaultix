import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

/// Phase 1 shell. The generator is built in Phase 7.
class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.password_rounded,
      title: 'Password generator',
      message: 'Secure password generation arrives in Phase 7.',
    );
  }
}
