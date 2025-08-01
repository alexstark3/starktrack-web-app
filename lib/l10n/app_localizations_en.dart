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
  String get members => 'members';

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
  String get perDiem => 'Per diem';

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
  String get addNewUser => 'New User';

  @override
  String get addNewClient => 'Add New Client';

  @override
  String get addNewProject => 'Add New Project';

  @override
  String get addHolidayPolicy => 'Holiday Policy';

  @override
  String get addTimeOffPolicy => 'Time Off Policy';

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
  String get createHolidayPolicy => 'Create Holiday Policy';

  @override
  String get editHolidayPolicy => 'Edit Holiday Policy';

  @override
  String get policyName => 'Policy Name';

  @override
  String get color => 'Color';

  @override
  String get customColor => 'Custom Color';

  @override
  String get date => 'Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get assignToEveryone => 'Assign to everyone';

  @override
  String get regionFilter => 'Region Filter';

  @override
  String get filterByRegion => 'Filter by Region';

  @override
  String get repeatsAnnually => 'Repeats annually';

  @override
  String get national => 'National';

  @override
  String get repeats => 'Repeats';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get accruing => 'Accruing';

  @override
  String get per => 'per';

  @override
  String get timeUnit => 'Time Unit';

  @override
  String get doesNotCount => 'Does not count';

  @override
  String get holidays => 'Holidays';

  @override
  String get timeOffPolicies => 'Time Off Policies:';

  @override
  String get includeOvertime => 'Include Overtime';

  @override
  String get negativeBalance => 'Negative Balance';

  @override
  String get days => 'Days';

  @override
  String get editTimeOffPolicy => 'Edit Time Off Policy';

  @override
  String get createTimeOffPolicy => 'Create Time Off Policy';

  @override
  String get paid => 'Paid';

  @override
  String get hours => 'Hours';

  @override
  String get chooseAllThatApply => 'Choose all that apply:';

  @override
  String get allHolidays => 'All Holidays';

  @override
  String get update => 'Update';

  @override
  String get error => 'Error';

  @override
  String get everyone => 'Everyone';

  @override
  String get selection => 'Selection';

  @override
  String get enterPolicyName => 'Enter policy name';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get ok => 'OK';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get years => 'Years';

  @override
  String get noTimeOffPoliciesFound => 'No time off policies found';

  @override
  String get noHolidayPoliciesFound => 'No holiday policies found';

  @override
  String get pleaseEnterPolicyName => 'Please enter a policy name';

  @override
  String get pleaseSelectDate => 'Please select a date';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get region => 'Region';

  @override
  String get assignToUsers => 'Assign to Users/Groups';

  @override
  String get searchUsers => 'Search users...';

  @override
  String get searchGroups => 'Search groups...';

  @override
  String get users => 'Users';

  @override
  String get groups => 'Groups';

  @override
  String get noUsersFound => 'No users found matching your search';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get searchUsersAndGroups => 'Search users and groups...';

  @override
  String get noUsersOrGroupsFound => 'No users or groups found';

  @override
  String get user => 'User';

  @override
  String get group => 'Group';

  @override
  String get holidayPolicies => 'Holiday Policies';

  @override
  String get createNew => 'Create New';

  @override
  String get deleteHolidayPolicy => 'Delete Holiday Policy';

  @override
  String get deleteHolidayPolicyConfirm => 'Are you sure you want to delete';

  @override
  String get holidayPolicyDeleted => 'Holiday policy deleted successfully';

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

  @override
  String get selectProject => 'Select Project';

  @override
  String get name => 'Name';

  @override
  String get amount => 'Amount';

  @override
  String get perDiemAmount => '16.00 CHF';

  @override
  String get perDiemAlreadyUsed => 'Per Diem already used for this day';

  @override
  String get perDiemAlreadyEntered => 'Per Diem already entered today';

  @override
  String get startAndEndTimesCannotBeEmpty => 'Start and End times cannot be empty';

  @override
  String get endTimeMustBeAfterStartTime => 'End time must be after start time';

  @override
  String get timeOverlap => 'Error: Time overlap';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noLogsFound => 'No logs found.';

  @override
  String get noEntriesMatchFilters => 'No entries match your filters.';

  @override
  String get unknown => 'Unknown';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get addNew => 'Add New';

  @override
  String get searchByClientNamePersonEmail => 'Search by client name, person, or email';

  @override
  String get contact => 'Contact';

  @override
  String get searchByNameSurnameEmail => 'Search by name, surname or email';

  @override
  String get role_admin => 'Admin';

  @override
  String get role_team_leader => 'Team Leader';

  @override
  String get role_company_admin => 'Company Admin';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get role_user => 'User';

  @override
  String get role_worker => 'Worker';

  @override
  String get module_admin => 'Administration';

  @override
  String get module_time_tracker => 'Time Tracker';

  @override
  String get module_team => 'Team Management';

  @override
  String get module_history => 'History';

  @override
  String get deleteSession => 'Delete Session';

  @override
  String get sessionDeletedSuccessfully => 'Session deleted successfully';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get editTimeLog => 'Edit Time Log';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get perDiemAlreadyUsedInAnotherSession => 'Per diem already used in another session today';

  @override
  String get projectName => 'Project Name';

  @override
  String get street => 'Street';

  @override
  String get number => 'Number';

  @override
  String get postCode => 'Post Code';

  @override
  String get client => 'Client';

  @override
  String get createNewClient => 'Create new client';

  @override
  String get clientMustBeSelectedOrCreated => 'Client must be selected or created';

  @override
  String get editProject => 'Edit Project';

  @override
  String get projectRef => 'Project Ref';

  @override
  String get clientDetails => 'Client Details';

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get nameLabel => 'Name';

  @override
  String get amountLabel => 'Amount';

  @override
  String get addLabel => 'Add';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveLabel => 'Save';

  @override
  String get projectLabel => 'Project';

  @override
  String get noteLabel => 'Note';

  @override
  String perDiemLabel(String amount) {
    return 'Per diem $amount CHF';
  }

  @override
  String get endBeforeStart => 'End before start';

  @override
  String get sessionDate => 'Date';

  @override
  String get time => 'Time';

  @override
  String get cannotBeEdited => 'cannot be edited';

  @override
  String get cannotBeDeleted => 'cannot be deleted';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteEntryMessage => 'Are you sure you want to delete this entry? This cannot be undone.';

  @override
  String get work => 'Work';

  @override
  String get tapToAddNote => 'Tap to add note';

  @override
  String get approvedAfterEdit => 'Approved After Edit';

  @override
  String get noNote => 'No note';

  @override
  String get accountLocked => 'Account temporarily locked';

  @override
  String get tooManyFailedAttempts => 'Too many failed login attempts';

  @override
  String accountLockedMessage(int minutes) {
    return 'Your account has been temporarily locked due to too many failed login attempts. Please try again in $minutes minutes.';
  }

  @override
  String remainingAttempts(int attempts) {
    return '$attempts login attempts remaining';
  }

  @override
  String get accountUnlocked => 'Account unlocked';

  @override
  String get accountUnlockedMessage => 'Your account has been unlocked. You can now try logging in again.';

  @override
  String get adminPasswordRequired => 'Admin password required';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get deleteUserConfirmation => 'Are you sure you want to delete this user? This action cannot be undone.';

  @override
  String get userDeleted => 'User deleted successfully';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get noUsers => 'No users found';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get rolesAndModules => 'Roles and Modules';

  @override
  String get workSettings => 'Work Settings';

  @override
  String get annualLeave => 'Annual Leave (days)';

  @override
  String get privateAddress => 'Private Address';

  @override
  String get workplaceSame => 'Workplace same as private address';

  @override
  String get workAddress => 'Work Address';

  @override
  String get security => 'Security';

  @override
  String get updateUser => 'Update User';

  @override
  String get area => 'Area';

  @override
  String get streetNumber => 'Street Number';

  @override
  String get projectsForThisClient => 'Projects for this client';

  @override
  String get noProjectsFoundForThisClient => 'No projects found for this client.';

  @override
  String get clientSummary => 'Client Summary';

  @override
  String get addGroup => 'Add Group';

  @override
  String get createFirstGroup => 'Create your first group to get started';

  @override
  String get noGroupsMatchSearch => 'No groups match your search';

  @override
  String get teamLeaderLabel => 'Team Leader:';

  @override
  String get member => 'member';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get teamLeaderOptional => 'Team Leader (Optional)';

  @override
  String get noTeamLeader => 'No Team Leader';

  @override
  String get membersLabel => 'Members';

  @override
  String get searchMembers => 'Search members...';

  @override
  String get noAvailableMembers => 'No available members';

  @override
  String get noMembersMatchSearch => 'No members match your search';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get unknownGroup => 'Unknown Group';

  @override
  String get create => 'Create';

  @override
  String get deleteGroupTitle => 'Delete Group';

  @override
  String get deleteGroupConfirmation => 'Are you sure you want to delete';

  @override
  String get deleteGroupCannotBeUndone => 'This action cannot be undone';

  @override
  String get groupDeletedSuccessfully => 'Group deleted successfully';

  @override
  String get errorCreatingGroup => 'Error creating group';

  @override
  String get errorUpdatingGroup => 'Error updating group';

  @override
  String get errorDeletingGroup => 'Error deleting group';

  @override
  String errorGroupOperation(String operation, String error) {
    return 'Error $operation group: $error';
  }
}
