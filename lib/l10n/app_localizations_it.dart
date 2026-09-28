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
  String get navTransactions => 'Movimenti';

  @override
  String get navAccounts => 'Conti';

  @override
  String get navCategories => 'Categorie';

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
  String get actionCancel => 'Annulla';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionArchive => 'Archivia';

  @override
  String get actionUnarchive => 'Ripristina';

  @override
  String get actionLoadMore => 'Carica altri';

  @override
  String get actionApply => 'Applica';

  @override
  String get actionClearFilters => 'Pulisci filtri';

  @override
  String get moneyInvalid => 'Inserisci un importo valido';

  @override
  String get ledgerErrorTitle => 'Qualcosa è andato storto';

  @override
  String get ledgerNotFound => 'Elemento non trovato';

  @override
  String get ledgerHomeTitle => 'Libro mastro';

  @override
  String get ledgerHomeBody =>
      'Gestisci conti, categorie e movimenti condivisi.';

  @override
  String get ledgerHubTransactionsSubtitle =>
      'Spese, entrate, rimborsi e trasferimenti';

  @override
  String get ledgerHubAccountsSubtitle => 'Saldi e saldo iniziale';

  @override
  String get ledgerHubCategoriesSubtitle =>
      'Categorie di sistema e personalizzate';

  @override
  String get ledgerHubTransferSubtitle => 'Sposta denaro tra conti';

  @override
  String get accountsTitle => 'Conti';

  @override
  String get accountsEmpty =>
      'Nessun conto. Creane uno per iniziare a tracciare i saldi.';

  @override
  String get accountsArchived => 'Archiviati';

  @override
  String get accountCreateTitle => 'Nuovo conto';

  @override
  String get accountEditTitle => 'Modifica conto';

  @override
  String get accountName => 'Nome conto';

  @override
  String get accountNameInvalid => 'Inserisci almeno 2 caratteri';

  @override
  String get accountType => 'Tipo di conto';

  @override
  String get accountTypeCash => 'Contanti';

  @override
  String get accountTypeBank => 'Conto bancario';

  @override
  String get accountTypeCard => 'Carta';

  @override
  String get accountTypeWallet => 'Portafoglio';

  @override
  String get accountOpeningBalance => 'Saldo iniziale';

  @override
  String get accountOpeningDate => 'Data apertura';

  @override
  String accountBalanceHint(String amount) {
    return 'Saldo attuale: $amount';
  }

  @override
  String get categoriesTitle => 'Categorie';

  @override
  String get categoriesEmpty => 'Nessuna categoria.';

  @override
  String get categoriesShowArchived => 'Mostra archiviate';

  @override
  String get categoryCreateTitle => 'Nuova categoria';

  @override
  String get categoryName => 'Nome categoria';

  @override
  String get categoryType => 'Tipo';

  @override
  String get categoryTypeExpense => 'Spesa';

  @override
  String get categoryTypeIncome => 'Entrata';

  @override
  String get categoryTypeImmutableHint =>
      'Il tipo non si può cambiare dopo la creazione.';

  @override
  String get categorySystemBadge => 'Sistema';

  @override
  String get categoryCustomBadge => 'Personalizzata';

  @override
  String get transactionsTitle => 'Movimenti';

  @override
  String get transactionsEmpty => 'Nessun movimento con questi filtri.';

  @override
  String get transactionsFilters => 'Filtri';

  @override
  String get filterAccount => 'Conto';

  @override
  String get filterCategory => 'Categoria';

  @override
  String get filterMember => 'Membro';

  @override
  String get filterDateFrom => 'Dal';

  @override
  String get filterDateTo => 'Al';

  @override
  String get filterAll => 'Tutti';

  @override
  String get transactionCreateTitle => 'Nuovo movimento';

  @override
  String get transactionEditTitle => 'Modifica movimento';

  @override
  String get transactionType => 'Tipo';

  @override
  String get transactionTypeExpense => 'Spesa';

  @override
  String get transactionTypeIncome => 'Entrata';

  @override
  String get transactionTypeRefund => 'Rimborso';

  @override
  String get transactionTypeTransfer => 'Trasferimento';

  @override
  String get transactionAmount => 'Importo';

  @override
  String get transactionBookingDate => 'Data contabile';

  @override
  String get transactionMerchant => 'Esercente';

  @override
  String get transactionNote => 'Nota';

  @override
  String get transactionFormIncomplete => 'Seleziona conto e categoria';

  @override
  String get transactionDeleteTitle => 'Eliminare il movimento?';

  @override
  String get transactionDeleteBody =>
      'Il movimento sarà rimosso dal libro mastro condiviso.';

  @override
  String get transferCreateTitle => 'Trasferimento';

  @override
  String get transferCreateBody =>
      'Crea due movimenti collegati. Si cancellano insieme.';

  @override
  String get transferSourceAccount => 'Dal conto';

  @override
  String get transferDestinationAccount => 'Al conto';

  @override
  String get transferAccountsInvalid => 'Scegli due conti diversi';

  @override
  String get transferDeleteBody =>
      'Elimina entrambe le gambe del trasferimento.';

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
