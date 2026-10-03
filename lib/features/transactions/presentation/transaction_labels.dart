import '../../../l10n/app_localizations.dart';
import '../domain/transaction.dart';

String transactionTypeLabel(AppLocalizations l10n, TransactionType type) {
  return switch (type) {
    TransactionType.expense => l10n.transactionTypeExpense,
    TransactionType.income => l10n.transactionTypeIncome,
    TransactionType.refund => l10n.transactionTypeRefund,
    TransactionType.transfer => l10n.transactionTypeTransfer,
  };
}
