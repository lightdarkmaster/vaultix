import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vaultix_card.dart';
import '../../../categories/domain/category.dart';
import '../../domain/credential.dart';
import 'credential_avatar.dart';

class CredentialTile extends StatelessWidget {
  const CredentialTile({
    super.key,
    required this.credential,
    required this.category,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final CredentialSummary credential;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category != null ? Color(category!.color) : scheme.primary;
    final subtitle = (credential.username?.isNotEmpty ?? false)
        ? credential.username!
        : (credential.websiteUrl ?? 'No username');
    return VaultixCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: onTap,
      child: Row(
        children: [
          CredentialAvatar(title: credential.title, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(credential.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          IconButton(
            tooltip: credential.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: onToggleFavorite,
            icon: Icon(
              credential.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: credential.isFavorite ? AppColors.warning : null,
            ),
          ),
        ],
      ),
    );
  }
}
