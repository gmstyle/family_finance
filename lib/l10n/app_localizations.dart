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
  /// **'Home'**
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

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

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
