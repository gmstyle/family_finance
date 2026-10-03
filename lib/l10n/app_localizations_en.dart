// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Finance';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navCategories => 'Categories';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italian';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Unarchive';

  @override
  String get actionLoadMore => 'Load more';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClearFilters => 'Clear filters';

  @override
  String get moneyInvalid => 'Enter a valid amount';

  @override
  String get ledgerErrorTitle => 'Something went wrong';

  @override
  String get ledgerNotFound => 'Item not found';

  @override
  String get ledgerHomeTitle => 'Ledger';

  @override
  String get ledgerHomeBody =>
      'Manage shared accounts, categories, and transactions.';

  @override
  String get ledgerHubTransactionsSubtitle =>
      'Expenses, income, refunds, and transfers';

  @override
  String get ledgerHubAccountsSubtitle => 'Balances and opening amounts';

  @override
  String get ledgerHubCategoriesSubtitle => 'System and custom categories';

  @override
  String get ledgerHubTransferSubtitle => 'Move money between accounts';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsEmpty =>
      'No accounts yet. Create one to start tracking balances.';

  @override
  String get accountsArchived => 'Archived';

  @override
  String get accountCreateTitle => 'New account';

  @override
  String get accountEditTitle => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameInvalid => 'Enter at least 2 characters';

  @override
  String get accountType => 'Account type';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCard => 'Card';

  @override
  String get accountTypeWallet => 'Wallet';

  @override
  String get accountOpeningBalance => 'Opening balance';

  @override
  String get accountOpeningDate => 'Opening date';

  @override
  String accountBalanceHint(String amount) {
    return 'Current balance: $amount';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmpty => 'No categories yet.';

  @override
  String get categoriesShowArchived => 'Show archived';

  @override
  String get categoryCreateTitle => 'New category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryType => 'Type';

  @override
  String get categoryTypeExpense => 'Expense';

  @override
  String get categoryTypeIncome => 'Income';

  @override
  String get categoryTypeImmutableHint =>
      'Type cannot be changed after creation.';

  @override
  String get categorySystemBadge => 'System';

  @override
  String get categoryCustomBadge => 'Custom';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsEmpty => 'No transactions match these filters.';

  @override
  String get transactionsFilters => 'Filters';

  @override
  String get filterAccount => 'Account';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterMember => 'Member';

  @override
  String get filterDateFrom => 'From date';

  @override
  String get filterDateTo => 'To date';

  @override
  String get filterAll => 'All';

  @override
  String get transactionCreateTitle => 'New transaction';

  @override
  String get transactionEditTitle => 'Edit transaction';

  @override
  String get transactionType => 'Type';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeRefund => 'Refund';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionBookingDate => 'Booking date';

  @override
  String get transactionMerchant => 'Merchant';

  @override
  String get transactionNote => 'Note';

  @override
  String get transactionFormIncomplete => 'Select account and category';

  @override
  String get transactionDeleteTitle => 'Delete transaction?';

  @override
  String get transactionDeleteBody =>
      'This removes the transaction from the shared ledger.';

  @override
  String get transferCreateTitle => 'Transfer';

  @override
  String get transferCreateBody =>
      'Creates two linked movements. They are deleted together.';

  @override
  String get transferSourceAccount => 'From account';

  @override
  String get transferDestinationAccount => 'To account';

  @override
  String get transferAccountsInvalid => 'Choose two different accounts';

  @override
  String get transferDeleteBody => 'Deletes both legs of this transfer.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authDisplayName => 'Display name';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNeedAccount => 'Need an account? Register';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSendReset => 'Send reset link';

  @override
  String get authResetSent => 'Check your inbox for the password reset link.';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailBody(String email) {
    return 'We sent a verification link to $email. Open it, then tap below.';
  }

  @override
  String get authIVerified => 'I verified my email';

  @override
  String get authResendVerification => 'Resend verification email';

  @override
  String get familyTitle => 'Family';

  @override
  String get familyCreateTitle => 'Create your family';

  @override
  String get familyCreateBody =>
      'A shared ledger starts with a family. Currency cannot be changed later.';

  @override
  String get familyName => 'Family name';

  @override
  String get familyNameInvalid => 'Enter at least 2 characters';

  @override
  String get familyCurrencyHint =>
      'Currency is set to EUR for this MVP and is immutable.';

  @override
  String get familyCreateAction => 'Create family';

  @override
  String get familyOrAcceptInvite => 'Or open an invite link you received.';

  @override
  String get familyMissing => 'You are not in a family yet.';

  @override
  String get familyMembers => 'Members';

  @override
  String get familyInvites => 'Invites';

  @override
  String get familyInviteEmail => 'Invite by email';

  @override
  String get familyInviteCopied => 'Invite link copied to clipboard';

  @override
  String get familyInviteLinkHint =>
      'Share this link (emulator: copy manually)';

  @override
  String get familyMakeAdmin => 'Make admin';

  @override
  String get familyMakeMember => 'Make member';

  @override
  String get familyTransferOwnership => 'Transfer ownership';

  @override
  String get familyRemoveMember => 'Remove';

  @override
  String get familyLeaveTitle => 'Leave family?';

  @override
  String get familyLeaveBody =>
      'You will lose access until invited again. Last admin must promote someone first.';

  @override
  String get familyLeaveAction => 'Leave family';

  @override
  String get inviteAcceptTitle => 'Family invite';

  @override
  String get inviteAcceptBody =>
      'Accept this invite to join the shared family ledger.';

  @override
  String get inviteAcceptAction => 'Accept invite';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFamily => 'Manage family';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryOtherExpense => 'Other expense';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryOtherIncome => 'Other income';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardPeriodLabel(String period) {
    return 'Period $period';
  }

  @override
  String get dashboardTotalIncome => 'Income';

  @override
  String get dashboardTotalExpense => 'Expenses';

  @override
  String get dashboardNet => 'Net';

  @override
  String get dashboardExpensesByCategory => 'Expenses by category';

  @override
  String get dashboardIncomeByCategory => 'Income by category';

  @override
  String get dashboardNoExpenses => 'No expenses this period yet.';

  @override
  String get dashboardNoIncome => 'No income this period yet.';

  @override
  String get dashboardQuickLinks => 'Quick links';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsEmpty =>
      'No budgets yet. Set a monthly limit for an expense category.';

  @override
  String get budgetCreateTitle => 'New budget';

  @override
  String get budgetEditTitle => 'Edit budget';

  @override
  String get budgetCategory => 'Category';

  @override
  String get budgetCategoryRequired => 'Select an expense category';

  @override
  String get budgetCategoryImmutableHint =>
      'Category cannot be changed after creation.';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String budgetPeriodLabel(String period) {
    return '$period';
  }

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get budgetAlert80 => '80% of budget reached';

  @override
  String get budgetAlert100 => 'Budget limit reached';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsEmpty =>
      'No goals yet. Create one and track virtual contributions.';

  @override
  String get goalCreateTitle => 'New goal';

  @override
  String get goalEditTitle => 'Edit goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalNameInvalid => 'Enter at least 2 characters';

  @override
  String get goalTargetAmount => 'Target amount';

  @override
  String get goalDueDate => 'Due date';

  @override
  String get goalDueDateOptional => 'Optional';

  @override
  String goalDueDateLabel(String date) {
    return 'Due $date';
  }

  @override
  String goalProgressLabel(String accumulated, String target) {
    return '$accumulated of $target';
  }

  @override
  String goalAccumulatedHint(String amount) {
    return 'Accumulated (server): $amount';
  }

  @override
  String get goalContributeTitle => 'Contribute';

  @override
  String get goalContributeAction => 'Deposit / withdraw';

  @override
  String get goalContributeHint =>
      'Virtual only — does not change account balances.';

  @override
  String get goalDeposit => 'Deposit';

  @override
  String get goalWithdraw => 'Withdraw';

  @override
  String get goalContributionsTitle => 'Recent contributions';

  @override
  String get goalContributionsEmpty => 'No contributions yet.';
}
