// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
///
/// NOTE: This class extends English and overrides only keys we translated now.
/// Missing keys will gracefully fall back to English.
class AppLocalizationsIt extends AppLocalizationsEn {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get timeTracker => 'Rilevazione tempi';

  @override
  String get history => 'Cronologia';

  @override
  String get team => 'Team';

  @override
  String get timeOff => 'Permessi';

  @override
  String get members => 'Membri';

  @override
  String get projects => 'Progetti';

  @override
  String get clients => 'Clienti';

  @override
  String get admin => 'Admin';
  
  @override
  String get accountLocked => 'Account temporaneamente bloccato';
  
  @override
  String get tooManyFailedAttempts => 'Troppi tentativi di accesso falliti';
  
  @override
  String accountLockedMessage(int minutes) => 'Account bloccato a causa di troppi tentativi falliti. Riprova tra $minutes minuti.';
  
  @override
  String remainingAttempts(int attempts) => '$attempts tentativi di accesso rimanenti';
  
  @override
  String get accountUnlocked => 'Account sbloccato';
  
  @override
  String get accountUnlockedMessage => 'Il tuo account è stato sbloccato. Ora puoi provare ad accedere di nuovo.';
  
  @override
  String get adminPasswordRequired => 'Password amministratore richiesta';

  @override
  String get settings => 'Impostazioni';

  @override
  String get calendar => 'Calendario';

  @override
  String get balance => 'Saldo';

  @override
  String get requests => 'Richieste';

  // Time Off - Requests
  @override
  String get searchRequests => 'Cerca richieste';

  @override
  String get requestButton => 'Richiesta';

  @override
  String get failedToLoadRequests => 'Caricamento richieste non riuscito';

  @override
  String get noRequests => 'Nessuna richiesta';

  @override
  String get unknownPolicy => 'Regola sconosciuta';

  @override
  String get newTimeOffRequest => 'Nuova richiesta di permesso';

  @override
  String get policy => 'Regola';

  @override
  String get descriptionOptional => 'Descrizione (opzionale)';

  @override
  String get submitRequest => 'Invia richiesta';

  @override
  String get pickDates => 'Seleziona date';

  @override
  String get selectedRange => 'Intervallo date';

  // Reports
  @override
  String get report => 'Rapporto';
  @override
  String get reports => 'Rapporti';
  @override
  String get createReport => 'Rapporto';
  @override
  String get reportName => 'Nome report';
  @override
  String get reportOrientation => 'Orientamento report';
  @override
  String get selectFields => 'Seleziona campi';
  @override
  String get filters => 'Filtri';

  @override
  String get runReport => 'Esegui report';
  @override
  String get deleteSuccessful => 'Eliminato con successo';

  // Timeline labels
  @override
  String get teamMember => 'Membro del team';

  @override
  String get weekAbbreviation => 'S';

  @override
  String get resetToThisWeek => 'Ripristina a questa settimana';

  @override
  String get personal => 'Personale';

  @override
  String get error => 'Errore';

  @override
  String get noMembersFound => 'Nessun membro trovato';

  @override
  String get unknownUser => 'Utente sconosciuto';

  // App shell/system
  @override
  String get systemMaintenance =>
      'Il sistema è in manutenzione. Riprova più tardi.';
  @override
  String get userNotFoundInCompany => 'Utente non trovato nell\'azienda.';
  @override
  String get noCompaniesFound => 'Nessuna azienda trovata.';
  @override
  String get userNotAssigned => 'Utente non assegnato a nessuna azienda.';

  @override
  String get all => 'Tutti';

  @override
  String get denyRequest => 'Rifiuta richiesta';

  @override
  String get deny => 'Rifiuta';

  // Calendar widget strings
  @override
  String get startingDayOfWeek => 'Primo giorno della settimana';
  @override
  String get monday => 'Lunedì';
  @override
  String get tuesday => 'Martedì';
  @override
  String get wednesday => 'Mercoledì';
  @override
  String get thursday => 'Giovedì';
  @override
  String get friday => 'Venerdì';
  @override
  String get saturday => 'Sabato';
  @override
  String get sunday => 'Domenica';
  @override
  String get calendarSettings => 'Impostazioni calendario';
  @override
  String get clear => 'Cancella';
  @override
  String get showWeekNumbers => 'Mostra numeri settimana';
  @override
  String get manager => 'Responsabile';
  @override
  String get changesSaved => 'Modifiche salvate con successo!';

  // Common UI
  @override
  String get add => 'Aggiungi';

  @override
  String get edit => 'Modifica';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get view => 'Vedi';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get from => 'Da';

  @override
  String get to => 'A';

  @override
  String get day => 'Giorno';

  @override
  String get week => 'Settimana';

  @override
  String get month => 'Mese';

  @override
  String get monthly => 'mensile';

  @override
  String get year => 'Anno';

  @override
  String get project => 'Progetto';

  @override
  String get note => 'Nota';

  @override
  String get clearFilters => 'Pulisci filtri';

  @override
  String get deleteSession => 'Elimina sessione';

  @override
  String get sessionDate => 'Data';

  @override
  String get time => 'Ora';

  @override
  String get approve => 'Approva';

  @override
  String get reject => 'Rifiuta';

  @override
  String get totalTime => 'Tempo totale';

  @override
  String get totalExpenses => 'Spese totali';

  @override
  String get expensesTitle => 'Spese';

  @override
  String get nameLabel => 'Nome';

  @override
  String get amountLabel => 'Importo';

  @override
  String get addLabel => 'Aggiungi';

  @override
  String get cancelLabel => 'Annulla';

  @override
  String get saveLabel => 'Salva';

  @override
  String get editTimeLog => 'Modifica registrazione';

  @override
  String get start => 'Inizio';

  @override
  String get end => 'Fine';

  @override
  String get projectLabel => 'Progetto';

  @override
  String get selectProject => 'Seleziona progetto';

  @override
  String get noteLabel => 'Nota';

  @override
  String get expenses => 'Spese';

  @override
  String get tapToAdd => 'Tocca per aggiungere';

  @override
  String get endBeforeStart => 'Fine prima dell\'inizio';

  @override
  String get addNewSession => 'Aggiungi nuova sessione';

  @override
  String get startAndEndTimesCannotBeEmpty =>
      'Gli orari di inizio e fine non possono essere vuoti';

  // Projects/Clients
  @override
  String get searchByProject => 'Cerca per progetto';

  @override
  String get searchByClient => 'Cerca per cliente';

  @override
  String get addNewProject => 'Aggiungi nuovo progetto';

  @override
  String get noProjectsFound => 'Nessun progetto trovato.';

  @override
  String get projectsForThisClient => 'Progetti per questo cliente';

  @override
  String get clientSummary => 'Riepilogo cliente';

  @override
  String get total => 'Totale';

  @override
  String get projectId => 'ID progetto';

  @override
  String get projectRef => 'Rif. progetto';

  @override
  String get clientName => 'Nome cliente';

  @override
  String get contactPerson => 'Referente';

  @override
  String get address => 'Indirizzo';

  @override
  String get email => 'E-mail';
  @override
  String get enterYourEmail => 'Inserisci il tuo indirizzo e-mail';
  @override
  String get enterYourPassword => 'Inserisci la tua password';

  @override
  String get password => "Parola d'accesso";

  String get forgotPassword => 'Password dimenticata';

  @override
  String get home => 'Home';

  @override
  String get features => 'Funzionalità';

  @override
  String get pricing => 'Prezzi';

  @override
  String get getStarted => 'Inizia';

  @override
  String get aboutUs => 'Chi siamo';

  @override
  String get getInTouch => 'Mettiti in contatto';

  @override
  String get sendUsMessage => 'Inviaci un messaggio';

  @override
  String get fullName => 'Nome completo';

  @override
  String get enterFullName => 'Inserisci il tuo nome completo';

  @override
  String get emailAddress => 'Indirizzo e-mail';

  @override
  String get enterEmailAddress => 'Inserisci il tuo indirizzo e-mail';

  @override
  String get company => 'Azienda';

  @override
  String get enterCompanyName => 'Inserisci il nome della tua azienda';

  @override
  String get message => 'Messaggio';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get pleaseEnterName => 'Inserisci il tuo nome';

  @override
  String get pleaseEnterEmail => 'Inserisci la tua e-mail';

  @override
  String get pleaseEnterValidEmail => 'Inserisci un indirizzo e-mail valido';

  @override
  String get pleaseEnterMessage => 'Inserisci il tuo messaggio';

  @override
  String get notProvided => 'Non fornito';

  @override
  String get timeTrackingMadeSimple => 'Tracciamento del tempo semplificato';

  @override
  String get professionalTimeTracking => 'Tracciamento del tempo professionale e gestione progetti per team di tutte le dimensioni. Accesso da qualsiasi dispositivo - desktop, tablet o mobile. Traccia il tempo, gestisci progetti e aumenta la produttività.';

  @override
  String get startFreeTrial => 'Inizia prova gratuita';

  @override
  String get watchDemo => 'Guarda demo';

  @override
  String get dashboardPreview => 'Anteprima dashboard';

  @override
  String get everythingYouNeedToTrackTime => 'Tutto quello che ti serve per tracciare il tempo';

  @override
  String get powerfulFeaturesDesigned => 'Funzionalità potenti progettate per semplificare il tuo flusso di lavoro';

  @override
  String get timeTracking => 'Tracciamento del tempo';

  @override
  String get trackTimeWithPrecision => 'Traccia il tempo con precisione. Avvia, ferma e gestisci le tue sessioni di lavoro senza sforzo.';

  @override
  String get teamManagement => 'Gestione team';

  @override
  String get manageYourTeam => 'Gestisci il tuo team, assegna progetti e traccia i progressi di tutti in tempo reale.';

  @override
  String get projectManagement => 'Gestione progetti';

  @override
  String get organizeAndTrack => 'Organizza e traccia tutti i tuoi progetti in un unico posto. Imposta scadenze, assegna attività e monitora i progressi.';

  @override
  String get mobileResponsive => 'Responsive mobile';

  @override
  String get accessFromAnywhere => 'Accedi ai tuoi dati di tracciamento del tempo da qualsiasi luogo. Funziona perfettamente su desktop, tablet e dispositivi mobili.';

  @override
  String get howItWorks => 'Come funziona';

  @override
  String get signUp => 'Contattaci';

  @override
  String get startTracking => 'Inizia tracciamento';

  @override
  String get reportsAnalytics => 'Report e analisi';

  @override
  String get generateDetailedReports => 'Genera report dettagliati e insights per ottimizzare la produttività del tuo team.';

  @override
  String get secureReliable => 'Sicuro e affidabile';

  @override
  String get dataSafeWithEnterprise => 'I tuoi dati sono al sicuro con sicurezza di livello enterprise e garanzia di uptime del 99,9%.';

  @override
  String get createAccountAndSetup => 'Contattaci per una consulenza e organizzeremo il piano perfetto per le tue esigenze.';

  @override
  String get beginTrackingTime => 'Inizia a tracciare il tempo su progetti e attività immediatamente.';

  @override
  String get analyzeAndImprove => 'Analizza e migliora';

  @override
  String get reviewReportsAndOptimize => 'Rivedi i report e ottimizza la produttività del tuo team.';

  @override
  String get simpleTransparentPricing => 'Prezzi semplici e trasparenti';

  @override
  String get choosePlanThatFits => 'Scegli il piano che si adatta alle dimensioni del tuo team';

  @override
  String get demoTrial => 'Versione demo';

  @override
  String get tryBeforeYouBuy => 'Prova prima di acquistare';

  @override
  String get fourteenDayFreeTrial => 'Prova gratuita di 14 giorni';

  @override
  String get fullAccessToAllFeatures => 'Accesso completo a tutte le funzionalità';

  @override
  String get upToFiveUsers => 'Fino a 5 utenti';

  @override
  String get emailSupport => 'Supporto via email';

  @override
  String get noCreditCardRequired => 'Nessuna carta di credito richiesta';

  @override
  String get starter => 'Starter';

  @override
  String get perfectForIndividuals => 'Perfetto per i singoli';

  @override
  String get basicTimeTracking => 'Tracciamento del tempo di base';

  @override
  String get mobileWebAccess => 'Accesso web mobile';

  @override
  String get professional => 'Professionale';

  @override
  String get bestForSmallTeams => 'Ideale per piccoli team';

  @override
  String get bestForMediumTeams => 'Ideale per team medi';

  @override
  String get starterPrice => 'CHF 5';

  @override
  String get professionalPrice => 'CHF 9';

  @override
  String get perUser => '-per utente-';

  @override
  String get free => 'Gratuito';

  @override
  String get custom => 'Personalizzato';

  @override
  String get unlimitedProjects => 'Progetti illimitati';

  @override
  String get advancedReporting => 'Reportistica avanzata';

  @override
  String get timeOffManagement => 'Gestione ferie';

  @override
  String get prioritySupport => 'Supporto prioritario';

  @override
  String get integrations => 'Integrazioni';

  @override
  String get enterprise => 'Enterprise';

  @override
  String get forLargeOrganizations => 'Per grandi organizzazioni';

  @override
  String get everythingInProfessional => 'Tutto quello che c\'è in Professionale';

  @override
  String get customIntegrations => 'Integrazioni personalizzate';

  @override
  String get customReporting => 'Reportistica personalizzata';

  @override
  String get dedicatedSupport => 'Supporto dedicato';

  @override
  String get mostPopular => 'Più popolare';

  @override
  String get readyToGetStarted => 'Pronto a iniziare?';

  @override
  String get joinOtherTeams => 'Unisciti agli altri team che già utilizzano Stark Track per aumentare la tua produttività.';

  @override
  String get startYourFreeTrial => 'Inizia la tua prova gratuita';

  @override
  String get professionalTimeTrackingForTeams => 'Tracciamento del tempo professionale e gestione progetti per team.';

  @override
  String get allRightsReserved => 'Tutti i diritti riservati.';

  @override
  String get haveQuestionsAboutStarkTrack => 'Hai domande su Stark Track? Ci piacerebbe sentirti!';

  @override
  String get phone => 'Telefono';

  @override
  String get city => 'Città';

  @override
  String get country => 'Paese';

  @override
  String get noTimeLogsFound =>
      'Nessuna registrazione oraria per questo lavoratore.';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get perDiem => 'Diaria';

  @override
  String get overtime => 'Straordinari';

  @override
  String get vacations => 'Vacanze';

  @override
  String get type => 'Tipo';

  @override
  String get bonus => 'Bonus';

  @override
  String get updatedSuccessfully => 'aggiornato con successo';

  @override
  String get transferred => 'Trasferito';

  @override
  String get current => 'Attuale';

  @override
  String get used => 'Utilizzato';

  @override
  String get available => 'Disponibile';

  @override
  String get calculatingOvertime => 'Calcolo straordinari dai log...';

  @override
  String get noOvertimeData => 'Nessun dato straordinario disponibile';

  @override
  String get failedToUpdateBonus => 'Impossibile aggiornare il valore del bonus';

  // Missing Report System Translations
  @override
  String get starkTrackDetailedSessionReport => 'Stark Track - Rapporto Sessione Dettagliato';
  
  @override
  String get reportNameLabel => 'Nome Rapporto:';
  
  @override
  String get reportRange => 'Intervallo Rapporto:';
  
  @override
  String get reportType => 'Tipo Rapporto:';
  
  @override
  String get generated => 'Generato:';
  
  @override
  String get totalSessions => 'Sessioni Totali:';
  
  @override
  String get clientLabel => 'Cliente:';
  
  @override
  String get userLabel => 'Utente:';
  
  @override
  String get totalProjects => 'Progetti Totali:';
  
  @override
  String get overtimeBalance => 'Saldo Ore Straordinarie:';
  
  @override
  String get vacationBalance => 'Saldo Vacanze:';
  
  @override
  String get ref => 'Ref:';
  
  @override
  String get totalHours => 'Ore Totali';
  
  @override
  String get totalOvertime => 'Ore Straordinarie Totali';
  
  @override
  String get pleaseSelectAtLeastOneField => 'Seleziona almeno un campo';
  
  @override
  String get excelFileExportedSuccessfully => 'File Excel esportato con successo!';
  
  @override
  String get excelFileWithMultipleUserSheetsExportedSuccessfully => 'File Excel con più fogli utente esportato con successo!';
  
  @override
  String get excelFileWithMultipleProjectSheetsExportedSuccessfully => 'File Excel con più fogli progetto esportato con successo!';
  
  @override
  String get excelFileWithMultipleClientSheetsExportedSuccessfully => 'File Excel con più fogli cliente esportato con successo!';
  
  @override
  String get exportFailed => 'Esportazione fallita:';
  
  @override
  String get failedToGenerateReport => 'Generazione rapporto fallita:';
  
  // Report Builder Dialog
  @override
  String get dateRange => 'Intervallo di date';
  
  @override
  String get workers => 'Lavoratori';
  
  @override
  String get fields => 'Campi';
  
  @override
  String get workerName => 'Nome del lavoratore';
  
  // Missing translations
  @override
  String get duration => 'Durata';
  
  @override
  String get worker => 'Lavoratore';
  
  @override
  String get pending => 'In attesa';
  
  @override
  String get date => 'Data';
  
  // Report Builder Dialog - Missing translations
  @override
  String get selectDateRange => 'Seleziona intervallo di date';
  
  @override
  String get allWorkers => 'Tutti i lavoratori';
  
  @override
  String get allProjects => 'Tutti i progetti';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get contactPersonName => 'Nome del contatto';
  
  @override
  String get contactPersonSurname => 'Cognome del contatto';
  
  @override
  String get companyAddress => 'Indirizzo aziendale';
  
  @override
  String get numberOfWorkers => 'Numero di dipendenti';
  
  @override
  String get phoneNumber => 'Numero di telefono';
  
  @override
  String get interestedIn => 'Interessato a';
  
  @override
  String get enterInterestedIn => 'Inserisci quello che ti interessa';

  @override
  String get ourStory => 'La Nostra Storia';
  
  @override
  String get ourStoryContent => 'Stark Track è nato da un bisogno semplice: rendere il tracciamento del tempo senza sforzo e potente per team di tutte le dimensioni. Crediamo che quando i team possono facilmente tracciare il loro tempo e gestire i loro progetti, possono concentrarsi su ciò che conta di più - fornire un ottimo lavoro.';
  
  @override
  String get ourMission => 'La Nostra Missione';
  
  @override
  String get ourMissionContent => 'Dare potere ai team con strumenti intuitivi di tracciamento del tempo e gestione dei progetti che aumentano la produttività e forniscono preziose informazioni su come viene speso il tempo.';
  
  @override
  String get ourValues => 'I Nostri Valori';
  
  @override
  String get ourValuesContent => 'Siamo impegnati nella semplicità, affidabilità ed esperienza utente. Ogni funzione che costruiamo è progettata con i nostri utenti in mente, garantendo che il tracciamento del tempo migliori piuttosto che ostacolare la produttività.';
  
  @override
  String get whyChooseStarkTrack => 'Perché scegliere Stark Track?';
  
  @override
  String get whyChooseStarkTrackContent => '• Interfaccia semplice e intuitiva\n• Funziona su qualsiasi dispositivo - desktop, tablet o mobile\n• Report e analisi potenti\n• Sicuro e affidabile\n• Prezzi accessibili per team di tutte le dimensioni\n• Eccellente supporto clienti';
  
  @override
  String get enterContactPersonName => 'Inserisci il nome del contatto';
  
  @override
  String get enterContactPersonSurname => 'Inserisci il cognome del contatto';
  
  @override
  String get enterCompanyAddress => 'Inserisci l\'indirizzo aziendale';
  
  @override
  String get enterNumberOfWorkers => 'Inserisci il numero di dipendenti';
  
  @override
  String get enterPhoneNumber => 'Inserisci il numero di telefono';
  
  @override
  String get pleaseEnterContactPersonName => 'Inserisci il nome del contatto';
  
  @override
  String get pleaseEnterContactPersonSurname => 'Inserisci il cognome del contatto';
  
  @override
  String get pleaseEnterPhoneNumber => 'Inserisci il numero di telefono';
  
  @override
  String get pleaseEnterValidPhoneNumber => 'Inserisci un numero di telefono valido';
  
  @override
  String get allClients => 'Tutti i clienti';
  
  // Report Cards
  @override
  String get created => 'Creato';
  
  // Report Viewer Dialog
  @override
  String get export => 'Esporta';
  
  @override
  String get exportReport => 'Esporta rapporto';
  
  @override
  String get csv => 'CSV';
  
  @override
  String get excel => 'Excel';
  
  @override
  String get retry => 'Riprova';
  
  @override
  String get noDataFoundForThisReport => 'Nessun dato trovato per questo rapporto';
  
  @override
  String get detailedSessionReport => 'Rapporto di sessione dettagliato';
  
  @override
  String get detailedReport => 'Rapporto dettagliato';
  
  @override
  String get unnamedReport => 'Rapporto senza nome';
  
  @override
  String get unnamedProject => 'Progetto senza nome';
  
  @override
  String get unnamedClient => 'Cliente senza nome';
  
  @override
  String get startTime => 'Ora di inizio';
  
  @override
  String get endTime => 'Ora di fine';
  
  @override
  String get notes => 'Note';
  
  @override
  String get usersInvolved => 'Utenti coinvolti';
  
  @override
  String get projectsWorked => 'Progetti lavorati';
  
  @override
  String get status => 'Stato';
  
  @override
  String get overtimeHours => 'Ore straordinarie';
  
  @override
  String get vacationDays => 'Giorni di vacanza';
  
  @override
  String get efficiencyRating => 'Valutazione efficienza';
  
  @override
  String get expenseType => 'Tipo di spesa';
  
  @override
  String get description => 'Descrizione';
  
  @override
  String get noActivity => 'Nessuna attività';
  
  @override
  String get inactive => 'Inattivo';
  
  @override
  String get mixed => 'Misto';
  
  @override
  String get noData => 'Nessun dato';
  
  @override
  String get notSpecified => 'Non specificato';
  
  @override
  String get summary => 'Riepilogo';
  
  @override
  String get noSessionsFoundForThisUserInTheSelectedPeriod => 'Nessuna sessione trovata per questo utente nel periodo selezionato';
  
  @override
  String get noSessionsFoundForThisProjectInTheSelectedPeriod => 'Nessuna sessione trovata per questo progetto nel periodo selezionato';
  
  @override
  String get noProjectsFoundForThisClientInTheSelectedPeriod => 'Nessun progetto trovato per questo cliente nel periodo selezionato';
  
  @override
  String get noDataAvailableForThisReport => 'Nessun dato disponibile per questo rapporto';
  
  @override
  String get reference => 'Riferimento';
  
  @override
  String get startEnd => 'Inizio - Fine';
  
  @override
  String get chooseExportFormat => 'Scegli il formato di esportazione:';
  
  @override
  String get csvExportedSuccessfully => 'CSV esportato con successo!';
  
  @override
  String get avgHoursPerDay => 'Ore medie/Giorno';
  
  @override
  String get sessions => 'Sessioni';
  
  @override
  String get sessionCount => 'Numero di sessioni';
  
  @override
  String get exportExcel => 'Esporta Excel';
  
  @override
  String get reportRangeLabel => 'Intervallo di report:';
  
  @override
  String get overtimeLabel => 'Ore straordinarie:';
  
  @override
  String get weekPrefix => 'S';
  
  @override
  String get clientReport => 'cliente';
  
  @override
  String get multiProjectReport => 'progetto';
  
  @override
  String get multiUserReport => 'lavoratore';
}
