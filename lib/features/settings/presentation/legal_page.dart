import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../domain/legal_content.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});
  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Text('Last updated ${AppInfo.legalLastUpdated}',
                style: TextStyle(fontSize: 12.5, color: muted)),
            const SizedBox(height: 14),
            Text(document.intro, style: const TextStyle(fontSize: 15.5, height: 1.5)),
            for (final section in document.sections) ...[
              const SizedBox(height: 24),
              Text(section.heading,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(section.body,
                  style: TextStyle(fontSize: 14.5, height: 1.55, color: scheme.onSurface.withValues(alpha: 0.85))),
            ],
          ],
        ),
      ),
    );
  }
}
