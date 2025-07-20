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
  String get perDiem => 'Tagesgeld';

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
  String get darkMode => 'Dunkler Modus';

  @override
  String get language => 'Sprache';

  @override
  String get today => 'Heute';

  @override
  String get noLogsForThisDay => 'Keine Einträge für diesen Tag';

  @override
  String get addNewUser => 'Neuen Benutzer hinzufügen';

  @override
  String get addNewClient => 'Neuen Kunden hinzufügen';

  @override
  String get addNewProject => 'Neues Projekt hinzufügen';

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
  String get addNewSession => 'Neue Sitzung hinzufügen';

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
}
