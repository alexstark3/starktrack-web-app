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
}
