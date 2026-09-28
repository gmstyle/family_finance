import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Shared loading / error / empty body for ledger lists.
class LedgerAsyncBody extends StatelessWidget {
  const LedgerAsyncBody({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
    this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: AppInsets.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ledgerErrorTitle,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
              ],
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: AppInsets.page,
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return child;
  }
}
