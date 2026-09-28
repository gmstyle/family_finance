/**
 * Ledger transaction image stored in `_projections/{transactionId}`
 * for idempotent apply (undo previous, apply new).
 */

export type TxType = "expense" | "income" | "refund" | "transfer";
export type TransferRole = "source" | "destination";

/** Fields that affect balance / budget / stats projections. */
export interface TransactionImage {
  type: TxType;
  accountId: string;
  categoryId: string | null;
  amountMinor: number;
  bookingDate: string;
  transferId: string | null;
  transferRole: TransferRole | null;
}

export interface StatsDelta {
  period: string;
  incomeByCategory: Record<string, number>;
  expenseByCategory: Record<string, number>;
  incomeByAccount: Record<string, number>;
  expenseByAccount: Record<string, number>;
  totalIncomeMinor: number;
  totalExpenseMinor: number;
}

export interface ThresholdCrossing {
  budgetId: string;
  periodId: string;
  crossed80: boolean;
  crossed100: boolean;
}
