import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Application title shown in the window and app bar
  ///
  /// In en, this message translates to:
  /// **'Family Finance'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navBudgetGoals.
  ///
  /// In en, this message translates to:
  /// **'Budget & Goals'**
  String get navBudgetGoals;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @shellBrandTagline.
  ///
  /// In en, this message translates to:
  /// **'Kinship Stewardship'**
  String get shellBrandTagline;

  /// No description provided for @shellActiveFamily.
  ///
  /// In en, this message translates to:
  /// **'Active family'**
  String get shellActiveFamily;

  /// No description provided for @shellSettingsMembers.
  ///
  /// In en, this message translates to:
  /// **'Settings / Members'**
  String get shellSettingsMembers;

  /// No description provided for @shellSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions, notes, or categories…'**
  String get shellSearchHint;

  /// No description provided for @shellExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get shellExport;

  /// No description provided for @shellNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get shellNotifications;

  /// No description provided for @shellAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get shellAddExpense;

  /// No description provided for @shellAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Log expense'**
  String get shellAddTransaction;

  /// No description provided for @shellScanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get shellScanReceipt;

  /// No description provided for @budgetGoalsTabBudgets.
  ///
  /// In en, this message translates to:
  /// **'Monthly budgets'**
  String get budgetGoalsTabBudgets;

  /// No description provided for @budgetGoalsTabGoals.
  ///
  /// In en, this message translates to:
  /// **'Shared goals'**
  String get budgetGoalsTabGoals;

  /// No description provided for @budgetGoalsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Shared overview'**
  String get budgetGoalsEyebrow;

  /// No description provided for @budgetGoalsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Budget & Savings'**
  String get budgetGoalsHeadline;

  /// No description provided for @budgetGoalsEyebrowWeb.
  ///
  /// In en, this message translates to:
  /// **'Shared household planning'**
  String get budgetGoalsEyebrowWeb;

  /// No description provided for @budgetGoalsHeadlineWeb.
  ///
  /// In en, this message translates to:
  /// **'Family budget & goals'**
  String get budgetGoalsHeadlineWeb;

  /// No description provided for @budgetTotalHouseholdSpend.
  ///
  /// In en, this message translates to:
  /// **'Total household spend'**
  String get budgetTotalHouseholdSpend;

  /// No description provided for @budgetAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String budgetAvailableLabel(String amount);

  /// No description provided for @budgetDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days left} one{{count} day left} other{{count} days left}}'**
  String budgetDaysRemaining(int count);

  /// No description provided for @budgetPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String budgetPercentUsed(int percent);

  /// No description provided for @budgetSpentPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% spent'**
  String budgetSpentPercent(int percent);

  /// No description provided for @budgetRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Left: {amount}'**
  String budgetRemainingLabel(String amount);

  /// No description provided for @budgetOfLimitSuffix.
  ///
  /// In en, this message translates to:
  /// **'of {limit}'**
  String budgetOfLimitSuffix(String limit);

  /// No description provided for @budgetCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Spending categories'**
  String get budgetCategoriesSection;

  /// No description provided for @budgetCategoriesSectionWeb.
  ///
  /// In en, this message translates to:
  /// **'Spending category monitoring'**
  String get budgetCategoriesSectionWeb;

  /// No description provided for @budgetEditLimits.
  ///
  /// In en, this message translates to:
  /// **'Edit limits'**
  String get budgetEditLimits;

  /// No description provided for @budgetCreateBudgetOrGoal.
  ///
  /// In en, this message translates to:
  /// **'Create new budget or goal'**
  String get budgetCreateBudgetOrGoal;

  /// No description provided for @budgetCreateBudgetChoice.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetCreateBudgetChoice;

  /// No description provided for @budgetCreateGoalChoice.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get budgetCreateGoalChoice;

  /// No description provided for @budgetNearLimitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} near limit} other{{count} near limit}}'**
  String budgetNearLimitCount(int count);

  /// No description provided for @budgetResidueMonth.
  ///
  /// In en, this message translates to:
  /// **'Month remaining'**
  String get budgetResidueMonth;

  /// No description provided for @budgetResidueAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get budgetResidueAvailable;

  /// No description provided for @budgetDailyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Allowed spend'**
  String get budgetDailyAllowance;

  /// No description provided for @budgetDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get budgetDailyTarget;

  /// No description provided for @budgetDailyPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String budgetDailyPerDay(String amount);

  /// No description provided for @budgetPercentUtilized.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetPercentUtilized(int percent);

  /// No description provided for @budgetMarginRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining margin: {amount} ({percent}%)'**
  String budgetMarginRemaining(String amount, int percent);

  /// No description provided for @budgetNewCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get budgetNewCategoryTitle;

  /// No description provided for @budgetNewCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Add a spending limit'**
  String get budgetNewCategoryBody;

  /// No description provided for @budgetCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create now'**
  String get budgetCreateNow;

  /// No description provided for @goalsSavingBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re saving together toward your family goals.'**
  String get goalsSavingBanner;

  /// No description provided for @goalsNextPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Next goal?'**
  String get goalsNextPromptTitle;

  /// No description provided for @goalsNextPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Add a new shared milestone'**
  String get goalsNextPromptBody;

  /// No description provided for @goalsExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get goalsExplore;

  /// No description provided for @goalAddFunds.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get goalAddFunds;

  /// No description provided for @goalProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String goalProgressPercent(int percent);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get actionUnarchive;

  /// No description provided for @actionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get actionLoadMore;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get actionClearFilters;

  /// No description provided for @moneyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get moneyInvalid;

  /// No description provided for @ledgerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get ledgerErrorTitle;

  /// No description provided for @ledgerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get ledgerNotFound;

  /// No description provided for @ledgerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledgerHomeTitle;

  /// No description provided for @ledgerHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Manage shared accounts, categories, and transactions.'**
  String get ledgerHomeBody;

  /// No description provided for @ledgerHubTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses, income, refunds, and transfers'**
  String get ledgerHubTransactionsSubtitle;

  /// No description provided for @ledgerHubAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balances and opening amounts'**
  String get ledgerHubAccountsSubtitle;

  /// No description provided for @ledgerHubCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System and custom categories'**
  String get ledgerHubCategoriesSubtitle;

  /// No description provided for @ledgerHubTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move money between accounts'**
  String get ledgerHubTransferSubtitle;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Create one to start tracking balances.'**
  String get accountsEmpty;

  /// No description provided for @accountsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get accountsArchived;

  /// No description provided for @accountCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountCreateTitle;

  /// No description provided for @accountEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountEditTitle;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get accountNameInvalid;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get accountTypeCard;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountTypeWallet;

  /// No description provided for @accountOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountOpeningBalance;

  /// No description provided for @accountOpeningDate.
  ///
  /// In en, this message translates to:
  /// **'Opening date'**
  String get accountOpeningDate;

  /// No description provided for @accountBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Current balance: {amount}'**
  String accountBalanceHint(String amount);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get categoriesShowArchived;

  /// No description provided for @categoryCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryCreateTitle;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoryType;

  /// No description provided for @categoryTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoryTypeExpense;

  /// No description provided for @categoryTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryTypeIncome;

  /// No description provided for @categoryTypeImmutableHint.
  ///
  /// In en, this message translates to:
  /// **'Type cannot be changed after creation.'**
  String get categoryTypeImmutableHint;

  /// No description provided for @categorySystemBadge.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get categorySystemBadge;

  /// No description provided for @categoryCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get categoryCustomBadge;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get transactionsEmpty;

  /// No description provided for @transactionsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get transactionsFilters;

  /// No description provided for @filterAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get filterAccount;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get filterMember;

  /// No description provided for @filterDateFrom.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get filterDateFrom;

  /// No description provided for @filterDateTo.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get filterDateTo;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @ledgerBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Ledger'**
  String get ledgerBookTitle;

  /// No description provided for @ledgerExpensesMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} expenses'**
  String ledgerExpensesMonth(String month);

  /// No description provided for @ledgerIncomeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get ledgerIncomeTotal;

  /// No description provided for @ledgerMonthlyOutflows.
  ///
  /// In en, this message translates to:
  /// **'Monthly outflows'**
  String get ledgerMonthlyOutflows;

  /// No description provided for @ledgerMonthlyInflows.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get ledgerMonthlyInflows;

  /// No description provided for @ledgerNetSavings.
  ///
  /// In en, this message translates to:
  /// **'Net savings'**
  String get ledgerNetSavings;

  /// No description provided for @ledgerDataIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Data integrity'**
  String get ledgerDataIntegrity;

  /// No description provided for @ledgerRegistered.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get ledgerRegistered;

  /// No description provided for @ledgerSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search merchant, note, amount…'**
  String get ledgerSearchPlaceholder;

  /// No description provided for @ledgerAllMembers.
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get ledgerAllMembers;

  /// No description provided for @ledgerMemberOnly.
  ///
  /// In en, this message translates to:
  /// **'Only {name}'**
  String ledgerMemberOnly(String name);

  /// No description provided for @ledgerThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get ledgerThisMonth;

  /// No description provided for @ledgerAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get ledgerAllAccounts;

  /// No description provided for @ledgerUnifiedFinance.
  ///
  /// In en, this message translates to:
  /// **'Unified financial management'**
  String get ledgerUnifiedFinance;

  /// No description provided for @ledgerFiscalYear.
  ///
  /// In en, this message translates to:
  /// **'Fiscal year {year}'**
  String ledgerFiscalYear(String year);

  /// No description provided for @ledgerInReview.
  ///
  /// In en, this message translates to:
  /// **'{count} in review'**
  String ledgerInReview(int count);

  /// No description provided for @ledgerDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String ledgerDayToday(String date);

  /// No description provided for @ledgerDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {date}'**
  String ledgerDayYesterday(String date);

  /// No description provided for @ledgerSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Sorted by: newest first'**
  String get ledgerSortNewest;

  /// No description provided for @ledgerShownOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String ledgerShownOf(int shown, int total);

  /// No description provided for @transactionCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get transactionCreateTitle;

  /// No description provided for @transactionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionEditTitle;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionType;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get transactionTypeRefund;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmount;

  /// No description provided for @transactionBookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking date'**
  String get transactionBookingDate;

  /// No description provided for @transactionMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get transactionMerchant;

  /// No description provided for @transactionNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionNote;

  /// No description provided for @transactionFormIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Select account and category'**
  String get transactionFormIncomplete;

  /// No description provided for @transactionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get transactionDeleteTitle;

  /// No description provided for @transactionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the transaction from the shared ledger.'**
  String get transactionDeleteBody;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring payments'**
  String get recurringTitle;

  /// No description provided for @recurringShort.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringShort;

  /// No description provided for @recurringSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage monthly expense and income rules'**
  String get recurringSettingsHint;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring rules yet. Enable monthly recurrence when saving an expense or income.'**
  String get recurringEmpty;

  /// No description provided for @recurringMonthlySwitch.
  ///
  /// In en, this message translates to:
  /// **'Repeat monthly'**
  String get recurringMonthlySwitch;

  /// No description provided for @recurringMonthlyHint.
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String recurringMonthlyHint(int day);

  /// No description provided for @recurringHasEndSwitch.
  ///
  /// In en, this message translates to:
  /// **'Ends after a set number of payments'**
  String get recurringHasEndSwitch;

  /// No description provided for @recurringTotalOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Total payments (including this one)'**
  String get recurringTotalOccurrences;

  /// No description provided for @recurringTotalOccurrencesHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 12 for a one-year loan installment'**
  String get recurringTotalOccurrencesHint;

  /// No description provided for @recurringTotalOccurrencesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 payments'**
  String get recurringTotalOccurrencesInvalid;

  /// No description provided for @recurringEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String recurringEndsOn(String date);

  /// No description provided for @recurringOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get recurringOpenEnded;

  /// No description provided for @recurringClearEnd.
  ///
  /// In en, this message translates to:
  /// **'Remove end date'**
  String get recurringClearEnd;

  /// No description provided for @recurringLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly recurrence'**
  String get recurringLinkedTitle;

  /// No description provided for @recurringLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · next {nextDate}'**
  String recurringLinkedBody(int day, String nextDate);

  /// No description provided for @recurringLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Saving this movement updates only this entry. Future automatic payments follow the rule until you pause or stop it.'**
  String get recurringLinkedHint;

  /// No description provided for @recurringLinkedMissing.
  ///
  /// In en, this message translates to:
  /// **'The linked recurring rule was deleted. You can start a new monthly recurrence below.'**
  String get recurringLinkedMissing;

  /// No description provided for @recurringStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop recurrence?'**
  String get recurringStopTitle;

  /// No description provided for @recurringStopBody.
  ///
  /// In en, this message translates to:
  /// **'Future automatic entries stop. Past ledger transactions are kept.'**
  String get recurringStopBody;

  /// No description provided for @recurringStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop recurrence'**
  String get recurringStopAction;

  /// No description provided for @recurringEditManageAction.
  ///
  /// In en, this message translates to:
  /// **'All recurring payments'**
  String get recurringEditManageAction;

  /// No description provided for @recurringActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringActive;

  /// No description provided for @recurringPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringPaused;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get recurringEdit;

  /// No description provided for @recurringUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recurring rule updated'**
  String get recurringUpdated;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring rule?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Future automatic entries stop. Past ledger transactions are kept.'**
  String get recurringDeleteBody;

  /// No description provided for @recurringBadge.
  ///
  /// In en, this message translates to:
  /// **'From recurring rule'**
  String get recurringBadge;

  /// No description provided for @recurringRuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · next {nextDate} · {account}'**
  String recurringRuleSubtitle(int day, String nextDate, String account);

  /// No description provided for @transferCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferCreateTitle;

  /// No description provided for @transferCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Creates two linked movements. They are deleted together.'**
  String get transferCreateBody;

  /// No description provided for @transferSourceAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get transferSourceAccount;

  /// No description provided for @transferDestinationAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get transferDestinationAccount;

  /// No description provided for @transferAccountsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts'**
  String get transferAccountsInvalid;

  /// No description provided for @transferDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes both legs of this transfer.'**
  String get transferDeleteBody;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayName;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Register'**
  String get authNeedAccount;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSendReset.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendReset;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for the password reset link.'**
  String get authResetSent;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open it, then tap below.'**
  String authVerifyEmailBody(String email);

  /// No description provided for @authIVerified.
  ///
  /// In en, this message translates to:
  /// **'I verified my email'**
  String get authIVerified;

  /// No description provided for @authResendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authResendVerification;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTitle;

  /// No description provided for @familyCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your family'**
  String get familyCreateTitle;

  /// No description provided for @familyCreateBody.
  ///
  /// In en, this message translates to:
  /// **'A shared ledger starts with a family. Currency cannot be changed later.'**
  String get familyCreateBody;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyName;

  /// No description provided for @familyNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get familyNameInvalid;

  /// No description provided for @familyCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Currency is set to EUR for this MVP and is immutable.'**
  String get familyCurrencyHint;

  /// No description provided for @familyCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get familyCreateAction;

  /// No description provided for @familyOrAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Or open an invite link you received.'**
  String get familyOrAcceptInvite;

  /// No description provided for @familyMissing.
  ///
  /// In en, this message translates to:
  /// **'You are not in a family yet.'**
  String get familyMissing;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get familyMembers;

  /// No description provided for @familyInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get familyInvites;

  /// No description provided for @familyInviteEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by email'**
  String get familyInviteEmail;

  /// No description provided for @familyInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied to clipboard'**
  String get familyInviteCopied;

  /// No description provided for @familyInviteEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Invite email sent. Link also copied to clipboard.'**
  String get familyInviteEmailSent;

  /// No description provided for @familyInviteCreatedCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Invite created. Link copied (email not sent — configure SMTP on createInvite).'**
  String get familyInviteCreatedCopyLink;

  /// No description provided for @familyInviteLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Universal invite link (web and Android)'**
  String get familyInviteLinkHint;

  /// No description provided for @familyMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get familyMakeAdmin;

  /// No description provided for @familyMakeMember.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get familyMakeMember;

  /// No description provided for @familyTransferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get familyTransferOwnership;

  /// No description provided for @familyRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get familyRemoveMember;

  /// No description provided for @familyLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave family?'**
  String get familyLeaveTitle;

  /// No description provided for @familyLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access until invited again. Last admin must promote someone first.'**
  String get familyLeaveBody;

  /// No description provided for @familyLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave family'**
  String get familyLeaveAction;

  /// No description provided for @inviteAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Family invite'**
  String get inviteAcceptTitle;

  /// No description provided for @inviteAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Accept this invite to join the shared family ledger.'**
  String get inviteAcceptBody;

  /// No description provided for @inviteAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept invite'**
  String get inviteAcceptAction;

  /// No description provided for @inviteAcceptUseInvitedEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in or register with the same email address that received the invite.'**
  String get inviteAcceptUseInvitedEmail;

  /// No description provided for @inviteAcceptSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String inviteAcceptSignedInAs(String email);

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsFamily.
  ///
  /// In en, this message translates to:
  /// **'Manage family'**
  String get settingsFamily;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the privacy policy.'**
  String get settingsPrivacyLoadError;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export family data'**
  String get settingsExportData;

  /// No description provided for @settingsExportDataHint.
  ///
  /// In en, this message translates to:
  /// **'Download a JSON copy of the data you can read in this family.'**
  String get settingsExportDataHint;

  /// No description provided for @settingsExportDone.
  ///
  /// In en, this message translates to:
  /// **'Export ready — choose an app to save or share it.'**
  String get settingsExportDone;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and sign-in credentials.'**
  String get settingsDeleteAccountHint;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. You will be signed out and your Auth account will be removed.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteAccountSoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account and family data?'**
  String get settingsDeleteAccountSoleTitle;

  /// No description provided for @settingsDeleteAccountSoleBody.
  ///
  /// In en, this message translates to:
  /// **'You are the only member of this family. Deleting your account will permanently erase the entire family ledger (accounts, transactions, budgets, goals, drafts). This cannot be undone.'**
  String get settingsDeleteAccountSoleBody;

  /// No description provided for @settingsDeleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get settingsDeleteAccountConfirmAction;

  /// No description provided for @settingsDeleteReauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it is you'**
  String get settingsDeleteReauthTitle;

  /// No description provided for @settingsDeleteReauthPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue'**
  String get settingsDeleteReauthPassword;

  /// No description provided for @settingsDeleteReauthGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google to confirm'**
  String get settingsDeleteReauthGoogle;

  /// No description provided for @settingsDeleteFailedPromote.
  ///
  /// In en, this message translates to:
  /// **'Promote another admin before deleting your account (or leave the family first).'**
  String get settingsDeleteFailedPromote;

  /// No description provided for @settingsDeleteFailedTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership before deleting your account (or leave the family first).'**
  String get settingsDeleteFailedTransfer;

  /// No description provided for @settingsDeleteFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Check family membership and try again.'**
  String get settingsDeleteFailedGeneric;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other expense'**
  String get categoryOtherExpense;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get categoryOtherIncome;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period {period}'**
  String dashboardPeriodLabel(String period);

  /// No description provided for @dashboardTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardTotalIncome;

  /// No description provided for @dashboardTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardTotalExpense;

  /// No description provided for @dashboardNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get dashboardNet;

  /// No description provided for @dashboardExpensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get dashboardExpensesByCategory;

  /// No description provided for @dashboardIncomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get dashboardIncomeByCategory;

  /// No description provided for @dashboardNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses this period yet.'**
  String get dashboardNoExpenses;

  /// No description provided for @dashboardNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income this period yet.'**
  String get dashboardNoIncome;

  /// No description provided for @dashboardQuickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get dashboardQuickLinks;

  /// No description provided for @dashboardGreetingHi.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}!'**
  String dashboardGreetingHi(String name);

  /// No description provided for @dashboardGreetingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String dashboardGreetingWelcome(String name);

  /// No description provided for @dashboardCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month • {month}'**
  String dashboardCurrentMonth(String month);

  /// No description provided for @dashboardTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Family total balance'**
  String get dashboardTotalBalance;

  /// No description provided for @dashboardNetSavings.
  ///
  /// In en, this message translates to:
  /// **'Net savings: {amount} ({percent}%)'**
  String dashboardNetSavings(String amount, String percent);

  /// No description provided for @dashboardIncomeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month income'**
  String get dashboardIncomeMonth;

  /// No description provided for @dashboardExpenseMonth.
  ///
  /// In en, this message translates to:
  /// **'Month expenses'**
  String get dashboardExpenseMonth;

  /// No description provided for @dashboardReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String dashboardReviewCount(int count);

  /// No description provided for @dashboardReviewActionBadge.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get dashboardReviewActionBadge;

  /// No description provided for @dashboardReviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get dashboardReviewNow;

  /// No description provided for @dashboardReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drafts from wallets and receipt scans awaiting confirmation.'**
  String get dashboardReviewSubtitle;

  /// No description provided for @dashboardAccountsSection.
  ///
  /// In en, this message translates to:
  /// **'Family accounts & cards'**
  String get dashboardAccountsSection;

  /// No description provided for @dashboardManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get dashboardManage;

  /// No description provided for @dashboardBudgetOfMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} budget'**
  String dashboardBudgetOfMonth(String month);

  /// No description provided for @dashboardSeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String dashboardSeeAllCount(int count);

  /// No description provided for @dashboardRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get dashboardRecentTransactions;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String dashboardActiveMembers(int count);

  /// No description provided for @dashboardPatrimony.
  ///
  /// In en, this message translates to:
  /// **'Household wealth'**
  String get dashboardPatrimony;

  /// No description provided for @dashboardIncomeForMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} income'**
  String dashboardIncomeForMonth(String month);

  /// No description provided for @dashboardMonthlyOutflows.
  ///
  /// In en, this message translates to:
  /// **'Monthly outflows'**
  String get dashboardMonthlyOutflows;

  /// No description provided for @dashboardSmartReview.
  ///
  /// In en, this message translates to:
  /// **'Smart review'**
  String get dashboardSmartReview;

  /// No description provided for @dashboardReviewValidate.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions to validate'**
  String dashboardReviewValidate(int count);

  /// No description provided for @dashboardReviewCta.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get dashboardReviewCta;

  /// No description provided for @dashboardCashflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashflow trend'**
  String get dashboardCashflowTitle;

  /// No description provided for @dashboardCashflowPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Weekly cashflow chart coming soon — month totals are in the KPIs above.'**
  String get dashboardCashflowPlaceholder;

  /// No description provided for @dashboardBudgetMonitor.
  ///
  /// In en, this message translates to:
  /// **'Category budget monitor'**
  String get dashboardBudgetMonitor;

  /// No description provided for @dashboardQuickQueue.
  ///
  /// In en, this message translates to:
  /// **'Quick queue'**
  String get dashboardQuickQueue;

  /// No description provided for @dashboardQuickQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drafts to review.'**
  String get dashboardQuickQueueEmpty;

  /// No description provided for @dashboardQuickQueueHint.
  ///
  /// In en, this message translates to:
  /// **'Transactions captured automatically from payment gateways.'**
  String get dashboardQuickQueueHint;

  /// No description provided for @dashboardLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get dashboardLinkedAccounts;

  /// No description provided for @dashboardLinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Link a new account'**
  String get dashboardLinkAccount;

  /// No description provided for @dashboardSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get dashboardSavingsGoals;

  /// No description provided for @dashboardViewAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'View full transaction ledger'**
  String get dashboardViewAllTransactions;

  /// No description provided for @dashboardBudgetPreset.
  ///
  /// In en, this message translates to:
  /// **'Budget target'**
  String get dashboardBudgetPreset;

  /// No description provided for @dashboardSpentPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% spent'**
  String dashboardSpentPercent(String percent);

  /// No description provided for @dashboardUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String dashboardUsedPercent(String percent);

  /// No description provided for @dashboardRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String dashboardRemaining(String amount);

  /// No description provided for @dashboardAttentionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Attention threshold'**
  String get dashboardAttentionThreshold;

  /// No description provided for @dashboardNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.'**
  String get dashboardNoAccounts;

  /// No description provided for @dashboardNoRecentTx.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get dashboardNoRecentTx;

  /// No description provided for @dashboardNoGoals.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet.'**
  String get dashboardNoGoals;

  /// No description provided for @dashboardAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get dashboardAvailableBalance;

  /// No description provided for @dashboardPrimaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get dashboardPrimaryAccount;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet. Set a monthly limit for an expense category.'**
  String get budgetsEmpty;

  /// No description provided for @budgetCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetCreateTitle;

  /// No description provided for @budgetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEditTitle;

  /// No description provided for @budgetCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetCategory;

  /// No description provided for @budgetCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an expense category'**
  String get budgetCategoryRequired;

  /// No description provided for @budgetCategoryImmutableHint.
  ///
  /// In en, this message translates to:
  /// **'Category cannot be changed after creation.'**
  String get budgetCategoryImmutableHint;

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetLimit;

  /// No description provided for @budgetPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'{period}'**
  String budgetPeriodLabel(String period);

  /// No description provided for @budgetPeriodPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get budgetPeriodPrevious;

  /// No description provided for @budgetPeriodNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get budgetPeriodNext;

  /// No description provided for @budgetSpentOfLimit.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String budgetSpentOfLimit(String spent, String limit);

  /// No description provided for @budgetAlert80.
  ///
  /// In en, this message translates to:
  /// **'80% of budget reached'**
  String get budgetAlert80;

  /// No description provided for @budgetAlert100.
  ///
  /// In en, this message translates to:
  /// **'Budget limit reached'**
  String get budgetAlert100;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. Create one and track virtual contributions.'**
  String get goalsEmpty;

  /// No description provided for @goalCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalCreateTitle;

  /// No description provided for @goalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEditTitle;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @goalNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get goalNameInvalid;

  /// No description provided for @goalTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalTargetAmount;

  /// No description provided for @goalDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get goalDueDate;

  /// No description provided for @goalDueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get goalDueDateOptional;

  /// No description provided for @goalDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String goalDueDateLabel(String date);

  /// No description provided for @goalProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{accumulated} of {target}'**
  String goalProgressLabel(String accumulated, String target);

  /// No description provided for @goalAccumulatedHint.
  ///
  /// In en, this message translates to:
  /// **'Accumulated (server): {amount}'**
  String goalAccumulatedHint(String amount);

  /// No description provided for @goalContributeTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get goalContributeTitle;

  /// No description provided for @goalContributeAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit / withdraw'**
  String get goalContributeAction;

  /// No description provided for @goalContributeHint.
  ///
  /// In en, this message translates to:
  /// **'Virtual only — does not change account balances.'**
  String get goalContributeHint;

  /// No description provided for @goalDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get goalDeposit;

  /// No description provided for @goalWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get goalWithdraw;

  /// No description provided for @goalContributionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent contributions'**
  String get goalContributionsTitle;

  /// No description provided for @goalContributionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contributions yet.'**
  String get goalContributionsEmpty;

  /// No description provided for @ingestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get ingestionTitle;

  /// No description provided for @ingestionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drafts to review. Scan a receipt on Android to add one.'**
  String get ingestionEmpty;

  /// No description provided for @ingestionReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review draft'**
  String get ingestionReviewTitle;

  /// No description provided for @ingestionUnknownMerchant.
  ///
  /// In en, this message translates to:
  /// **'Unknown merchant'**
  String get ingestionUnknownMerchant;

  /// No description provided for @ingestionStatusNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get ingestionStatusNeedsReview;

  /// No description provided for @ingestionStatusPossibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get ingestionStatusPossibleDuplicate;

  /// No description provided for @ingestionSourceReceiptOcr.
  ///
  /// In en, this message translates to:
  /// **'Receipt scan'**
  String get ingestionSourceReceiptOcr;

  /// No description provided for @ingestionSourceNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get ingestionSourceNotification;

  /// No description provided for @ingestionPossibleDuplicateHint.
  ///
  /// In en, this message translates to:
  /// **'A similar transaction may already exist. Review carefully before confirming.'**
  String get ingestionPossibleDuplicateHint;

  /// No description provided for @ingestionConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm transaction'**
  String get ingestionConfirmAction;

  /// No description provided for @ingestionPeriodMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Date outside current month'**
  String get ingestionPeriodMismatchTitle;

  /// No description provided for @ingestionPeriodMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'The receipt is dated {bookingDate}: it will count toward the {bookingPeriod} budget, not {currentPeriod} that you are viewing.'**
  String ingestionPeriodMismatchBody(
    String bookingDate,
    String bookingPeriod,
    String currentPeriod,
  );

  /// No description provided for @ingestionUseReceiptDate.
  ///
  /// In en, this message translates to:
  /// **'Use receipt date'**
  String get ingestionUseReceiptDate;

  /// No description provided for @ingestionUseTodayDate.
  ///
  /// In en, this message translates to:
  /// **'Use today\'s date'**
  String get ingestionUseTodayDate;

  /// No description provided for @ingestionDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get ingestionDiscardAction;

  /// No description provided for @ingestionDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard draft?'**
  String get ingestionDiscardTitle;

  /// No description provided for @ingestionDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'This draft will be discarded. No transaction will be created.'**
  String get ingestionDiscardBody;

  /// No description provided for @ingestionSaveMerchantRule.
  ///
  /// In en, this message translates to:
  /// **'Remember category and account for this merchant'**
  String get ingestionSaveMerchantRule;

  /// No description provided for @ingestionSaveMerchantRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Used as suggestions the next time this merchant appears.'**
  String get ingestionSaveMerchantRuleHint;

  /// No description provided for @ingestionOpenQueue.
  ///
  /// In en, this message translates to:
  /// **'Open review queue'**
  String get ingestionOpenQueue;

  /// No description provided for @ingestionPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String ingestionPendingCount(int count);

  /// No description provided for @ingestionFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String ingestionFilterAll(int count);

  /// No description provided for @ingestionFilterNotification.
  ///
  /// In en, this message translates to:
  /// **'Notifications ({count})'**
  String ingestionFilterNotification(int count);

  /// No description provided for @ingestionFilterOcr.
  ///
  /// In en, this message translates to:
  /// **'Receipt OCR ({count})'**
  String ingestionFilterOcr(int count);

  /// No description provided for @ingestionFilterDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicates ({count})'**
  String ingestionFilterDuplicates(int count);

  /// No description provided for @ingestionConfirmLedger.
  ///
  /// In en, this message translates to:
  /// **'Confirm to ledger'**
  String get ingestionConfirmLedger;

  /// No description provided for @ingestionEmptyDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get ingestionEmptyDoneTitle;

  /// No description provided for @ingestionEmptyDoneBody.
  ///
  /// In en, this message translates to:
  /// **'No drafts waiting. The family ledger is up to date.'**
  String get ingestionEmptyDoneBody;

  /// No description provided for @ingestionEmptyGoDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get ingestionEmptyGoDashboard;

  /// No description provided for @ingestionSettingsCapture.
  ///
  /// In en, this message translates to:
  /// **'Notification & OCR capture settings'**
  String get ingestionSettingsCapture;

  /// No description provided for @ingestionUnreconciledTitle.
  ///
  /// In en, this message translates to:
  /// **'Unreconciled items'**
  String get ingestionUnreconciledTitle;

  /// No description provided for @ingestionSortedByDate.
  ///
  /// In en, this message translates to:
  /// **'Sorted by date'**
  String get ingestionSortedByDate;

  /// No description provided for @ingestionSelectDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Select a draft to verify and confirm'**
  String get ingestionSelectDraftHint;

  /// No description provided for @ingestionReviewVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify & assign expense'**
  String get ingestionReviewVerifyTitle;

  /// No description provided for @ingestionInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get ingestionInReview;

  /// No description provided for @ingestionToConfirm.
  ///
  /// In en, this message translates to:
  /// **'To confirm'**
  String get ingestionToConfirm;

  /// No description provided for @ingestionWebEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Staging & AI reconciliation'**
  String get ingestionWebEyebrow;

  /// No description provided for @receiptScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get receiptScanTitle;

  /// No description provided for @receiptScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get receiptScanAction;

  /// No description provided for @receiptScanBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose an image. The app extracts amount, date, and merchant into a draft you must confirm — nothing is posted silently.'**
  String get receiptScanBody;

  /// No description provided for @receiptScanCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get receiptScanCamera;

  /// No description provided for @receiptScanGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get receiptScanGallery;

  /// No description provided for @receiptScanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reading receipt…'**
  String get receiptScanProcessing;

  /// No description provided for @receiptScanAndroidOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt scan is Android-only'**
  String get receiptScanAndroidOnlyTitle;

  /// No description provided for @receiptScanAndroidOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'On-device OCR runs only on Android. You can still review and confirm drafts from the queue on this device.'**
  String get receiptScanAndroidOnlyBody;

  /// No description provided for @receiptScanAndroidOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanning is available on Android. You can review drafts here.'**
  String get receiptScanAndroidOnlyBanner;

  /// No description provided for @notificationListenerTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment notification capture'**
  String get notificationListenerTitle;

  /// No description provided for @notificationListenerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Listener enabled — Wallet notifications create review drafts'**
  String get notificationListenerEnabled;

  /// No description provided for @notificationListenerDisabled.
  ///
  /// In en, this message translates to:
  /// **'Listener off — tap to enable in system settings'**
  String get notificationListenerDisabled;

  /// No description provided for @notificationListenerAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Payment notification capture is available on Android only. You can still review drafts here.'**
  String get notificationListenerAndroidOnly;

  /// No description provided for @notificationListenerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification access settings'**
  String get notificationListenerOpenSettings;

  /// No description provided for @notificationDraftAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} drafts to review'**
  String notificationDraftAlertTitle(int count);

  /// No description provided for @notificationDraftAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Open the review queue to confirm or discard. Nothing is posted without your confirmation.'**
  String get notificationDraftAlertBody;

  /// No description provided for @accountBindingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification account bindings'**
  String get accountBindingsTitle;

  /// No description provided for @accountBindingsHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest a default account when a draft is created from each app’s notifications. You can still change the account before confirming.'**
  String get accountBindingsHint;

  /// No description provided for @accountBindingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notification packages configured.'**
  String get accountBindingsEmpty;

  /// No description provided for @accountBindingsNone.
  ///
  /// In en, this message translates to:
  /// **'No account'**
  String get accountBindingsNone;

  /// No description provided for @accountBindingsOpen.
  ///
  /// In en, this message translates to:
  /// **'Account bindings'**
  String get accountBindingsOpen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
