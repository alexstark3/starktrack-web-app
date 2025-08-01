// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Stark Track';

  @override
  String get timeTracker => 'Zeiterfassung';

  @override
  String get history => 'Verlauf';

  @override
  String get team => 'Team';

  @override
  String get members => 'Mitglieder';

  @override
  String get projects => 'Projekte';

  @override
  String get clients => 'Kunden';

  @override
  String get admin => 'Administration';

  @override
  String get settings => 'Einstellungen';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get firstName => 'Vorname';

  @override
  String get surname => 'Nachname';

  @override
  String get phone => 'Telefon';

  @override
  String get address => 'Adresse';

  @override
  String get search => 'Suchen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get start => 'Start';

  @override
  String get end => 'Ende';

  @override
  String get project => 'Projekt';

  @override
  String get note => 'Notiz';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get perDiem => 'Spesen';

  @override
  String get worked => 'Gearbeitet';

  @override
  String get breaks => 'Pausen';

  @override
  String get total => 'Gesamt';

  @override
  String get approved => 'Genehmigt';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get pending => 'Ausstehend';

  @override
  String get darkMode => 'Dunkel Mod';

  @override
  String get language => 'Sprache';

  @override
  String get today => 'Heute';

  @override
  String get noLogsForThisDay => 'Keine Einträge für diesen Tag';

  @override
  String get addNewUser => 'Neuer Benutzer';

  @override
  String get addNewClient => 'Neuen Kunden hinzufügen';

  @override
  String get addNewProject => 'Hinzufügen';

  @override
  String get addHolidayPolicy => 'Urlaubsrichtlinie';

  @override
  String get addTimeOffPolicy => 'Freizeitrichtlinie';

  @override
  String get searchByName => 'Nach Namen suchen';

  @override
  String get searchByEmail => 'Nach E-Mail suchen';

  @override
  String get searchByProject => 'Nach Projekt suchen';

  @override
  String get searchByClient => 'Nach Kunde suchen';

  @override
  String get contactPerson => 'Kontaktperson';

  @override
  String get country => 'Land';

  @override
  String get city => 'Stadt';

  @override
  String get duration => 'Dauer';

  @override
  String get worker => 'Mitarbeiter';

  @override
  String get actions => 'Aktionen';

  @override
  String get view => 'Anzeigen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get filter => 'Filter';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get groupBy => 'Gruppieren nach';

  @override
  String get day => 'Tag';

  @override
  String get week => 'Woche';

  @override
  String get month => 'Monat';

  @override
  String get year => 'Jahr';

  @override
  String get overtime => 'Überstunden';

  @override
  String get totalExpenses => 'Gesamtausgaben';

  @override
  String get totalTime => 'Gesamtzeit';

  @override
  String get weeklyHours => 'Wochenstunden';

  @override
  String get workload => 'Arbeitslast';

  @override
  String get active => 'Aktiv';

  @override
  String get roles => 'Rollen';

  @override
  String get modules => 'Module';

  @override
  String get teamLeader => 'Teamleiter';

  @override
  String get passwordManualEntry => 'Passwort (manuelle Eingabe)';

  @override
  String get passwordMinLength => 'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get editUser => 'Benutzer bearbeiten';

  @override
  String get addNewSession => 'Neue Zeiterfassung';

  @override
  String get approvalNote => 'Genehmigungsnotiz (optional)';

  @override
  String get noMembersFound => 'Keine Mitglieder gefunden.';

  @override
  String get noProjectsFound => 'Keine Projekte gefunden.';

  @override
  String get noClientsFound => 'Keine Kunden gefunden.';

  @override
  String get noTimeLogsFound => 'Keine Zeiteinträge für diesen Mitarbeiter gefunden.';

  @override
  String errorLoadingProjects(String error) {
    return 'Fehler beim Laden der Projekte: $error';
  }

  @override
  String get noProjectsFoundInFirestore => 'Keine Projekte in Firestore gefunden.';

  @override
  String get projectId => 'Projekt-ID';

  @override
  String get clientName => 'Kundenname';

  @override
  String get personName => 'Personenname';

  @override
  String get optional => 'optional';

  @override
  String get companyAdmin => 'Firmenadministrator';

  @override
  String get required => 'erforderlich';

  @override
  String get createHolidayPolicy => 'Urlaubsrichtlinie erstellen';

  @override
  String get editHolidayPolicy => 'Urlaubsrichtlinie bearbeiten';

  @override
  String get policyName => 'Richtlinienname';

  @override
  String get color => 'Farbe';

  @override
  String get customColor => 'Benutzerdefinierte Farbe';

  @override
  String get date => 'Datum';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get assignToEveryone => 'Allen zuweisen';

  @override
  String get regionFilter => 'Regionsfilter';

  @override
  String get filterByRegion => 'Nach Region filtern';

  @override
  String get repeatsAnnually => 'Jährlich wiederholen';

  @override
  String get national => 'National';

  @override
  String get repeats => 'Wiederholt';

  @override
  String get assignedTo => 'Zugewiesen an';

  @override
  String get accruing => 'Ansparung';

  @override
  String get per => 'pro';

  @override
  String get timeUnit => 'Zeiteinheit';

  @override
  String get doesNotCount => 'Zählt nicht';

  @override
  String get holidays => 'Feiertage';

  @override
  String get timeOffPolicies => 'Urlaubsrichtlinien:';

  @override
  String get includeOvertime => 'Überstunden einschließen';

  @override
  String get negativeBalance => 'Negativer Saldo';

  @override
  String get days => 'Tage';

  @override
  String get editTimeOffPolicy => 'Urlaubsrichtlinie bearbeiten';

  @override
  String get createTimeOffPolicy => 'Urlaubsrichtlinie erstellen';

  @override
  String get paid => 'Bezahlt';

  @override
  String get hours => 'Stunden';

  @override
  String get chooseAllThatApply => 'Wählen Sie alle zutreffenden:';

  @override
  String get allHolidays => 'Alle Feiertage';

  @override
  String get update => 'Aktualisieren';

  @override
  String get error => 'Fehler';

  @override
  String get everyone => 'Alle';

  @override
  String get selection => 'Auswahl';

  @override
  String get enterPolicyName => 'Richtliniennamen eingeben';

  @override
  String get yearly => 'Jährlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get ok => 'OK';

  @override
  String get weeks => 'Wochen';

  @override
  String get months => 'Monate';

  @override
  String get years => 'Jahre';

  @override
  String get noTimeOffPoliciesFound => 'Keine Urlaubsrichtlinien gefunden';

  @override
  String get noHolidayPoliciesFound => 'Keine Urlaubsrichtlinien gefunden';

  @override
  String get pleaseEnterPolicyName => 'Bitte geben Sie einen Richtliniennamen ein';

  @override
  String get pleaseSelectDate => 'Bitte wählen Sie ein Datum';

  @override
  String get pickAColor => 'Farbe auswählen';

  @override
  String get region => 'Region';

  @override
  String get assignToUsers => 'Benutzern/Gruppen zuweisen';

  @override
  String get searchUsers => 'Benutzer suchen...';

  @override
  String get searchGroups => 'Gruppen suchen...';

  @override
  String get users => 'Benutzer';

  @override
  String get groups => 'Gruppen';

  @override
  String get noUsersFound => 'Keine Benutzer gefunden, die Ihrer Suche entsprechen';

  @override
  String get noGroupsFound => 'Keine Gruppen gefunden';

  @override
  String get searchUsersAndGroups => 'Benutzer und Gruppen suchen...';

  @override
  String get noUsersOrGroupsFound => 'Keine Benutzer oder Gruppen gefunden';

  @override
  String get user => 'Benutzer';

  @override
  String get group => 'Gruppe';

  @override
  String get holidayPolicies => 'Urlaubsrichtlinien';

  @override
  String get createNew => 'Neu erstellen';

  @override
  String get deleteHolidayPolicy => 'Urlaubsrichtlinie löschen';

  @override
  String get deleteHolidayPolicyConfirm => 'Sind Sie sicher, dass Sie löschen möchten';

  @override
  String get holidayPolicyDeleted => 'Urlaubsrichtlinie erfolgreich gelöscht';

  @override
  String get includesHistory => 'enthält Verlauf';

  @override
  String get additionalModules => 'Zusätzliche Module';

  @override
  String get showBreaks => 'Pausen anzeigen';

  @override
  String get assignToTeamLeader => 'Teamleiter zuweisen';

  @override
  String get none => 'Keine';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get createUser => 'Benutzer erstellen';

  @override
  String get sendPasswordResetEmail => 'Passwort-Reset-E-Mail senden';

  @override
  String passwordResetEmailSent(String email) {
    return 'Passwort-Reset-E-Mail an $email gesendet';
  }

  @override
  String failedToSendResetEmail(String error) {
    return 'Fehler beim Senden der Reset-E-Mail: $error';
  }

  @override
  String get searchByNameEmailRole => 'Nach Name, E-Mail oder Rolle suchen';

  @override
  String get confirmDelete => 'Löschen bestätigen';

  @override
  String get confirmDeleteMessage => 'Sind Sie sicher, dass Sie diesen Benutzer löschen möchten?';

  @override
  String get firstNameSurnameEmailRequired => 'Vorname, Nachname und E-Mail sind erforderlich!';

  @override
  String get atLeastOneRoleRequired => 'Mindestens eine Rolle ist erforderlich!';

  @override
  String get atLeastOneModuleRequired => 'Mindestens ein Modul ist erforderlich!';

  @override
  String get passwordMustBeAtLeast6Characters => 'Das Passwort muss mindestens 6 Zeichen lang sein!';

  @override
  String get userWithThisEmailAlreadyExists => 'Ein Benutzer mit dieser E-Mail existiert bereits.';

  @override
  String get onlySuperAdminCanEditCompanyAdmin => 'Nur Super-Admin kann den Firmenadministrator bearbeiten.';

  @override
  String get authError => 'Authentifizierungsfehler';

  @override
  String permissionDenied(String error) {
    return 'Zugriff verweigert: $error';
  }

  @override
  String unknownError(String error) {
    return 'Unbekannter Fehler: $error';
  }

  @override
  String get selectProject => 'Projekt auswählen';

  @override
  String get name => 'Name';

  @override
  String get amount => 'Betrag';

  @override
  String get perDiemAmount => '16.00 CHF';

  @override
  String get perDiemAlreadyUsed => 'Spesen bereits für diesen Tag verwendet';

  @override
  String get perDiemAlreadyEntered => 'Spesen bereits heute eingegeben';

  @override
  String get startAndEndTimesCannotBeEmpty => 'Start- und Endzeiten dürfen nicht leer sein';

  @override
  String get endTimeMustBeAfterStartTime => 'Endzeit muss nach Startzeit liegen';

  @override
  String get timeOverlap => 'Fehler: Zeitüberschneidung';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get noLogsFound => 'Keine Einträge gefunden.';

  @override
  String get noEntriesMatchFilters => 'Keine Einträge entsprechen Ihren Filtern.';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get addNew => 'Hinzufügen';

  @override
  String get searchByClientNamePersonEmail => 'Nach Kundenname, Person oder E-Mail suchen';

  @override
  String get contact => 'Kontakt';

  @override
  String get searchByNameSurnameEmail => 'Nach Name, Nachname oder E-Mail suchen';

  @override
  String get role_admin => 'Admin';

  @override
  String get role_team_leader => 'Teamleiter';

  @override
  String get role_company_admin => 'Firmenadmin';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get role_user => 'Benutzer';

  @override
  String get role_worker => 'Mitarbeiter';

  @override
  String get module_admin => 'Verwaltung';

  @override
  String get module_time_tracker => 'Zeiterfassung';

  @override
  String get module_team => 'Teamverwaltung';

  @override
  String get module_history => 'Verlauf';

  @override
  String get deleteSession => 'Sitzung löschen';

  @override
  String get sessionDeletedSuccessfully => 'Sitzung erfolgreich gelöscht';

  @override
  String get approve => 'Genehmigen';

  @override
  String get reject => 'Ablehnen';

  @override
  String get editTimeLog => 'Zeiteintrag bearbeiten';

  @override
  String get tapToAdd => 'Tippen zum Hinzufügen';

  @override
  String get perDiemAlreadyUsedInAnotherSession => 'Spesen bereits in einer anderen Sitzung heute verwendet';

  @override
  String get projectName => 'Projektname';

  @override
  String get street => 'Straße';

  @override
  String get number => 'Nummer';

  @override
  String get postCode => 'PLZ';

  @override
  String get client => 'Kunde';

  @override
  String get createNewClient => 'Neuen Kunden erstellen';

  @override
  String get clientMustBeSelectedOrCreated => 'Kunde muss ausgewählt oder erstellt werden';

  @override
  String get editProject => 'Projekt bearbeiten';

  @override
  String get projectRef => 'Projekt-Ref';

  @override
  String get clientDetails => 'Kundendetails';

  @override
  String get expensesTitle => 'Ausgaben';

  @override
  String get nameLabel => 'Name';

  @override
  String get amountLabel => 'Betrag';

  @override
  String get addLabel => 'Hinzufügen';

  @override
  String get cancelLabel => 'Abbrechen';

  @override
  String get saveLabel => 'Speichern';

  @override
  String get projectLabel => 'Projekt';

  @override
  String get noteLabel => 'Notiz';

  @override
  String perDiemLabel(String amount) {
    return 'Spesen $amount CHF';
  }

  @override
  String get endBeforeStart => 'Ende vor Start';

  @override
  String get sessionDate => 'Datum';

  @override
  String get time => 'Zeit';

  @override
  String get cannotBeEdited => 'kann nicht bearbeitet werden';

  @override
  String get cannotBeDeleted => 'kann nicht gelöscht werden';

  @override
  String get deleteEntry => 'Eintrag löschen';

  @override
  String get deleteEntryMessage => 'Sind Sie sicher, dass Sie diesen Eintrag löschen möchten? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get work => 'Arbeit';

  @override
  String get tapToAddNote => 'Tippen zum Hinzufügen einer Notiz';

  @override
  String get approvedAfterEdit => 'Nach Bearbeitung genehmigt';

  @override
  String get noNote => 'Keine Notiz';

  @override
  String get accountLocked => 'Konto vorübergehend gesperrt';

  @override
  String get tooManyFailedAttempts => 'Zu viele fehlgeschlagene Anmeldeversuche';

  @override
  String accountLockedMessage(int minutes) {
    return 'Ihr Konto wurde aufgrund zu vieler fehlgeschlagener Anmeldeversuche vorübergehend gesperrt. Bitte versuchen Sie es in $minutes Minuten erneut.';
  }

  @override
  String remainingAttempts(int attempts) {
    return '$attempts Anmeldeversuche verbleibend';
  }

  @override
  String get accountUnlocked => 'Konto entsperrt';

  @override
  String get accountUnlockedMessage => 'Ihr Konto wurde entsperrt. Sie können sich jetzt erneut anmelden.';

  @override
  String get adminPasswordRequired => 'Admin-Passwort erforderlich';

  @override
  String get enterYourPassword => 'Geben Sie Ihr Passwort ein';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get deleteUser => 'Benutzer löschen';

  @override
  String get deleteUserConfirmation => 'Sind Sie sicher, dass Sie diesen Benutzer löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get userDeleted => 'Benutzer erfolgreich gelöscht';

  @override
  String get adminPanel => 'Admin-Panel';

  @override
  String get noUsers => 'Keine Benutzer gefunden';

  @override
  String get basicInformation => 'Grundinformationen';

  @override
  String get invalidEmail => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get rolesAndModules => 'Rollen und Module';

  @override
  String get workSettings => 'Arbeitseinstellungen';

  @override
  String get annualLeave => 'Jahresurlaub (Tage)';

  @override
  String get privateAddress => 'Private Adresse';

  @override
  String get workplaceSame => 'Arbeitsplatz gleich wie private Adresse';

  @override
  String get workAddress => 'Arbeitsadresse';

  @override
  String get security => 'Sicherheit';

  @override
  String get updateUser => 'Benutzer aktualisieren';

  @override
  String get area => 'Kanton';

  @override
  String get streetNumber => 'Hausnummer';

  @override
  String get projectsForThisClient => 'Projekte für diesen Kunden';

  @override
  String get noProjectsFoundForThisClient => 'Keine Projekte für diesen Kunden gefunden.';

  @override
  String get clientSummary => 'Kundenübersicht';

  @override
  String get addGroup => 'Gruppe hinzufügen';

  @override
  String get createFirstGroup => 'Erstellen Sie Ihre erste Gruppe, um zu beginnen';

  @override
  String get noGroupsMatchSearch => 'Keine Gruppen entsprechen Ihrer Suche';

  @override
  String get teamLeaderLabel => 'Teamleiter:';

  @override
  String get member => 'Mitglied';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get teamLeaderOptional => 'Teamleiter (Optional)';

  @override
  String get noTeamLeader => 'Kein Teamleiter';

  @override
  String get membersLabel => 'Mitglieder';

  @override
  String get searchMembers => 'Mitglieder suchen...';

  @override
  String get noAvailableMembers => 'Keine verfügbaren Mitglieder';

  @override
  String get noMembersMatchSearch => 'Keine Mitglieder entsprechen Ihrer Suche';

  @override
  String get unknownUser => 'Unbekannter Benutzer';

  @override
  String get unknownGroup => 'Unbekannte Gruppe';

  @override
  String get create => 'Erstellen';

  @override
  String get deleteGroupTitle => 'Gruppe löschen';

  @override
  String get deleteGroupConfirmation => 'Sind Sie sicher, dass Sie löschen möchten';

  @override
  String get deleteGroupCannotBeUndone => 'Diese Aktion kann nicht rückgängig gemacht werden';

  @override
  String get groupDeletedSuccessfully => 'Gruppe erfolgreich gelöscht';

  @override
  String get errorCreatingGroup => 'Fehler beim Erstellen der Gruppe';

  @override
  String get errorUpdatingGroup => 'Fehler beim Aktualisieren der Gruppe';

  @override
  String get errorDeletingGroup => 'Fehler beim Löschen der Gruppe';

  @override
  String errorGroupOperation(String operation, String error) {
    return 'Fehler beim $operation der Gruppe: $error';
  }
}
