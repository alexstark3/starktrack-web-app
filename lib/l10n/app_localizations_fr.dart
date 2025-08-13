// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
///
/// NOTE: This class extends English and overrides only keys we translated now.
/// Missing keys will gracefully fall back to English.
class AppLocalizationsFr extends AppLocalizationsEn {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get timeTracker => 'Suivi du temps';

  @override
  String get history => 'Historique';

  @override
  String get team => 'Équipe';

  @override
  String get timeOff => 'Congés';

  @override
  String get members => 'Membres';

  @override
  String get projects => 'Projets';

  @override
  String get clients => 'Clients';

  @override
  String get admin => 'Admin';

  @override
  String get settings => 'Paramètres';

  @override
  String get calendar => 'Calendrier';

  @override
  String get balance => 'Solde';

  @override
  String get requests => 'Demandes';

  // Time Off - Requests
  @override
  String get searchRequests => 'Rechercher des demandes';

  @override
  String get requestButton => 'Demande';

  @override
  String get failedToLoadRequests => 'Échec du chargement des demandes';

  @override
  String get noRequests => 'Aucune demande';

  @override
  String get unknownPolicy => 'Règle inconnue';

  @override
  String get newTimeOffRequest => 'Nouvelle demande d\'absence';

  @override
  String get policy => 'Règle';

  @override
  String get descriptionOptional => 'Description (optionnel)';

  @override
  String get submitRequest => 'Envoyer la demande';

  @override
  String get pickDates => 'Choisir des dates';

  // Timeline labels
  @override
  String get teamMember => 'Membre de l\'équipe';

  @override
  String get resetToThisWeek => 'Réinitialiser à cette semaine';

  @override
  String get personal => 'Personnel';

  @override
  String get error => 'Erreur';

  @override
  String get noMembersFound => 'Aucun membre trouvé';

  @override
  String get unknownUser => 'Utilisateur inconnu';

  // App shell/system
  @override
  String get systemMaintenance =>
      'Le système est en maintenance. Veuillez réessayer plus tard.';
  @override
  String get userNotFoundInCompany =>
      'Utilisateur introuvable dans l\'entreprise.';
  @override
  String get noCompaniesFound => 'Aucune entreprise trouvée.';
  @override
  String get userNotAssigned => 'Utilisateur non assigné à une entreprise.';

  // Calendar widget strings
  @override
  String get startingDayOfWeek => 'Premier jour de la semaine';
  @override
  String get monday => 'Lundi';
  @override
  String get tuesday => 'Mardi';
  @override
  String get wednesday => 'Mercredi';
  @override
  String get thursday => 'Jeudi';
  @override
  String get friday => 'Vendredi';
  @override
  String get saturday => 'Samedi';
  @override
  String get sunday => 'Dimanche';
  @override
  String get calendarSettings => 'Paramètres du calendrier';
  @override
  String get clear => 'Effacer';
  @override
  String get showWeekNumbers => 'Afficher les numéros de semaine';
  @override
  String get manager => 'Manager';
  @override
  String get changesSaved => 'Modifications enregistrées avec succès !';

  // Common UI
  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get view => 'Voir';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get day => 'Jour';

  @override
  String get week => 'Semaine';

  @override
  String get month => 'Mois';

  @override
  String get year => 'Année';

  @override
  String get project => 'Projet';

  @override
  String get note => 'Note';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get deleteSession => 'Supprimer la session';

  @override
  String get sessionDate => 'Date';

  @override
  String get time => 'Heure';

  @override
  String get approve => 'Approuver';

  @override
  String get reject => 'Rejeter';

  @override
  String get totalTime => 'Temps total';

  @override
  String get totalExpenses => 'Dépenses totales';

  @override
  String get expensesTitle => 'Dépenses';

  @override
  String get nameLabel => 'Nom';

  @override
  String get amountLabel => 'Montant';

  @override
  String get addLabel => 'Ajouter';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get editTimeLog => 'Modifier le pointage';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get projectLabel => 'Projet';

  @override
  String get selectProject => 'Sélectionner un projet';

  @override
  String get noteLabel => 'Note';

  @override
  String get expenses => 'Dépenses';

  @override
  String get tapToAdd => 'Appuyer pour ajouter';

  @override
  String get endBeforeStart => 'Fin avant début';

  @override
  String get addNewSession => 'Ajouter une nouvelle session';

  @override
  String get startAndEndTimesCannotBeEmpty =>
      'Les heures de début et de fin ne peuvent pas être vides';

  // Projects/Clients
  @override
  String get searchByProject => 'Rechercher par projet';

  @override
  String get searchByClient => 'Rechercher par client';

  @override
  String get addNewProject => 'Ajouter un nouveau projet';

  @override
  String get noProjectsFound => 'Aucun projet trouvé.';

  @override
  String get projectsForThisClient => 'Projets pour ce client';

  @override
  String get clientSummary => 'Résumé du client';

  @override
  String get total => 'Total';

  @override
  String get projectId => 'ID du projet';

  @override
  String get projectRef => 'Réf. projet';

  @override
  String get clientName => 'Nom du client';

  @override
  String get contactPerson => 'Personne de contact';

  @override
  String get address => 'Adresse';

  @override
  String get email => 'E-mail';
  @override
  String get enterYourEmail => 'Entrez votre adresse e-mail';
  @override
  String get enterYourPassword => 'Entrez votre mot de passe';

  @override
  String get phone => 'Téléphone';

  @override
  String get city => 'Ville';

  @override
  String get country => 'Pays';

  @override
  String get noTimeLogsFound =>
      'Aucun enregistrement de temps pour cet employé.';

  @override
  String get unknown => 'Inconnu';

  @override
  String get perDiem => 'Indemnité';

  @override
  String get all => 'Tous';

  @override
  String get denyRequest => 'Refuser la demande';

  @override
  String get deny => 'Refuser';
}
