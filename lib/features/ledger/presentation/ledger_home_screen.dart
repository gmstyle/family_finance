import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';

/// Hub replacing the Phase 1/2 home placeholder — entry to ledger features.
class LedgerHomeScreen extends StatelessWidget {
  const LedgerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final tiles = [
      _HubTile(
        icon: Icons.receipt_long_outlined,
        title: l10n.transactionsTitle,
        subtitle: l10n.ledgerHubTransactionsSubtitle,
        onTap: () => context.go(AppRoutes.transactions),
      ),
      _HubTile(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.accountsTitle,
        subtitle: l10n.ledgerHubAccountsSubtitle,
        onTap: () => context.go(AppRoutes.accounts),
      ),
      _HubTile(
        icon: Icons.category_outlined,
        title: l10n.categoriesTitle,
        subtitle: l10n.ledgerHubCategoriesSubtitle,
        onTap: () => context.go(AppRoutes.categories),
      ),
      _HubTile(
        icon: Icons.swap_horiz,
        title: l10n.transferCreateTitle,
        subtitle: l10n.ledgerHubTransferSubtitle,
        onTap: () => context.push(AppRoutes.transferNew),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ledgerHomeTitle)),
      body: AppPage(
        padding: AppInsets.page,
        child: ListView(
          children: [
            Text(l10n.ledgerHomeBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            ...tiles.map(
              (tile) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: tile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: AppInsets.card,
          child: Row(
            children: [
              Icon(icon, size: AppSizes.avatar),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
