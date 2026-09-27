// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Family Finance';

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get homePlaceholderTitle => 'Home';

  @override
  String get homePlaceholderBody =>
      'Qui compariranno libro mastro, budget e obiettivi.';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authRegister => 'Crea account';

  @override
  String get authCreateAccount => 'Crea il tuo account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authDisplayName => 'Nome visualizzato';

  @override
  String get authEmailInvalid => 'Inserisci un\'email valida';

  @override
  String get authPasswordTooShort =>
      'La password deve avere almeno 6 caratteri';

  @override
  String get authContinueGoogle => 'Continua con Google';

  @override
  String get authHaveAccount => 'Hai già un account? Accedi';

  @override
  String get authNeedAccount => 'Non hai un account? Registrati';

  @override
  String get authForgotPassword => 'Password dimenticata?';

  @override
  String get authSendReset => 'Invia link di reset';

  @override
  String get authResetSent => 'Controlla la posta per il link di reset.';

  @override
  String get authBackToSignIn => 'Torna all\'accesso';

  @override
  String get authSignOut => 'Esci';

  @override
  String get authVerifyEmailTitle => 'Verifica la tua email';

  @override
  String authVerifyEmailBody(String email) {
    return 'Abbiamo inviato un link a $email. Aprilo, poi tocca qui sotto.';
  }

  @override
  String get authIVerified => 'Ho verificato l\'email';

  @override
  String get authResendVerification => 'Reinvia email di verifica';

  @override
  String get familyTitle => 'Famiglia';

  @override
  String get familyCreateTitle => 'Crea la tua famiglia';

  @override
  String get familyCreateBody =>
      'Il libro mastro condiviso inizia con una famiglia. La valuta non si può cambiare dopo.';

  @override
  String get familyName => 'Nome famiglia';

  @override
  String get familyNameInvalid => 'Inserisci almeno 2 caratteri';

  @override
  String get familyCurrencyHint =>
      'La valuta è EUR per questo MVP ed è immutabile.';

  @override
  String get familyCreateAction => 'Crea famiglia';

  @override
  String get familyOrAcceptInvite =>
      'Oppure apri un link di invito che hai ricevuto.';

  @override
  String get familyMissing => 'Non sei ancora in una famiglia.';

  @override
  String get familyMembers => 'Membri';

  @override
  String get familyInvites => 'Inviti';

  @override
  String get familyInviteEmail => 'Invita via email';

  @override
  String get familyInviteCopied => 'Link invito copiato negli appunti';

  @override
  String get familyInviteLinkHint =>
      'Condividi questo link (in emulatore: copia a mano)';

  @override
  String get familyMakeAdmin => 'Rendi admin';

  @override
  String get familyMakeMember => 'Rendi membro';

  @override
  String get familyTransferOwnership => 'Trasferisci ownership';

  @override
  String get familyRemoveMember => 'Rimuovi';

  @override
  String get familyLeaveTitle => 'Uscire dalla famiglia?';

  @override
  String get familyLeaveBody =>
      'Perderai l\'accesso finché non verrai reinvitato. L\'ultimo admin deve promuoverne un altro prima.';

  @override
  String get familyLeaveAction => 'Esci dalla famiglia';

  @override
  String get inviteAcceptTitle => 'Invito famiglia';

  @override
  String get inviteAcceptBody =>
      'Accetta l\'invito per entrare nel libro mastro condiviso.';

  @override
  String get inviteAcceptAction => 'Accetta invito';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFamily => 'Gestisci famiglia';

  @override
  String get categoryFood => 'Cibo';

  @override
  String get categoryTransport => 'Trasporti';

  @override
  String get categoryHousing => 'Casa';

  @override
  String get categoryUtilities => 'Utenze';

  @override
  String get categoryHealth => 'Salute';

  @override
  String get categoryEntertainment => 'Svago';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEducation => 'Istruzione';

  @override
  String get categoryOtherExpense => 'Altre uscite';

  @override
  String get categorySalary => 'Stipendio';

  @override
  String get categoryOtherIncome => 'Altre entrate';
}
