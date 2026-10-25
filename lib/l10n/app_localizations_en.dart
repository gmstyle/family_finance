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
  String get navHome => 'Dashboard';

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
  String get navReview => 'Review';

  @override
  String get navBudgetGoals => 'Budget & Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get shellBrandTagline => 'Kinship Stewardship';

  @override
  String get shellActiveFamily => 'Active family';

  @override
  String get shellSettingsMembers => 'Settings / Members';

  @override
  String get shellSearchHint => 'Search transactions, notes, or categories…';

  @override
  String get shellExport => 'Export';

  @override
  String get shellNotifications => 'Notifications';

  @override
  String get shellAddExpense => 'Add expense';

  @override
  String get shellAddTransaction => 'Log expense';

  @override
  String get shellScanReceipt => 'Scan receipt';

  @override
  String get budgetGoalsTabBudgets => 'Monthly budgets';

  @override
  String get budgetGoalsTabGoals => 'Shared goals';

  @override
  String get budgetGoalsEyebrow => 'Shared overview';

  @override
  String get budgetGoalsHeadline => 'Budget & Savings';

  @override
  String get budgetGoalsEyebrowWeb => 'Shared household planning';

  @override
  String get budgetGoalsHeadlineWeb => 'Family budget & goals';

  @override
  String get budgetTotalHouseholdSpend => 'Total household spend';

  @override
  String budgetAvailableLabel(String amount) {
    return 'Available: $amount';
  }

  @override
  String budgetDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '$count day left',
      zero: 'No days left',
    );
    return '$_temp0';
  }

  @override
  String budgetPercentUsed(int percent) {
    return '$percent%';
  }

  @override
  String budgetSpentPercent(int percent) {
    return '$percent% spent';
  }

  @override
  String budgetRemainingLabel(String amount) {
    return 'Left: $amount';
  }

  @override
  String budgetOfLimitSuffix(String limit) {
    return 'of $limit';
  }

  @override
  String get budgetCategoriesSection => 'Spending categories';

  @override
  String get budgetCategoriesSectionWeb => 'Spending category monitoring';

  @override
  String get budgetEditLimits => 'Edit limits';

  @override
  String get budgetCreateBudgetOrGoal => 'Create new budget or goal';

  @override
  String get budgetCreateBudgetChoice => 'New budget';

  @override
  String get budgetCreateGoalChoice => 'New goal';

  @override
  String budgetNearLimitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count near limit',
      one: '$count near limit',
    );
    return '$_temp0';
  }

  @override
  String get budgetResidueMonth => 'Month remaining';

  @override
  String get budgetResidueAvailable => 'Available';

  @override
  String get budgetDailyAllowance => 'Allowed spend';

  @override
  String get budgetDailyTarget => 'Daily target';

  @override
  String budgetDailyPerDay(String amount) {
    return '$amount / day';
  }

  @override
  String budgetPercentUtilized(int percent) {
    return '$percent% used';
  }

  @override
  String budgetMarginRemaining(String amount, int percent) {
    return 'Remaining margin: $amount ($percent%)';
  }

  @override
  String get budgetNewCategoryTitle => 'New category';

  @override
  String get budgetNewCategoryBody => 'Add a spending limit';

  @override
  String get budgetCreateNow => 'Create now';

  @override
  String get goalsSavingBanner =>
      'You\'re saving together toward your family goals.';

  @override
  String get goalsNextPromptTitle => 'Next goal?';

  @override
  String get goalsNextPromptBody => 'Add a new shared milestone';

  @override
  String get goalsExplore => 'Explore';

  @override
  String get goalAddFunds => 'Add funds';

  @override
  String goalProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italian';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionContinue => 'Continue';

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
  String get ledgerBookTitle => 'Family Ledger';

  @override
  String ledgerExpensesMonth(String month) {
    return '$month expenses';
  }

  @override
  String get ledgerIncomeTotal => 'Total income';

  @override
  String get ledgerMonthlyOutflows => 'Monthly outflows';

  @override
  String get ledgerMonthlyInflows => 'Monthly income';

  @override
  String get ledgerNetSavings => 'Net savings';

  @override
  String get ledgerDataIntegrity => 'Data integrity';

  @override
  String get ledgerRegistered => 'Logged';

  @override
  String get ledgerSearchPlaceholder => 'Search merchant, note, amount…';

  @override
  String get ledgerAllMembers => 'All members';

  @override
  String ledgerMemberOnly(String name) {
    return 'Only $name';
  }

  @override
  String get ledgerThisMonth => 'This month';

  @override
  String get ledgerAllAccounts => 'All accounts';

  @override
  String get ledgerUnifiedFinance => 'Unified financial management';

  @override
  String ledgerFiscalYear(String year) {
    return 'Fiscal year $year';
  }

  @override
  String ledgerInReview(int count) {
    return '$count in review';
  }

  @override
  String ledgerDayToday(String date) {
    return 'Today, $date';
  }

  @override
  String ledgerDayYesterday(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get ledgerSortNewest => 'Sorted by: newest first';

  @override
  String ledgerShownOf(int shown, int total) {
    return 'Showing $shown of $total';
  }

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
  String get familyInviteEmailSent =>
      'Invite email sent. Link also copied to clipboard.';

  @override
  String get familyInviteCreatedCopyLink =>
      'Invite created. Link copied (email not sent — configure SMTP on createInvite).';

  @override
  String get familyInviteLinkHint => 'Universal invite link (web and Android)';

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
  String get inviteAcceptUseInvitedEmail =>
      'Sign in or register with the same email address that received the invite.';

  @override
  String inviteAcceptSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFamily => 'Manage family';

  @override
  String get settingsPrivacyData => 'Privacy & data';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyLoadError => 'Could not load the privacy policy.';

  @override
  String get settingsExportData => 'Export family data';

  @override
  String get settingsExportDataHint =>
      'Download a JSON copy of the data you can read in this family.';

  @override
  String get settingsExportDone =>
      'Export ready — choose an app to save or share it.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountHint =>
      'Permanently delete your account and sign-in credentials.';

  @override
  String get settingsDeleteAccountTitle => 'Delete your account?';

  @override
  String get settingsDeleteAccountBody =>
      'This cannot be undone. You will be signed out and your Auth account will be removed.';

  @override
  String get settingsDeleteAccountSoleTitle =>
      'Delete account and family data?';

  @override
  String get settingsDeleteAccountSoleBody =>
      'You are the only member of this family. Deleting your account will permanently erase the entire family ledger (accounts, transactions, budgets, goals, drafts). This cannot be undone.';

  @override
  String get settingsDeleteAccountConfirmAction => 'Delete permanently';

  @override
  String get settingsDeleteReauthTitle => 'Confirm it is you';

  @override
  String get settingsDeleteReauthPassword => 'Enter your password to continue';

  @override
  String get settingsDeleteReauthGoogle => 'Continue with Google to confirm';

  @override
  String get settingsDeleteFailedPromote =>
      'Promote another admin before deleting your account (or leave the family first).';

  @override
  String get settingsDeleteFailedTransfer =>
      'Transfer ownership before deleting your account (or leave the family first).';

  @override
  String get settingsDeleteFailedGeneric =>
      'Could not delete the account. Check family membership and try again.';

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
  String dashboardGreetingHi(String name) {
    return 'Hi $name!';
  }

  @override
  String dashboardGreetingWelcome(String name) {
    return 'Welcome back, $name';
  }

  @override
  String dashboardCurrentMonth(String month) {
    return 'Current month • $month';
  }

  @override
  String get dashboardTotalBalance => 'Family total balance';

  @override
  String dashboardNetSavings(String amount, String percent) {
    return 'Net savings: $amount ($percent%)';
  }

  @override
  String get dashboardIncomeMonth => 'Month income';

  @override
  String get dashboardExpenseMonth => 'Month expenses';

  @override
  String dashboardReviewCount(int count) {
    return '$count to review';
  }

  @override
  String get dashboardReviewActionBadge => 'Action';

  @override
  String get dashboardReviewNow => 'Review now';

  @override
  String get dashboardReviewSubtitle =>
      'Drafts from wallets and receipt scans awaiting confirmation.';

  @override
  String get dashboardAccountsSection => 'Family accounts & cards';

  @override
  String get dashboardManage => 'Manage';

  @override
  String dashboardBudgetOfMonth(String month) {
    return '$month budget';
  }

  @override
  String dashboardSeeAllCount(int count) {
    return 'See all ($count)';
  }

  @override
  String get dashboardRecentTransactions => 'Recent transactions';

  @override
  String get dashboardSeeAll => 'All';

  @override
  String dashboardActiveMembers(int count) {
    return '$count active';
  }

  @override
  String get dashboardPatrimony => 'Household wealth';

  @override
  String dashboardIncomeForMonth(String month) {
    return '$month income';
  }

  @override
  String get dashboardMonthlyOutflows => 'Monthly outflows';

  @override
  String get dashboardSmartReview => 'Smart review';

  @override
  String dashboardReviewValidate(int count) {
    return '$count transactions to validate';
  }

  @override
  String get dashboardReviewCta => 'Review now';

  @override
  String get dashboardCashflowTitle => 'Cashflow trend';

  @override
  String get dashboardCashflowPlaceholder =>
      'Weekly cashflow chart coming soon — month totals are in the KPIs above.';

  @override
  String get dashboardBudgetMonitor => 'Category budget monitor';

  @override
  String get dashboardQuickQueue => 'Quick queue';

  @override
  String get dashboardQuickQueueEmpty => 'No drafts to review.';

  @override
  String get dashboardQuickQueueHint =>
      'Transactions captured automatically from payment gateways.';

  @override
  String get dashboardLinkedAccounts => 'Linked accounts';

  @override
  String get dashboardLinkAccount => 'Link a new account';

  @override
  String get dashboardSavingsGoals => 'Savings goals';

  @override
  String get dashboardViewAllTransactions => 'View full transaction ledger';

  @override
  String get dashboardBudgetPreset => 'Budget target';

  @override
  String dashboardSpentPercent(String percent) {
    return '$percent% spent';
  }

  @override
  String dashboardUsedPercent(String percent) {
    return '$percent% used';
  }

  @override
  String dashboardRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get dashboardAttentionThreshold => 'Attention threshold';

  @override
  String get dashboardNoAccounts => 'No accounts yet.';

  @override
  String get dashboardNoRecentTx => 'No recent transactions.';

  @override
  String get dashboardNoGoals => 'No savings goals yet.';

  @override
  String get dashboardAvailableBalance => 'Available balance';

  @override
  String get dashboardPrimaryAccount => 'Primary';

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
  String get budgetPeriodPrevious => 'Previous month';

  @override
  String get budgetPeriodNext => 'Next month';

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

  @override
  String get ingestionTitle => 'Review queue';

  @override
  String get ingestionEmpty =>
      'No drafts to review. Scan a receipt on Android to add one.';

  @override
  String get ingestionReviewTitle => 'Review draft';

  @override
  String get ingestionUnknownMerchant => 'Unknown merchant';

  @override
  String get ingestionStatusNeedsReview => 'Needs review';

  @override
  String get ingestionStatusPossibleDuplicate => 'Possible duplicate';

  @override
  String get ingestionSourceReceiptOcr => 'Receipt scan';

  @override
  String get ingestionSourceNotification => 'Notification';

  @override
  String get ingestionPossibleDuplicateHint =>
      'A similar transaction may already exist. Review carefully before confirming.';

  @override
  String get ingestionConfirmAction => 'Confirm transaction';

  @override
  String get ingestionPeriodMismatchTitle => 'Date outside current month';

  @override
  String ingestionPeriodMismatchBody(
    String bookingDate,
    String bookingPeriod,
    String currentPeriod,
  ) {
    return 'The receipt is dated $bookingDate: it will count toward the $bookingPeriod budget, not $currentPeriod that you are viewing.';
  }

  @override
  String get ingestionUseReceiptDate => 'Use receipt date';

  @override
  String get ingestionUseTodayDate => 'Use today\'s date';

  @override
  String get ingestionDiscardAction => 'Discard';

  @override
  String get ingestionDiscardTitle => 'Discard draft?';

  @override
  String get ingestionDiscardBody =>
      'This draft will be discarded. No transaction will be created.';

  @override
  String get ingestionSaveMerchantRule =>
      'Remember category and account for this merchant';

  @override
  String get ingestionSaveMerchantRuleHint =>
      'Used as suggestions the next time this merchant appears.';

  @override
  String get ingestionOpenQueue => 'Open review queue';

  @override
  String ingestionPendingCount(int count) {
    return '$count pending';
  }

  @override
  String ingestionFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String ingestionFilterNotification(int count) {
    return 'Notifications ($count)';
  }

  @override
  String ingestionFilterOcr(int count) {
    return 'Receipt OCR ($count)';
  }

  @override
  String ingestionFilterDuplicates(int count) {
    return 'Possible duplicates ($count)';
  }

  @override
  String get ingestionConfirmLedger => 'Confirm to ledger';

  @override
  String get ingestionEmptyDoneTitle => 'All clear!';

  @override
  String get ingestionEmptyDoneBody =>
      'No drafts waiting. The family ledger is up to date.';

  @override
  String get ingestionEmptyGoDashboard => 'Back to Dashboard';

  @override
  String get ingestionSettingsCapture => 'Notification & OCR capture settings';

  @override
  String get ingestionUnreconciledTitle => 'Unreconciled items';

  @override
  String get ingestionSortedByDate => 'Sorted by date';

  @override
  String get ingestionSelectDraftHint => 'Select a draft to verify and confirm';

  @override
  String get ingestionReviewVerifyTitle => 'Verify & assign expense';

  @override
  String get ingestionInReview => 'In review';

  @override
  String get ingestionToConfirm => 'To confirm';

  @override
  String get ingestionWebEyebrow => 'Staging & AI reconciliation';

  @override
  String get receiptScanTitle => 'Scan receipt';

  @override
  String get receiptScanAction => 'Scan receipt';

  @override
  String get receiptScanBody =>
      'Take a photo or choose an image. The app extracts amount, date, and merchant into a draft you must confirm — nothing is posted silently.';

  @override
  String get receiptScanCamera => 'Take photo';

  @override
  String get receiptScanGallery => 'Choose from gallery';

  @override
  String get receiptScanProcessing => 'Reading receipt…';

  @override
  String get receiptScanAndroidOnlyTitle => 'Receipt scan is Android-only';

  @override
  String get receiptScanAndroidOnlyBody =>
      'On-device OCR runs only on Android. You can still review and confirm drafts from the queue on this device.';

  @override
  String get receiptScanAndroidOnlyBanner =>
      'Receipt scanning is available on Android. You can review drafts here.';

  @override
  String get notificationListenerTitle => 'Payment notification capture';

  @override
  String get notificationListenerEnabled =>
      'Listener enabled — Wallet notifications create review drafts';

  @override
  String get notificationListenerDisabled =>
      'Listener off — tap to enable in system settings';

  @override
  String get notificationListenerAndroidOnly =>
      'Payment notification capture is available on Android only. You can still review drafts here.';

  @override
  String get notificationListenerOpenSettings =>
      'Open notification access settings';

  @override
  String notificationDraftAlertTitle(int count) {
    return '$count drafts to review';
  }

  @override
  String get notificationDraftAlertBody =>
      'Open the review queue to confirm or discard. Nothing is posted without your confirmation.';

  @override
  String get accountBindingsTitle => 'Notification account bindings';

  @override
  String get accountBindingsHint =>
      'Suggest a default account when a draft is created from each app’s notifications. You can still change the account before confirming.';

  @override
  String get accountBindingsEmpty => 'No notification packages configured.';

  @override
  String get accountBindingsNone => 'No account';

  @override
  String get accountBindingsOpen => 'Account bindings';
}
