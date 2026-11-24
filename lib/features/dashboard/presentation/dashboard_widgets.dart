import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../categories/domain/category.dart';
import '../../password_health/domain/password_health.dart';
import '../../vault/domain/credential.dart';
import '../../vault/presentation/widgets/credential_avatar.dart';

String plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
    return VaultixCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    );
  }
}

class CredentialMiniList extends StatelessWidget {
  const CredentialMiniList({
    super.key,
    required this.items,
    required this.categories,
    required this.onOpen,
  });

  final List<CredentialSummary> items;
  final Map<int, Category> categories;
  final void Function(CredentialSummary) onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = items[i];
          final cat = categories[c.categoryId];
          final color = cat != null ? Color(cat.color) : scheme.primary;
          return SizedBox(
            width: 160,
            child: VaultixCard(
              padding: const EdgeInsets.all(12),
              onTap: () => onOpen(c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CredentialAvatar(title: c.title, color: color, size: 38),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        (c.username?.isNotEmpty ?? false) ? c.username! : (c.websiteUrl ?? ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SecurityOverviewCard extends StatelessWidget {
  const SecurityOverviewCard({super.key, required this.report, this.onTap});
  final AsyncValue<HealthReport> report;
  final VoidCallback? onTap;

  Color _scoreColor(int score) => score >= 80
      ? AppColors.success
      : score >= 50
          ? AppColors.warning
          : AppColors.error;

  String _tip(HealthReport r) {
    if (r.weakCount > 0) return 'Update your ${plural(r.weakCount, 'weak password')} first.';
    if (r.reusedCount > 0) {
      return '${plural(r.reusedCount, 'password')} ${r.reusedCount == 1 ? 'is' : 'are'} reused. Use a unique one for each account.';
    }
    if (r.oldCount > 0) {
      return '${plural(r.oldCount, 'password')} ${r.oldCount == 1 ? 'has' : 'have'} not changed in over 6 months.';
    }
    return 'Your passwords look healthy. Nice work.';
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
    return VaultixCard(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: report.when(
        loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => Text('Could not analyse your passwords right now.', style: TextStyle(color: muted)),
        data: (r) {
          final score = r.score;
          if (score == null) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Add passwords to see your security score.', style: TextStyle(color: muted))),
              ],
            );
          }
          final color = _scoreColor(score);
          return Row(
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: score / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        Text('score', style: TextStyle(fontSize: 10, color: muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.scoreLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill('${r.strongCount} strong', AppColors.success),
                        _Pill('${r.weakCount} weak', AppColors.error),
                        _Pill('${r.reusedCount} reused', AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_tip(r), style: TextStyle(fontSize: 12.5, color: muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return VaultixCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.18), primary.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
