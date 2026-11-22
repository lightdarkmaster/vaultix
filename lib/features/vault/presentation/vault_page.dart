import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

/// Phase 1 shell. Vault CRUD is built in Phase 6.
class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_rounded,
      title: 'Your vault',
      message: 'Saved credentials will appear here (Phase 6).',
    );
  }
}
