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
