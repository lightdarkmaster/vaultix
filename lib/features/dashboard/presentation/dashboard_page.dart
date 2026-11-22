import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';

/// Phase 1 shell. The real dashboard is built in Phase 5.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.shield_rounded,
      title: AppConstants.appName,
      message: '${AppConstants.tagline}\n\nDashboard arrives in Phase 5.',
    );
  }
}
