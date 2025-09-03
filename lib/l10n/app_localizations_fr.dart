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
  String get appTitle => 'Stark Track';

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

  @override
  String get selectedRange => 'Plage de dates';

  // Reports
  @override
  String get report => 'Rapport';
  @override
  String get reports => 'Rapports';
  @override
  String get createReport => 'Rapport';
  @override
  String get reportName => 'Nom du rapport';
  @override
  String get reportOrientation => 'Orientation du rapport';
  @override
  String get selectFields => 'Sélectionner les champs';
  @override
  String get filters => 'Filtres';

  @override
  String get runReport => 'Exécuter le rapport';
  @override
  String get deleteSuccessful => 'Supprimé avec succès';

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

  // Authentication and User Management
  @override
  String get login => 'Connexion';
  @override
  String get logout => 'Déconnexion';
  @override
  String get password => 'Mot de passe';
  @override
  String get firstName => 'Prénom';
  @override
  String get surname => 'Nom de famille';
  @override
  String get search => 'Rechercher';
  @override
  String get refresh => 'Actualiser';
  @override
  String get filter => 'Filtrer';
  @override
  String get groupBy => 'Grouper par';
  @override
  String get worked => 'Travaillé';
  @override
  String get breaks => 'Pauses';
  @override
  String get approved => 'Approuvé';
  @override
  String get rejected => 'Rejeté';
  @override
  String get pending => 'En attente';
  @override
  String get darkMode => 'Mode sombre';
  @override
  String get language => 'Langue';
  @override
  String get today => 'Aujourd\'hui';
  @override
  String get noLogsForThisDay => 'Aucun enregistrement pour ce jour';
  @override
  String get addNewUser => 'Nouvel utilisateur';
  @override
  String get addNewClient => 'Ajouter un nouveau client';
  @override
  String get addHolidayPolicy => 'Politique de congés';
  @override
  String get addTimeOffPolicy => 'Politique d\'absence';
  @override
  String get searchByName => 'Rechercher par nom';
  @override
  String get searchByEmail => 'Rechercher par e-mail';
  @override
  String get duration => 'Durée';
  @override
  String get worker => 'Travailleur';
  @override
  String get actions => 'Actions';
  @override
  String get overtime => 'Heures extra';

  @override
  String get vacations => 'Vacances';

  @override
  String get type => 'Type';

  @override
  String get bonus => 'Bonus';

  @override
  String get updatedSuccessfully => 'mis à jour avec succès';

  @override
  String get transferred => 'Transféré';

  @override
  String get current => 'Actuel';

  @override
  String get used => 'Utilisé';

  @override
  String get available => 'Disponible';

  @override
  String get calculatingOvertime => 'Calcul des heures supplémentaires...';

  @override
  String get noOvertimeData => 'Aucune donnée d\'heures supplémentaires disponible';

  @override
  String get failedToUpdateBonus => 'Échec de la mise à jour de la valeur du bonus';

  @override
  String get weeklyHours => 'Heures hebdomadaires';

  @override
  String get workingDays => 'Jours de travail par semaine';

  @override
  String get overtimeDays => 'Jours d\'heures supplémentaires';

  // Additional core features
  @override
  String get workload => 'Charge de travail';
  @override
  String get active => 'Actif';
  @override
  String get roles => 'Rôles';
  @override
  String get modules => 'Modules';
  @override
  String get teamLeader => 'Chef d\'équipe';
  @override
  String get passwordManualEntry => 'Mot de passe (saisie manuelle)';
  @override
  String get passwordMinLength => 'Le mot de passe doit contenir au moins 6 caractères.';
  @override
  String get editUser => 'Modifier l\'utilisateur';
  @override
  String get approvalNote => 'Note d\'approbation (optionnel)';
  @override
  String get noClientsFound => 'Aucun client trouvé.';
  @override
  String get noTimeLogsFound => 'Aucun enregistrement de temps trouvé pour ce travailleur.';
  @override
  String get noProjectsFoundInFirestore => 'Aucun projet trouvé dans Firestore.';
  @override
  String get personName => 'Nom de la personne';
  @override
  String get optional => 'optionnel';
  @override
  String get companyAdmin => 'Administrateur de l\'entreprise';
  @override
  String get required => 'requis';
  @override
  String get createHolidayPolicy => 'Créer une politique de congés';
  @override
  String get editHolidayPolicy => 'Modifier la politique de congés';
  @override
  String get policyName => 'Nom de la politique';
  @override
  String get color => 'Couleur';
  @override
  String get customColor => 'Couleur personnalisée';
  @override
  String get date => 'Date';
  @override
  String get selectDate => 'Sélectionner une date';
  @override
  String get assignToEveryone => 'Assigner à tout le monde';
  @override
  String get regionFilter => 'Filtre de région';
  @override
  String get filterByRegion => 'Filtrer par région';

  // Contact and location information
  @override
  String get phone => 'Téléphone';
  @override
  String get city => 'Ville';
  @override
  String get country => 'Pays';

  // Holiday and Time Off Policies
  @override
  String get repeatsAnnually => 'Se répète annuellement';
  @override
  String get national => 'National';
  @override
  String get repeats => 'Se répète';
  @override
  String get assignedTo => 'Assigné à';
  @override
  String get accruing => 'Cumulatif';
  @override
  String get per => 'par';
  @override
  String get timeUnit => 'Unité de temps';
  @override
  String get doesNotCount => 'Ne compte pas';
  @override
  String get holidays => 'Congés';
  @override
  String get timeOffPolicies => 'Politiques d\'absence :';
  @override
  String get includeOvertime => 'Inclure les heures supplémentaires';
  @override
  String get negativeBalance => 'Solde négatif';
  @override
  String get days => 'Jours';
  @override
  String get editTimeOffPolicy => 'Modifier la politique d\'absence';
  @override
  String get createTimeOffPolicy => 'Créer une politique d\'absence';
  @override
  String get paid => 'Payé';
  @override
  String get hours => 'Heures';
  @override
  String get chooseAllThatApply => 'Choisissez tout ce qui s\'applique :';
  @override
  String get allHolidays => 'Tous les congés';
  @override
  String get update => 'Mettre à jour';
  @override
  String get everyone => 'Tout le monde';
  @override
  String get selection => 'Sélection';
  @override
  String get enterPolicyName => 'Entrez le nom de la politique';
  @override
  String get yearly => 'Annuel';
  @override
  String get monthly => 'Mensuel';
  @override
  String get ok => 'OK';
  @override
  String get weeks => 'Semaines';
  @override
  String get weekAbbreviation => 'S';
  @override
  String get months => 'Mois';
  @override
  String get years => 'Années';
  @override
  String get noTimeOffPoliciesFound => 'Aucune politique d\'absence trouvée';
  @override
  String get noHolidayPoliciesFound => 'Aucune politique de congés trouvée';
  @override
  String get pleaseEnterPolicyName => 'Veuillez entrer un nom de politique';
  @override
  String get pleaseSelectDate => 'Veuillez sélectionner une date';

  // User and Group Management
  @override
  String get pickAColor => 'Choisir une couleur';
  @override
  String get region => 'Région';
  @override
  String get assignToUsers => 'Assigner aux utilisateurs/groupes';
  @override
  String get searchUsers => 'Rechercher des utilisateurs...';
  @override
  String get searchGroups => 'Rechercher des groupes...';
  @override
  String get users => 'Utilisateurs';
  @override
  String get groups => 'Groupes';
  @override
  String get noUsersFound => 'Aucun utilisateur trouvé correspondant à votre recherche';
  @override
  String get noGroupsFound => 'Aucun groupe trouvé';
  @override
  String get searchUsersAndGroups => 'Rechercher des utilisateurs et des groupes...';
  @override
  String get noUsersOrGroupsFound => 'Aucun utilisateur ou groupe trouvé';
  @override
  String get user => 'Utilisateur';
  @override
  String get group => 'Groupe';
  @override
  String get holidayPolicies => 'Politiques de congés';
  @override
  String get createNew => 'Créer nouveau';
  @override
  String get deleteHolidayPolicy => 'Supprimer la politique de congés';
  @override
  String get deleteHolidayPolicyConfirm => 'Êtes-vous sûr de vouloir supprimer';
  @override
  String get holidayPolicyDeleted => 'Politique de congés supprimée avec succès';
  @override
  String get includesHistory => 'inclut l\'historique';
  @override
  String get additionalModules => 'Modules supplémentaires';
  @override
  String get showBreaks => 'Afficher les pauses';
  @override
  String get assignToTeamLeader => 'Assigner au chef d\'équipe';
  @override
  String get none => 'Aucun';
  @override
  String get saveChanges => 'Enregistrer les modifications';
  @override
  String get createUser => 'Créer un utilisateur';
  @override
  String get sendPasswordResetEmail => 'Envoyer un e-mail de réinitialisation du mot de passe';
  @override
  String get searchByNameEmailRole => 'Rechercher par nom, e-mail ou rôle';
  @override
  String get confirmDelete => 'Confirmer la suppression';
  @override
  String get confirmDeleteMessage => 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?';

  // Validation and Error Messages
  @override
  String get firstNameSurnameEmailRequired => 'Le prénom, le nom de famille et l\'e-mail sont requis !';
  @override
  String get atLeastOneRoleRequired => 'Au moins un rôle est requis !';
  @override
  String get atLeastOneModuleRequired => 'Au moins un module est requis !';
  @override
  String get passwordMustBeAtLeast6Characters => 'Le mot de passe doit contenir au moins 6 caractères !';
  @override
  String get userWithThisEmailAlreadyExists => 'Un utilisateur avec cet e-mail existe déjà.';
  @override
  String get onlySuperAdminCanEditCompanyAdmin => 'Seul le super administrateur peut modifier l\'administrateur de l\'entreprise.';
  @override
  String get authError => 'Erreur d\'authentification';
  @override
  String get name => 'Nom';
  @override
  String get amount => 'Montant';
  @override
  String get perDiemAmount => '16,00 CHF';
  @override
  String get perDiemAlreadyUsed => 'Indemnité déjà utilisée pour ce jour';
  @override
  String get perDiemAlreadyEntered => 'Indemnité déjà saisie aujourd\'hui';
  @override
  String get endTimeMustBeAfterStartTime => 'L\'heure de fin doit être après l\'heure de début';
  @override
  String get timeOverlap => 'Erreur : Chevauchement de temps';
  @override
  String get noLogsFound => 'Aucun enregistrement trouvé.';
  @override
  String get noEntriesMatchFilters => 'Aucune entrée ne correspond à vos filtres.';
  @override
  String get addNew => 'Ajouter nouveau';
  @override
  String get searchByClientNamePersonEmail => 'Rechercher par nom de client, personne ou e-mail';
  @override
  String get contact => 'Contact';
  @override
  String get searchByNameSurnameEmail => 'Rechercher par nom, prénom ou e-mail';
  @override
  String get role_admin => 'Admin';
  @override
  String get role_team_leader => 'Chef d\'équipe';

  // Roles and Modules
  @override
  String get role_company_admin => 'Administrateur de l\'entreprise';
  @override
  String get superAdmin => 'Super Admin';
  @override
  String get role_user => 'Utilisateur';
  @override
  String get role_worker => 'Travailleur';
  @override
  String get module_admin => 'Administration';
  @override
  String get module_time_tracker => 'Suivi du temps';
  @override
  String get module_team => 'Gestion d\'équipe';
  @override
  String get module_history => 'Historique';

  // Session and Time Management
  @override
  String get sessionDeletedSuccessfully => 'Session supprimée avec succès';
  @override
  String get perDiemAlreadyUsedInAnotherSession => 'Indemnité déjà utilisée dans une autre session aujourd\'hui';

  // Project and Client Management
  @override
  String get projectName => 'Nom du projet';
  @override
  String get street => 'Rue';
  @override
  String get number => 'Numéro';
  @override
  String get postCode => 'Code postal';
  @override
  String get client => 'Client';
  @override
  String get createNewClient => 'Créer un nouveau client';
  @override
  String get clientMustBeSelectedOrCreated => 'Le client doit être sélectionné ou créé';
  @override
  String get editProject => 'Modifier le projet';
  @override
  String get clientDetails => 'Détails du client';

  // Account and Security
  @override
  String get cannotBeEdited => 'ne peut pas être modifié';
  @override
  String get cannotBeDeleted => 'ne peut pas être supprimé';
  @override
  String get deleteEntry => 'Supprimer l\'entrée';
  @override
  String get deleteEntryMessage => 'Êtes-vous sûr de vouloir supprimer cette entrée ? Cette action ne peut pas être annulée.';
  @override
  String get work => 'Travail';
  @override
  String get tapToAddNote => 'Appuyer pour ajouter une note';
  @override
  String get approvedAfterEdit => 'Approuvé après modification';
  @override
  String get noNote => 'Aucune note';
  @override
  String get accountLocked => 'Compte temporairement verrouillé';
  @override
  String get tooManyFailedAttempts => 'Trop de tentatives de connexion échouées';
  @override
  String get accountUnlocked => 'Compte déverrouillé';
  @override
  String get accountUnlockedMessage => 'Votre compte a été déverrouillé. Vous pouvez maintenant essayer de vous reconnecter.';
  @override
  String get adminPasswordRequired => 'Mot de passe administrateur requis';
  @override
  String get confirm => 'Confirmer';
  @override
  String get deleteUser => 'Supprimer l\'utilisateur';
  @override
  String get deleteUserConfirmation => 'Êtes-vous sûr de vouloir supprimer cet utilisateur ? Cette action ne peut pas être annulée.';
  @override
  String get userDeleted => 'Utilisateur supprimé avec succès';
  @override
  String get adminPanel => 'Panneau d\'administration';
  @override
  String get noUsers => 'Aucun utilisateur trouvé';
  @override
  String get basicInformation => 'Informations de base';
  @override
  String get invalidEmail => 'Veuillez entrer une adresse e-mail valide';
  @override
  String get rolesAndModules => 'Rôles et modules';
  @override
  String get workSettings => 'Paramètres de travail';

  // Work and Address Settings
  @override
  String get annualLeave => 'Congés annuels (jours)';
  @override
  String get privateAddress => 'Adresse privée';
  @override
  String get workplaceSame => 'Lieu de travail identique à l\'adresse privée';
  @override
  String get workAddress => 'Adresse de travail';
  @override
  String get security => 'Sécurité';
  @override
  String get updateUser => 'Mettre à jour l\'utilisateur';
  @override
  String get area => 'Zone';
  @override
  String get streetNumber => 'Numéro de rue';

  // Group Management
  @override
  String get addGroup => 'Ajouter un groupe';
  @override
  String get createFirstGroup => 'Créez votre premier groupe pour commencer';
  @override
  String get noGroupsMatchSearch => 'Aucun groupe ne correspond à votre recherche';
  @override
  String get teamLeaderLabel => 'Chef d\'équipe :';
  @override
  String get member => 'membre';
  @override
  String get editGroup => 'Modifier le groupe';
  @override
  String get deleteGroup => 'Supprimer le groupe';
  @override
  String get groupName => 'Nom du groupe';
  @override
  String get teamLeaderOptional => 'Chef d\'équipe (optionnel)';
  @override
  String get noTeamLeader => 'Aucun chef d\'équipe';
  @override
  String get membersLabel => 'Membres';
  @override
  String get searchMembers => 'Rechercher des membres...';
  @override
  String get noAvailableMembers => 'Aucun membre disponible';
  @override
  String get noMembersMatchSearch => 'Aucun membre ne correspond à votre recherche';
  @override
  String get unknownGroup => 'Groupe inconnu';
  @override
  String get create => 'Créer';
  @override
  String get deleteGroupTitle => 'Supprimer le groupe';
  @override
  String get deleteGroupConfirmation => 'Êtes-vous sûr de vouloir supprimer';
  @override
  String get deleteGroupCannotBeUndone => 'Cette action ne peut pas être annulée';
  @override
  String get groupDeletedSuccessfully => 'Groupe supprimé avec succès';
  @override
  String get errorCreatingGroup => 'Erreur lors de la création du groupe';
  @override
  String get errorUpdatingGroup => 'Erreur lors de la mise à jour du groupe';
  @override
  String get errorDeletingGroup => 'Erreur lors de la suppression du groupe';

  // Methods with parameters
  @override
  String perDiemLabel(String amount) {
    return 'Indemnité $amount CHF';
  }

  @override
  String accountLockedMessage(int minutes) {
    return 'Votre compte a été temporairement verrouillé en raison de trop nombreuses tentatives de connexion échouées. Veuillez réessayer dans $minutes minutes.';
  }

  @override
  String remainingAttempts(int attempts) {
    return '$attempts tentatives de connexion restantes';
  }

  @override
  String errorGroupOperation(String operation, String error) {
    return 'Erreur $operation du groupe : $error';
  }

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

  // Missing Report System Translations
  @override
  String get starkTrackDetailedSessionReport => 'Stark Track - Rapport de Session Détaillé';
  
  @override
  String get reportNameLabel => 'Nom du Rapport:';
  
  @override
  String get reportRange => 'Plage du Rapport:';
  
  @override
  String get reportType => 'Type de Rapport:';
  
  @override
  String get generated => 'Généré:';
  
  @override
  String get totalSessions => 'Total des Sessions:';
  
  @override
  String get clientLabel => 'Client:';
  
  @override
  String get userLabel => 'Utilisateur:';
  
  @override
  String get totalProjects => 'Total des Projets:';
  
  @override
  String get overtimeBalance => 'Solde d\'Heures Supplémentaires:';
  
  @override
  String get vacationBalance => 'Solde de Vacances:';
  
  @override
  String get ref => 'Ref:';
  
  @override
  String get totalHours => 'Total des Heures';
  
  @override
  String get totalOvertime => 'Total des Heures Supplémentaires';
  
  @override
  String get pleaseSelectAtLeastOneField => 'Veuillez sélectionner au moins un champ';
  
  @override
  String get excelFileExportedSuccessfully => 'Fichier Excel exporté avec succès!';
  
  @override
  String get excelFileWithMultipleUserSheetsExportedSuccessfully => 'Fichier Excel avec plusieurs feuilles utilisateur exporté avec succès!';
  
  @override
  String get excelFileWithMultipleProjectSheetsExportedSuccessfully => 'Fichier Excel avec plusieurs feuilles projet exporté avec succès!';
  
  @override
  String get excelFileWithMultipleClientSheetsExportedSuccessfully => 'Fichier Excel avec plusieurs feuilles client exporté avec succès!';
  
  @override
  String get exportFailed => 'Échec de l\'export:';
  
  @override
  String get failedToGenerateReport => 'Échec de la génération du rapport:';
  
  // Report Builder Dialog
  @override
  String get dateRange => 'Plage de dates';
  
  @override
  String get workers => 'Travailleurs';
  
  @override
  String get fields => 'Champs';
  
  @override
  String get workerName => 'Nom du travailleur';
  
  // Report Builder Dialog - Missing translations
  @override
  String get selectDateRange => 'Sélectionner la plage de dates';
  
  @override
  String get allWorkers => 'Tous les travailleurs';
  
  @override
  String get allProjects => 'Tous les projets';
  
  @override
  String get allClients => 'Tous les clients';
  
  // Report Cards
  @override
  String get created => 'Créé';
  
  // Report Viewer Dialog
  @override
  String get export => 'Exporter';
  
  @override
  String get exportReport => 'Exporter le rapport';
  
  @override
  String get csv => 'CSV';
  
  @override
  String get excel => 'Excel';
  
  @override
  String get retry => 'Réessayer';
  
  @override
  String get noDataFoundForThisReport => 'Aucune donnée trouvée pour ce rapport';
  
  @override
  String get detailedSessionReport => 'Rapport de session détaillé';
  
  @override
  String get detailedReport => 'Rapport détaillé';
  
  @override
  String get unnamedReport => 'Rapport sans nom';
  
  @override
  String get unnamedProject => 'Projet sans nom';
  
  @override
  String get unnamedClient => 'Client sans nom';
  
  @override
  String get startTime => 'Heure de début';
  
  @override
  String get endTime => 'Heure de fin';
  
  @override
  String get notes => 'Notes';
  
  @override
  String get usersInvolved => 'Utilisateurs impliqués';
  
  @override
  String get projectsWorked => 'Projets travaillés';
  
  @override
  String get status => 'Statut';
  
  @override
  String get overtimeHours => 'Heures supplémentaires';
  
  @override
  String get vacationDays => 'Jours de vacances';
  
  @override
  String get efficiencyRating => 'Évaluation de l\'efficacité';
  
  @override
  String get expenseType => 'Type de dépense';
  
  @override
  String get description => 'Description';
  
  @override
  String get noActivity => 'Aucune activité';
  
  @override
  String get inactive => 'Inactif';
  
  @override
  String get mixed => 'Mixte';
  
  @override
  String get noData => 'Aucune donnée';
  
  @override
  String get notSpecified => 'Non spécifié';
  
  @override
  String get summary => 'Résumé';
  
  @override
  String get noSessionsFoundForThisUserInTheSelectedPeriod => 'Aucune session trouvée pour cet utilisateur dans la période sélectionnée';
  
  @override
  String get noSessionsFoundForThisProjectInTheSelectedPeriod => 'Aucune session trouvée pour ce projet dans la période sélectionnée';
  
  @override
  String get noProjectsFoundForThisClientInTheSelectedPeriod => 'Aucun projet trouvé pour ce client dans la période sélectionnée';
  
  @override
  String get noDataAvailableForThisReport => 'Aucune donnée disponible pour ce rapport';
  
  @override
  String get reference => 'Référence';
  
  @override
  String get startEnd => 'Début - Fin';
  
  @override
  String get chooseExportFormat => 'Choisir le format d\'exportation:';
  
  @override
  String get csvExportedSuccessfully => 'CSV exporté avec succès!';
  
  @override
  String get avgHoursPerDay => 'Heures moy./Jour';
  
  @override
  String get sessions => 'Sessions';
  
  @override
  String get sessionCount => 'Nombre de sessions';
  
  @override
  String get exportExcel => 'Exporter Excel';
  
  @override
  String get reportRangeLabel => 'Plage de rapport:';
  
  @override
  String get overtimeLabel => 'Heures supplémentaires:';
  
  @override
  String get weekPrefix => 'S';
  
  @override
  String get clientReport => 'client';
  
  @override
  String get multiProjectReport => 'projet';
  
  @override
  String get multiUserReport => 'travailleur';
}
