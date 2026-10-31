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
  String get navHome => 'Dashboard';

  @override
  String get navTransactions => 'Transazioni';

  @override
  String get navAccounts => 'Conti';

  @override
  String get navCategories => 'Categorie';

  @override
  String get navBudgets => 'Budget';

  @override
  String get navGoals => 'Obiettivi';

  @override
  String get navReview => 'Revisione';

  @override
  String get navBudgetGoals => 'Budget & Obiettivi';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get shellBrandTagline => 'Kinship Stewardship';

  @override
  String get shellActiveFamily => 'Nucleo attivo';

  @override
  String get shellSettingsMembers => 'Impostazioni / Membri';

  @override
  String get shellSearchHint => 'Cerca transazioni, note o categorie...';

  @override
  String get shellExport => 'Esporta';

  @override
  String get shellNotifications => 'Notifiche';

  @override
  String get shellAddExpense => 'Aggiungi spesa';

  @override
  String get shellAddTransaction => 'Registra spesa';

  @override
  String get shellScanReceipt => 'Scansiona ricevuta';

  @override
  String get budgetGoalsTabBudgets => 'Budget mensili';

  @override
  String get budgetGoalsTabGoals => 'Obiettivi comuni';

  @override
  String get budgetGoalsEyebrow => 'Panoramica condivisa';

  @override
  String get budgetGoalsHeadline => 'Budget & Risparmio';

  @override
  String get budgetGoalsEyebrowWeb => 'Pianificazione domestica condivisa';

  @override
  String get budgetGoalsHeadlineWeb => 'Budget e obiettivi del nucleo';

  @override
  String get budgetTotalHouseholdSpend => 'Spesa totale della casa';

  @override
  String budgetAvailableLabel(String amount) {
    return 'Disponibili: $amount';
  }

  @override
  String budgetDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni rimasti',
      one: '$count giorno rimasto',
      zero: 'Nessun giorno rimasto',
    );
    return '$_temp0';
  }

  @override
  String budgetPercentUsed(int percent) {
    return '$percent%';
  }

  @override
  String budgetSpentPercent(int percent) {
    return '$percent% speso';
  }

  @override
  String budgetRemainingLabel(String amount) {
    return 'Rimasti: $amount';
  }

  @override
  String budgetOfLimitSuffix(String limit) {
    return 'su $limit';
  }

  @override
  String get budgetCategoriesSection => 'Categorie di spesa';

  @override
  String get budgetCategoriesSectionWeb => 'Monitoraggio categorie di spesa';

  @override
  String get budgetEditLimits => 'Modifica limiti';

  @override
  String get budgetCreateBudgetOrGoal => 'Crea nuovo budget o obiettivo';

  @override
  String get budgetCreateBudgetChoice => 'Nuovo budget';

  @override
  String get budgetCreateGoalChoice => 'Nuovo obiettivo';

  @override
  String budgetNearLimitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vicini al limite',
      one: '$count vicino al limite',
    );
    return '$_temp0';
  }

  @override
  String get budgetResidueMonth => 'Residuo mese';

  @override
  String get budgetResidueAvailable => 'Disponibili';

  @override
  String get budgetDailyAllowance => 'Spesa consentita';

  @override
  String get budgetDailyTarget => 'Target giornaliero';

  @override
  String budgetDailyPerDay(String amount) {
    return '$amount / g';
  }

  @override
  String budgetPercentUtilized(int percent) {
    return '$percent% utilizzato';
  }

  @override
  String budgetMarginRemaining(String amount, int percent) {
    return 'Margine residuo: $amount ($percent%)';
  }

  @override
  String get budgetNewCategoryTitle => 'Nuova categoria';

  @override
  String get budgetNewCategoryBody => 'Aggiungi una soglia di spesa';

  @override
  String get budgetCreateNow => 'Crea ora';

  @override
  String get goalsSavingBanner =>
      'State risparmiando insieme verso i vostri obiettivi di famiglia.';

  @override
  String get goalsNextPromptTitle => 'Prossimo obiettivo?';

  @override
  String get goalsNextPromptBody => 'Aggiungi un nuovo traguardo condiviso';

  @override
  String get goalsExplore => 'Esplora';

  @override
  String get goalAddFunds => 'Aggiungi fondi';

  @override
  String goalProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionContinue => 'Continua';

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
  String get ledgerBookTitle => 'Libro Mastro Famiglia';

  @override
  String ledgerExpensesMonth(String month) {
    return 'Spese $month';
  }

  @override
  String get ledgerIncomeTotal => 'Entrate totali';

  @override
  String get ledgerMonthlyOutflows => 'Uscite mensili';

  @override
  String get ledgerMonthlyInflows => 'Entrate mensili';

  @override
  String get ledgerNetSavings => 'Risparmio netto';

  @override
  String get ledgerDataIntegrity => 'Integrità dati';

  @override
  String get ledgerRegistered => 'Registrate';

  @override
  String get ledgerSearchPlaceholder => 'Cerca esercente, nota, importo...';

  @override
  String get ledgerAllMembers => 'Tutti i membri';

  @override
  String ledgerMemberOnly(String name) {
    return 'Solo $name';
  }

  @override
  String get ledgerThisMonth => 'Questo mese';

  @override
  String get ledgerAllAccounts => 'Tutti i conti';

  @override
  String get ledgerUnifiedFinance => 'Gestione finanziaria unificata';

  @override
  String ledgerFiscalYear(String year) {
    return 'Anno fiscale $year';
  }

  @override
  String ledgerInReview(int count) {
    return '$count in revisione';
  }

  @override
  String ledgerDayToday(String date) {
    return 'Oggi, $date';
  }

  @override
  String ledgerDayYesterday(String date) {
    return 'Ieri, $date';
  }

  @override
  String get ledgerSortNewest => 'Ordinato per: data più recente';

  @override
  String ledgerShownOf(int shown, int total) {
    return 'Mostrate $shown di $total';
  }

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
  String get recurringTitle => 'Pagamenti ricorrenti';

  @override
  String get recurringShort => 'Ricorrenti';

  @override
  String get recurringSettingsHint =>
      'Gestisci regole mensili di spese e entrate';

  @override
  String get recurringEmpty =>
      'Nessuna regola ricorrente. Attiva la ricorrenza mensile quando salvi una spesa o un\'entrata.';

  @override
  String get recurringMonthlySwitch => 'Ripeti ogni mese';

  @override
  String recurringMonthlyHint(int day) {
    return 'Ogni mese il giorno $day';
  }

  @override
  String get recurringHasEndSwitch => 'Termina dopo un numero di pagamenti';

  @override
  String get recurringTotalOccurrences => 'Pagamenti totali (incluso questo)';

  @override
  String get recurringTotalOccurrencesHint =>
      'Esempio: 12 per una rata annuale';

  @override
  String get recurringTotalOccurrencesInvalid => 'Inserisci almeno 2 pagamenti';

  @override
  String recurringEndsOn(String date) {
    return 'Termina il $date';
  }

  @override
  String get recurringOpenEnded => 'Senza scadenza';

  @override
  String get recurringClearEnd => 'Rimuovi scadenza';

  @override
  String get recurringLinkedTitle => 'Ricorrenza mensile';

  @override
  String recurringLinkedBody(int day, String nextDate) {
    return 'Giorno $day · prossima $nextDate';
  }

  @override
  String get recurringLinkedHint =>
      'Salvare questo movimento aggiorna solo questa voce. I pagamenti automatici futuri seguono la regola finché non la metti in pausa o la interrompi.';

  @override
  String get recurringLinkedMissing =>
      'La regola ricorrente collegata è stata eliminata. Puoi avviare una nuova ricorrenza mensile qui sotto.';

  @override
  String get recurringStopTitle => 'Interrompere la ricorrenza?';

  @override
  String get recurringStopBody =>
      'Le prossime voci automatiche si interrompono. I movimenti già scritti restano nel libro mastro.';

  @override
  String get recurringStopAction => 'Interrompi ricorrenza';

  @override
  String get recurringEditManageAction => 'Tutti i pagamenti ricorrenti';

  @override
  String get recurringActive => 'Attiva';

  @override
  String get recurringPaused => 'In pausa';

  @override
  String get recurringPause => 'Pausa';

  @override
  String get recurringResume => 'Riprendi';

  @override
  String get recurringEdit => 'Modifica regola';

  @override
  String get recurringUpdated => 'Regola ricorrente aggiornata';

  @override
  String get recurringDeleteTitle => 'Eliminare la regola ricorrente?';

  @override
  String get recurringDeleteBody =>
      'Le prossime voci automatiche si interrompono. I movimenti già scritti restano nel libro mastro.';

  @override
  String get recurringBadge => 'Da regola ricorrente';

  @override
  String recurringRuleSubtitle(int day, String nextDate, String account) {
    return 'Giorno $day · prossima $nextDate · $account';
  }

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
  String get familyInviteEmailSent =>
      'Email di invito inviata. Link copiato negli appunti.';

  @override
  String get familyInviteCreatedCopyLink =>
      'Invito creato. Link copiato (email non inviata — configura SMTP su createInvite).';

  @override
  String get familyInviteLinkHint => 'Link invito universale (web e Android)';

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
  String get inviteAcceptUseInvitedEmail =>
      'Accedi o registrati con la stessa email a cui è stato inviato l’invito.';

  @override
  String inviteAcceptSignedInAs(String email) {
    return 'Accesso come $email';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFamily => 'Gestisci famiglia';

  @override
  String get settingsPrivacyData => 'Privacy e dati';

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsPrivacyLoadError =>
      'Impossibile caricare l\'informativa sulla privacy.';

  @override
  String get settingsExportData => 'Esporta dati famiglia';

  @override
  String get settingsExportDataHint =>
      'Scarica una copia JSON dei dati che puoi leggere in questa famiglia.';

  @override
  String get settingsExportDone =>
      'Export pronto — scegli un\'app per salvarlo o condividerlo.';

  @override
  String get settingsDeleteAccount => 'Elimina account';

  @override
  String get settingsDeleteAccountHint =>
      'Elimina in modo permanente l\'account e le credenziali di accesso.';

  @override
  String get settingsDeleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get settingsDeleteAccountBody =>
      'L\'operazione non si può annullare. Verrai disconnesso e l\'account Auth sarà rimosso.';

  @override
  String get settingsDeleteAccountSoleTitle =>
      'Eliminare account e dati famiglia?';

  @override
  String get settingsDeleteAccountSoleBody =>
      'Sei l\'unico membro di questa famiglia. Eliminando l\'account cancellerai in modo permanente tutto il libro mastro (conti, movimenti, budget, obiettivi, bozze). Non si può annullare.';

  @override
  String get settingsDeleteAccountConfirmAction => 'Elimina definitivamente';

  @override
  String get settingsDeleteReauthTitle => 'Conferma la tua identità';

  @override
  String get settingsDeleteReauthPassword =>
      'Inserisci la password per continuare';

  @override
  String get settingsDeleteReauthGoogle => 'Continua con Google per confermare';

  @override
  String get settingsDeleteFailedPromote =>
      'Promuovi un altro admin prima di eliminare l\'account (oppure esci prima dalla famiglia).';

  @override
  String get settingsDeleteFailedTransfer =>
      'Trasferisci la proprietà prima di eliminare l\'account (oppure esci prima dalla famiglia).';

  @override
  String get settingsDeleteFailedGeneric =>
      'Impossibile eliminare l\'account. Controlla l\'appartenenza alla famiglia e riprova.';

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

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardPeriodLabel(String period) {
    return 'Periodo $period';
  }

  @override
  String get dashboardTotalIncome => 'Entrate';

  @override
  String get dashboardTotalExpense => 'Spese';

  @override
  String get dashboardNet => 'Netto';

  @override
  String get dashboardExpensesByCategory => 'Spese per categoria';

  @override
  String get dashboardIncomeByCategory => 'Entrate per categoria';

  @override
  String get dashboardNoExpenses => 'Nessuna spesa in questo periodo.';

  @override
  String get dashboardNoIncome => 'Nessuna entrata in questo periodo.';

  @override
  String get dashboardQuickLinks => 'Collegamenti rapidi';

  @override
  String dashboardGreetingHi(String name) {
    return 'Ciao $name!';
  }

  @override
  String dashboardGreetingWelcome(String name) {
    return 'Bentornato, $name';
  }

  @override
  String dashboardCurrentMonth(String month) {
    return 'Mese corrente • $month';
  }

  @override
  String get dashboardTotalBalance => 'Saldo Totale Famiglia';

  @override
  String dashboardNetSavings(String amount, String percent) {
    return 'Risparmio netto: $amount ($percent%)';
  }

  @override
  String get dashboardIncomeMonth => 'Entrate Mese';

  @override
  String get dashboardExpenseMonth => 'Spese Mese';

  @override
  String dashboardReviewCount(int count) {
    return '$count Da Revisionare';
  }

  @override
  String get dashboardReviewActionBadge => 'Azione';

  @override
  String get dashboardReviewNow => 'Revisiona ora';

  @override
  String get dashboardReviewSubtitle =>
      'Bozze da wallet e scansione scontrino in attesa di conferma.';

  @override
  String get dashboardAccountsSection => 'Conti e Carte Famiglia';

  @override
  String get dashboardManage => 'Gestisci';

  @override
  String dashboardBudgetOfMonth(String month) {
    return 'Budget di $month';
  }

  @override
  String dashboardSeeAllCount(int count) {
    return 'Vedi tutti ($count)';
  }

  @override
  String get dashboardRecentTransactions => 'Ultime Transazioni';

  @override
  String get dashboardSeeAll => 'Tutte';

  @override
  String dashboardActiveMembers(int count) {
    return '$count attivi';
  }

  @override
  String get dashboardPatrimony => 'Patrimonio Nucleo';

  @override
  String dashboardIncomeForMonth(String month) {
    return 'Entrate $month';
  }

  @override
  String get dashboardMonthlyOutflows => 'Uscite Mensili';

  @override
  String get dashboardSmartReview => 'Smart Review';

  @override
  String dashboardReviewValidate(int count) {
    return '$count Transazioni da Validare';
  }

  @override
  String get dashboardReviewCta => 'Revisiona Subito';

  @override
  String get dashboardCashflowTitle => 'Andamento Cashflow';

  @override
  String get dashboardCashflowPlaceholder =>
      'Grafico cashflow settimanale in arrivo — i totali del mese sono nei KPI sopra.';

  @override
  String get dashboardBudgetMonitor => 'Monitoraggio Budget di Categoria';

  @override
  String get dashboardQuickQueue => 'Coda Rapida';

  @override
  String get dashboardQuickQueueEmpty => 'Nessuna bozza da revisionare.';

  @override
  String get dashboardQuickQueueHint =>
      'Transazioni intercettate automaticamente dai gateway di pagamento.';

  @override
  String get dashboardLinkedAccounts => 'Conti Collegati';

  @override
  String get dashboardLinkAccount => 'Collega nuovo conto';

  @override
  String get dashboardSavingsGoals => 'Obiettivi di Risparmio';

  @override
  String get dashboardViewAllTransactions =>
      'Vedi tutto il registro transazioni';

  @override
  String get dashboardBudgetPreset => 'Budget prefissato';

  @override
  String dashboardSpentPercent(String percent) {
    return '$percent% speso';
  }

  @override
  String dashboardUsedPercent(String percent) {
    return '$percent% utilizzato';
  }

  @override
  String dashboardRemaining(String amount) {
    return 'Rimangono $amount';
  }

  @override
  String get dashboardAttentionThreshold => 'Soglia d\'attenzione';

  @override
  String get dashboardNoAccounts => 'Nessun conto ancora.';

  @override
  String get dashboardNoRecentTx => 'Nessuna transazione recente.';

  @override
  String get dashboardNoGoals => 'Nessun obiettivo di risparmio.';

  @override
  String get dashboardAvailableBalance => 'Saldo disponibile';

  @override
  String get dashboardPrimaryAccount => 'Principale';

  @override
  String get budgetsTitle => 'Budget';

  @override
  String get budgetsEmpty =>
      'Nessun budget. Imposta un limite mensile per una categoria di spesa.';

  @override
  String get budgetCreateTitle => 'Nuovo budget';

  @override
  String get budgetEditTitle => 'Modifica budget';

  @override
  String get budgetCategory => 'Categoria';

  @override
  String get budgetCategoryRequired => 'Seleziona una categoria di spesa';

  @override
  String get budgetCategoryImmutableHint =>
      'La categoria non si può cambiare dopo la creazione.';

  @override
  String get budgetLimit => 'Limite mensile';

  @override
  String budgetPeriodLabel(String period) {
    return '$period';
  }

  @override
  String get budgetPeriodPrevious => 'Mese precedente';

  @override
  String get budgetPeriodNext => 'Mese successivo';

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent di $limit';
  }

  @override
  String get budgetAlert80 => 'Raggiunto l\'80% del budget';

  @override
  String get budgetAlert100 => 'Limite di budget raggiunto';

  @override
  String get goalsTitle => 'Obiettivi';

  @override
  String get goalsEmpty =>
      'Nessun obiettivo. Creane uno e traccia i versamenti virtuali.';

  @override
  String get goalCreateTitle => 'Nuovo obiettivo';

  @override
  String get goalEditTitle => 'Modifica obiettivo';

  @override
  String get goalName => 'Nome obiettivo';

  @override
  String get goalNameInvalid => 'Inserisci almeno 2 caratteri';

  @override
  String get goalTargetAmount => 'Importo obiettivo';

  @override
  String get goalDueDate => 'Scadenza';

  @override
  String get goalDueDateOptional => 'Opzionale';

  @override
  String goalDueDateLabel(String date) {
    return 'Scadenza $date';
  }

  @override
  String goalProgressLabel(String accumulated, String target) {
    return '$accumulated di $target';
  }

  @override
  String goalAccumulatedHint(String amount) {
    return 'Accumulato (server): $amount';
  }

  @override
  String get goalContributeTitle => 'Versamento';

  @override
  String get goalContributeAction => 'Versa / preleva';

  @override
  String get goalContributeHint =>
      'Solo virtuale — non modifica i saldi dei conti.';

  @override
  String get goalDeposit => 'Versa';

  @override
  String get goalWithdraw => 'Preleva';

  @override
  String get goalContributionsTitle => 'Versamenti recenti';

  @override
  String get goalContributionsEmpty => 'Nessun versamento ancora.';

  @override
  String get ingestionTitle => 'Coda di revisione';

  @override
  String get ingestionEmpty =>
      'Nessuna bozza da revisionare. Scansiona uno scontrino su Android per aggiungerne una.';

  @override
  String get ingestionReviewTitle => 'Revisiona bozza';

  @override
  String get ingestionUnknownMerchant => 'Esercente sconosciuto';

  @override
  String get ingestionStatusNeedsReview => 'Da revisionare';

  @override
  String get ingestionStatusPossibleDuplicate => 'Possibile duplicato';

  @override
  String get ingestionSourceReceiptOcr => 'Scansione scontrino';

  @override
  String get ingestionSourceNotification => 'Notifica';

  @override
  String get ingestionPossibleDuplicateHint =>
      'Potrebbe già esistere una transazione simile. Controlla prima di confermare.';

  @override
  String get ingestionConfirmAction => 'Conferma transazione';

  @override
  String get ingestionPeriodMismatchTitle => 'Data fuori dal mese corrente';

  @override
  String ingestionPeriodMismatchBody(
    String bookingDate,
    String bookingPeriod,
    String currentPeriod,
  ) {
    return 'Lo scontrino è del $bookingDate: conterà nel budget di $bookingPeriod, non in quello di $currentPeriod che stai guardando.';
  }

  @override
  String get ingestionUseReceiptDate => 'Usa data scontrino';

  @override
  String get ingestionUseTodayDate => 'Usa data di oggi';

  @override
  String get ingestionDiscardAction => 'Scarta';

  @override
  String get ingestionDiscardTitle => 'Scartare la bozza?';

  @override
  String get ingestionDiscardBody =>
      'La bozza verrà scartata. Non verrà creata alcuna transazione.';

  @override
  String get ingestionSaveMerchantRule =>
      'Ricorda categoria e conto per questo esercente';

  @override
  String get ingestionSaveMerchantRuleHint =>
      'Usato come suggerimento la prossima volta che compare questo esercente.';

  @override
  String get ingestionOpenQueue => 'Apri coda di revisione';

  @override
  String ingestionPendingCount(int count) {
    return '$count in attesa';
  }

  @override
  String ingestionFilterAll(int count) {
    return 'Tutte ($count)';
  }

  @override
  String ingestionFilterNotification(int count) {
    return 'Notifiche ($count)';
  }

  @override
  String ingestionFilterOcr(int count) {
    return 'Scontrino OCR ($count)';
  }

  @override
  String ingestionFilterDuplicates(int count) {
    return 'Possibili duplicati ($count)';
  }

  @override
  String get ingestionConfirmLedger => 'Conferma nel mastro';

  @override
  String get ingestionEmptyDoneTitle => 'Tutto in ordine!';

  @override
  String get ingestionEmptyDoneBody =>
      'Non ci sono altre bozze in attesa. Il libro mastro di famiglia è aggiornato.';

  @override
  String get ingestionEmptyGoDashboard => 'Torna alla Dashboard';

  @override
  String get ingestionSettingsCapture =>
      'Impostazioni acquisizione notifiche & OCR';

  @override
  String get ingestionUnreconciledTitle => 'Elementi non riconciliati';

  @override
  String get ingestionSortedByDate => 'Ordinati per data';

  @override
  String get ingestionSelectDraftHint =>
      'Seleziona una bozza per verificare e confermare';

  @override
  String get ingestionReviewVerifyTitle => 'Verifica & associazione spesa';

  @override
  String get ingestionInReview => 'In revisione';

  @override
  String get ingestionToConfirm => 'Da confermare';

  @override
  String get ingestionWebEyebrow => 'Staging & riconciliazione AI';

  @override
  String get receiptScanTitle => 'Scansiona scontrino';

  @override
  String get receiptScanAction => 'Scansiona scontrino';

  @override
  String get receiptScanBody =>
      'Scatta una foto o scegli un\'immagine. L\'app estrae importo, data ed esercente in una bozza da confermare — niente viene registrato in silenzio.';

  @override
  String get receiptScanCamera => 'Scatta foto';

  @override
  String get receiptScanGallery => 'Scegli dalla galleria';

  @override
  String get receiptScanProcessing => 'Lettura scontrino…';

  @override
  String get receiptScanAndroidOnlyTitle =>
      'Scansione scontrino solo su Android';

  @override
  String get receiptScanAndroidOnlyBody =>
      'L\'OCR on-device è disponibile solo su Android. Puoi comunque revisionare e confermare le bozze da questa coda.';

  @override
  String get receiptScanAndroidOnlyBanner =>
      'La scansione scontrini è disponibile su Android. Qui puoi revisionare le bozze.';

  @override
  String get notificationListenerTitle => 'Cattura notifiche di pagamento';

  @override
  String get notificationListenerEnabled =>
      'Listener attivo — le notifiche Wallet creano bozze da revisionare';

  @override
  String get notificationListenerDisabled =>
      'Listener spento — tocca per attivarlo nelle impostazioni di sistema';

  @override
  String get notificationListenerAndroidOnly =>
      'La cattura delle notifiche di pagamento è disponibile solo su Android. Qui puoi comunque revisionare le bozze.';

  @override
  String get notificationListenerOpenSettings => 'Apri accesso alle notifiche';

  @override
  String notificationDraftAlertTitle(int count) {
    return '$count bozze da revisionare';
  }

  @override
  String get notificationDraftAlertBody =>
      'Apri la coda di revisione per confermare o scartare. Niente viene registrato senza la tua conferma.';

  @override
  String get accountBindingsTitle => 'Associazioni conto notifiche';

  @override
  String get accountBindingsHint =>
      'Suggerisci un conto predefinito quando una bozza viene creata dalle notifiche di ciascuna app. Puoi comunque cambiarlo prima di confermare.';

  @override
  String get accountBindingsEmpty => 'Nessun pacchetto notifiche configurato.';

  @override
  String get accountBindingsNone => 'Nessun conto';

  @override
  String get accountBindingsOpen => 'Associazioni conto';
}
