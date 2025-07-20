import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stark Track'**
  String get appTitle;

  /// No description provided for @timeTracker.
  ///
  /// In en, this message translates to:
  /// **'Time Tracker'**
  String get timeTracker;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @perDiem.
  ///
  /// In en, this message translates to:
  /// **'Per diem'**
  String get perDiem;

  /// No description provided for @worked.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get worked;

  /// No description provided for @breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get breaks;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noLogsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No logs for this day'**
  String get noLogsForThisDay;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @addNewClient.
  ///
  /// In en, this message translates to:
  /// **'Add New Client'**
  String get addNewClient;

  /// No description provided for @addNewProject.
  ///
  /// In en, this message translates to:
  /// **'Add New Project'**
  String get addNewProject;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @searchByEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by email'**
  String get searchByEmail;

  /// No description provided for @searchByProject.
  ///
  /// In en, this message translates to:
  /// **'Search by project'**
  String get searchByProject;

  /// No description provided for @searchByClient.
  ///
  /// In en, this message translates to:
  /// **'Search by client'**
  String get searchByClient;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupBy;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @weeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly Hours'**
  String get weeklyHours;

  /// No description provided for @workload.
  ///
  /// In en, this message translates to:
  /// **'Workload'**
  String get workload;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @teamLeader.
  ///
  /// In en, this message translates to:
  /// **'Team Leader'**
  String get teamLeader;

  /// No description provided for @passwordManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Password (manual entry)'**
  String get passwordManualEntry;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinLength;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @addNewSession.
  ///
  /// In en, this message translates to:
  /// **'Add New Session'**
  String get addNewSession;

  /// No description provided for @approvalNote.
  ///
  /// In en, this message translates to:
  /// **'Approval Note (optional)'**
  String get approvalNote;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found.'**
  String get noMembersFound;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found.'**
  String get noProjectsFound;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get noClientsFound;

  /// No description provided for @noTimeLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No time logs found for this worker.'**
  String get noTimeLogsFound;

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects: {error}'**
  String errorLoadingProjects(String error);

  /// No description provided for @noProjectsFoundInFirestore.
  ///
  /// In en, this message translates to:
  /// **'No projects found in Firestore.'**
  String get noProjectsFoundInFirestore;

  /// No description provided for @projectId.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get projectId;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Person Name'**
  String get personName;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @companyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Company Admin'**
  String get companyAdmin;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get required;

  /// No description provided for @includesHistory.
  ///
  /// In en, this message translates to:
  /// **'includes History'**
  String get includesHistory;

  /// No description provided for @additionalModules.
  ///
  /// In en, this message translates to:
  /// **'Additional Modules'**
  String get additionalModules;

  /// No description provided for @showBreaks.
  ///
  /// In en, this message translates to:
  /// **'Show Breaks'**
  String get showBreaks;

  /// No description provided for @assignToTeamLeader.
  ///
  /// In en, this message translates to:
  /// **'Assign to Team Leader'**
  String get assignToTeamLeader;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @sendPasswordResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send password reset email'**
  String get sendPasswordResetEmail;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String passwordResetEmailSent(String email);

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email: {error}'**
  String failedToSendResetEmail(String error);

  /// No description provided for @searchByNameEmailRole.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or role'**
  String get searchByNameEmailRole;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get confirmDeleteMessage;

  /// No description provided for @firstNameSurnameEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'First Name, Surname, and Email are required!'**
  String get firstNameSurnameEmailRequired;

  /// No description provided for @atLeastOneRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one role is required!'**
  String get atLeastOneRoleRequired;

  /// No description provided for @atLeastOneModuleRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one module is required!'**
  String get atLeastOneModuleRequired;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters!'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @userWithThisEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A user with this email already exists.'**
  String get userWithThisEmailAlreadyExists;

  /// No description provided for @onlySuperAdminCanEditCompanyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only super admin can edit the company admin.'**
  String get onlySuperAdminCanEditCompanyAdmin;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth error'**
  String get authError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied: {error}'**
  String permissionDenied(String error);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error: {error}'**
  String unknownError(String error);

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select Project'**
  String get selectProject;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @perDiemAmount.
  ///
  /// In en, this message translates to:
  /// **'16.00 CHF'**
  String get perDiemAmount;

  /// No description provided for @perDiemAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Per Diem already used for this day'**
  String get perDiemAlreadyUsed;

  /// No description provided for @perDiemAlreadyEntered.
  ///
  /// In en, this message translates to:
  /// **'Per Diem already entered today'**
  String get perDiemAlreadyEntered;

  /// No description provided for @startAndEndTimesCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start and End times cannot be empty'**
  String get startAndEndTimesCannotBeEmpty;

  /// No description provided for @endTimeMustBeAfterStartTime.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeMustBeAfterStartTime;

  /// No description provided for @timeOverlap.
  ///
  /// In en, this message translates to:
  /// **'Error: Time overlap'**
  String get timeOverlap;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @noLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No logs found.'**
  String get noLogsFound;

  /// No description provided for @noEntriesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No entries match your filters.'**
  String get noEntriesMatchFilters;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @searchByClientNamePersonEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by client name, person, or email'**
  String get searchByClientNamePersonEmail;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @searchByNameSurnameEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name, surname or email'**
  String get searchByNameSurnameEmail;

  /// No description provided for @role_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get role_admin;

  /// No description provided for @role_team_leader.
  ///
  /// In en, this message translates to:
  /// **'Team Leader'**
  String get role_team_leader;

  /// No description provided for @role_company_admin.
  ///
  /// In en, this message translates to:
  /// **'Company Admin'**
  String get role_company_admin;

  /// No description provided for @role_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get role_user;

  /// No description provided for @role_worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get role_worker;

  /// No description provided for @module_admin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get module_admin;

  /// No description provided for @module_time_tracker.
  ///
  /// In en, this message translates to:
  /// **'Time Tracker'**
  String get module_time_tracker;

  /// No description provided for @module_team.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get module_team;

  /// No description provided for @module_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get module_history;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSession;

  /// No description provided for @sessionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Session deleted successfully'**
  String get sessionDeletedSuccessfully;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @editTimeLog.
  ///
  /// In en, this message translates to:
  /// **'Edit Time Log'**
  String get editTimeLog;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @perDiemAlreadyUsedInAnotherSession.
  ///
  /// In en, this message translates to:
  /// **'Per diem already used in another session today'**
  String get perDiemAlreadyUsedInAnotherSession;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @postCode.
  ///
  /// In en, this message translates to:
  /// **'Post Code'**
  String get postCode;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @createNewClient.
  ///
  /// In en, this message translates to:
  /// **'Create new client'**
  String get createNewClient;

  /// No description provided for @clientMustBeSelectedOrCreated.
  ///
  /// In en, this message translates to:
  /// **'Client must be selected or created'**
  String get clientMustBeSelectedOrCreated;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @projectRef.
  ///
  /// In en, this message translates to:
  /// **'Project Ref'**
  String get projectRef;

  /// No description provided for @clientDetails.
  ///
  /// In en, this message translates to:
  /// **'Client Details'**
  String get clientDetails;

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @perDiemLabel.
  ///
  /// In en, this message translates to:
  /// **'Per diem {amount} CHF'**
  String perDiemLabel(String amount);

  /// No description provided for @endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End before start'**
  String get endBeforeStart;

  /// No description provided for @sessionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sessionDate;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @cannotBeEdited.
  ///
  /// In en, this message translates to:
  /// **'cannot be edited'**
  String get cannotBeEdited;

  /// No description provided for @cannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'cannot be deleted'**
  String get cannotBeDeleted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
