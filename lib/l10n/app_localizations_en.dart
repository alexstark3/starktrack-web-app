// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stark Track';

  @override
  String get timeTracker => 'Time Tracker';

  @override
  String get history => 'History';

  @override
  String get team => 'Team';

  @override
  String get members => 'Members';

  @override
  String get projects => 'Projects';

  @override
  String get clients => 'Clients';

  @override
  String get admin => 'Admin';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Log out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get firstName => 'First Name';

  @override
  String get surname => 'Surname';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get search => 'Search';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get project => 'Project';

  @override
  String get note => 'Note';

  @override
  String get expenses => 'Expenses';

  @override
  String get perDiem => 'Per Diem';

  @override
  String get worked => 'Worked';

  @override
  String get breaks => 'Breaks';

  @override
  String get total => 'Total';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get pending => 'Pending';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get today => 'Today';

  @override
  String get noLogsForThisDay => 'No logs for this day';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get addNewClient => 'Add New Client';

  @override
  String get addNewProject => 'Add New Project';

  @override
  String get searchByName => 'Search by name';

  @override
  String get searchByEmail => 'Search by email';

  @override
  String get searchByProject => 'Search by project';

  @override
  String get searchByClient => 'Search by client';

  @override
  String get contactPerson => 'Contact Person';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get duration => 'Duration';

  @override
  String get worker => 'Worker';

  @override
  String get actions => 'Actions';

  @override
  String get view => 'View';

  @override
  String get refresh => 'Refresh';

  @override
  String get filter => 'Filter';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get groupBy => 'Group by';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get overtime => 'Overtime';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get totalTime => 'Total Time';

  @override
  String get weeklyHours => 'Weekly Hours';

  @override
  String get workload => 'Workload';

  @override
  String get active => 'Active';

  @override
  String get roles => 'Roles';

  @override
  String get modules => 'Modules';

  @override
  String get teamLeader => 'Team Leader';

  @override
  String get passwordManualEntry => 'Password (manual entry)';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters.';

  @override
  String get editUser => 'Edit User';

  @override
  String get addNewSession => 'Add New Session';

  @override
  String get approvalNote => 'Approval Note (optional)';

  @override
  String get noMembersFound => 'No members found.';

  @override
  String get noProjectsFound => 'No projects found.';

  @override
  String get noClientsFound => 'No clients found.';

  @override
  String get noTimeLogsFound => 'No time logs found for this worker.';

  @override
  String errorLoadingProjects(String error) {
    return 'Error loading projects: $error';
  }

  @override
  String get noProjectsFoundInFirestore => 'No projects found in Firestore.';

  @override
  String get projectId => 'Project ID';

  @override
  String get clientName => 'Client Name';

  @override
  String get personName => 'Person Name';

  @override
  String get optional => 'optional';

  @override
  String get companyAdmin => 'Company Admin';

  @override
  String get required => 'required';

  @override
  String get includesHistory => 'includes History';

  @override
  String get additionalModules => 'Additional Modules';

  @override
  String get showBreaks => 'Show Breaks';

  @override
  String get assignToTeamLeader => 'Assign to Team Leader';

  @override
  String get none => 'None';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createUser => 'Create User';

  @override
  String get sendPasswordResetEmail => 'Send password reset email';

  @override
  String passwordResetEmailSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String failedToSendResetEmail(String error) {
    return 'Failed to send reset email: $error';
  }

  @override
  String get searchByNameEmailRole => 'Search by name, email, or role';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteMessage => 'Are you sure you want to delete this user?';

  @override
  String get firstNameSurnameEmailRequired => 'First Name, Surname, and Email are required!';

  @override
  String get atLeastOneRoleRequired => 'At least one role is required!';

  @override
  String get atLeastOneModuleRequired => 'At least one module is required!';

  @override
  String get passwordMustBeAtLeast6Characters => 'Password must be at least 6 characters!';

  @override
  String get userWithThisEmailAlreadyExists => 'A user with this email already exists.';

  @override
  String get onlySuperAdminCanEditCompanyAdmin => 'Only super admin can edit the company admin.';

  @override
  String get authError => 'Auth error';

  @override
  String permissionDenied(String error) {
    return 'Permission denied: $error';
  }

  @override
  String unknownError(String error) {
    return 'Unknown error: $error';
  }
}
