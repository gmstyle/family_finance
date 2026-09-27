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
  String get homePlaceholderTitle => 'Home';

  @override
  String get homePlaceholderBody =>
      'Shared ledger, budgets, and goals will appear here.';

  @override
  String get actionCancel => 'Cancel';

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
}
