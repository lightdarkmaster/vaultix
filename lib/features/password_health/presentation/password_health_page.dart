import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/score_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../vault/domain/credential.dart';
import '../../vault/presentation/widgets/credential_avatar.dart';
import '../domain/password_health.dart';
import '../domain/recommendations.dart';
import 'health_providers.dart';

class PasswordHealthPage extends ConsumerWidget {
  const PasswordHealthPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(healthEntriesProvider);
    ref.invalidate(passwordHealthProvider);
    await ref.read(passwordHealthProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(passwordHealthProvider);
    final entries = ref.watch(healthEntriesProvider).valueOrNull ??
        const <int, CredentialSummary>{};
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final byCategory = {for (final c in cats) c.category.id: c.category};

    return Scaffold(
      appBar: AppBar(title: const Text('Password health')),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not analyse your passwords',
          message: 'Something went wrong. Pull down or try again.',
          actionLabel: 'Try again',
          onAction: () => _refresh(ref),
        ),
        data: (r) {
          if (r.total == 0) {
            return EmptyState(
              icon: Icons.shield_outlined,
              title: 'Nothing to check yet',
              message: 'Add some passwords and Vaultix will analyse them here.',
              actionLabel: 'Add password',
              onAction: () => context.push('/vault/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: _Body(report: r, entries: entries, categories: byCategory),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.report,
    required this.entries,
    required this.categories,
  });

  final HealthReport report;
  final Map<int, CredentialSummary> entries;
  final Map<int, Category> categories;

  String _age(DateTime changed) {
    final days = DateTime.now().difference(changed).inDays;
    if (days >= 365) {
      final y = days ~/ 365;
      return 'Changed $y year${y == 1 ? '' : 's'} ago';
    }
    if (days >= 30) {
      final m = days ~/ 30;
      return 'Changed $m month${m == 1 ? '' : 's'} ago';
    }
    return 'Changed $days day${days == 1 ? '' : 's'} ago';
  }

  String _who(CredentialSummary s) =>
      (s.username?.isNotEmpty ?? false) ? s.username! : (s.websiteUrl ?? ' ');

  List<int> _sortedByTitle(Iterable<int> ids) {
    final list = ids.where(entries.containsKey).toList();
    list.sort((a, b) => entries[a]!.title
        .toLowerCase()
        .compareTo(entries[b]!.title.toLowerCase()));
    return list;
  }

  Widget _tile(
    BuildContext context,
    int id,
    String Function(CredentialSummary) subtitle,
  ) {
    final s = entries[id];
    if (s == null) return const SizedBox.shrink();
    final cat = categories[s.categoryId];
    final color =
        cat != null ? Color(cat.color) : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _HealthTile(
        title: s.title,
        subtitle: subtitle(s),
        color: color,
        onTap: () => context.push('/vault/$id/edit'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final score = report.score ?? 0;
    final recs = buildRecommendations(report);

    final weak = _sortedByTitle(report.weakIds);
    final oldIds = report.oldIds.where(entries.containsKey).toList()
      ..sort((a, b) => entries[a]!.passwordUpdatedAt
          .compareTo(entries[b]!.passwordUpdatedAt));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        VaultixCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ScoreRing(score: score, size: 112),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.scoreLabel,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ScoreRing.colorFor(score))),
                    const SizedBox(height: 4),
                    Text('${report.total} '
                        '${report.total == 1 ? 'password' : 'passwords'} analysed'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14, color: muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Checked on this device only',
                              style: TextStyle(fontSize: 12, color: muted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CountsGrid(report: report),
        const SizedBox(height: 8),

        const SectionHeader(title: 'Recommendations'),
        for (final rec in recs) _RecommendationCard(rec),

        if (weak.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(title: 'Weak passwords (${weak.length})'),
          for (final id in weak)
            _tile(context, id, (s) => _who(s)),
        ],

        if (report.reuseGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(title: 'Reused passwords (${report.reusedCount})'),
          for (final group in report.reuseGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text('Same password on ${group.length} accounts',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning)),
            ),
            for (final id in _sortedByTitle(group)) _tile(context, id, _who),
            const SizedBox(height: 6),
          ],
        ],

        if (oldIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(title: 'Old passwords (${oldIds.length})'),
          for (final id in oldIds)
            _tile(context, id, (s) => _age(s.passwordUpdatedAt)),
        ],
      ],
    );
  }
}

class _CountsGrid extends StatelessWidget {
  const _CountsGrid({required this.report});
  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        Widget tile(String label, int value, Color color, IconData icon) =>
            SizedBox(
              width: width,
              child: VaultixCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$value',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(label, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            tile('Strong', report.strongCount, AppColors.success,
                Icons.verified_rounded),
            tile('Weak', report.weakCount, AppColors.error,
                Icons.warning_amber_rounded),
            tile('Reused', report.reusedCount, AppColors.warning,
                Icons.content_copy_rounded),
            tile('Old', report.oldCount, AppColors.secondary,
                Icons.history_rounded),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard(this.rec);
  final Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (rec.severity) {
      RecommendationSeverity.high => (AppColors.error, Icons.priority_high_rounded),
      RecommendationSeverity.medium =>
        (AppColors.warning, Icons.warning_amber_rounded),
      RecommendationSeverity.low =>
        (AppColors.secondary, Icons.lightbulb_outline_rounded),
      RecommendationSeverity.good =>
        (AppColors.success, Icons.check_circle_outline_rounded),
    };
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VaultixCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(rec.message,
                      style: TextStyle(fontSize: 13, height: 1.35, color: muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return VaultixCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: onTap,
      child: Row(
        children: [
          CredentialAvatar(title: title, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Text('Update',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
          Icon(Icons.chevron_right_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}
