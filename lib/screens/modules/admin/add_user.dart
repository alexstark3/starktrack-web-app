import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../super_admin/services/company_module_service.dart';
import '../../../../widgets/calendar.dart';
import 'user_address.dart';
import '../../../../utils/app_logger.dart';

class AddUserDialog extends StatefulWidget {
  final String companyId;
  final List<Map<String, dynamic>> teamLeaders;
  final DocumentSnapshot? editUser;
  final Function() onUserAdded;
  final List<String> currentUserRoles;
  final List<String>? preSelectedRoles;

  const AddUserDialog({
    super.key,
    required this.companyId,
    required this.teamLeaders,
    this.editUser,
    required this.onUserAdded,
    required this.currentUserRoles,
    this.preSelectedRoles,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();

  // User data
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _privateAddress = {};
  Map<String, dynamic> _workAddress = {};

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _workloadController;
  late TextEditingController _weeklyHoursController;
  late TextEditingController _annualLeaveController;
  late TextEditingController _passwordController;
  late TextEditingController _startDateController;

  // Form state
  List<String> _selectedRoles = [];
  List<String> _selectedModules = ['time_tracker'];
  String _selectedTeamLeaderId = '';
  bool _isActive = true;
  bool _showBreaks = true;
  bool _workplaceSame = true;
  bool _isSubmitting = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
  }

  void _initializeData() {
    final isEdit = widget.editUser != null;

    if (isEdit) {
      final editData = widget.editUser!.data() as Map<String, dynamic>;
      _userData = Map<String, dynamic>.from(editData);

      // Initialize addresses
      _privateAddress =
          Map<String, dynamic>.from(_userData['privateAdress'] ?? {});
      _workAddress = Map<String, dynamic>.from(_userData['workAddress'] ?? {});

      // Initialize form values
      _selectedRoles = List<String>.from(_userData['roles'] ?? []);
      _selectedModules =
          List<String>.from(_userData['modules'] ?? ['time_tracker']);
      _selectedTeamLeaderId = _userData['teamLeaderId'] ?? '';
      _isActive = _userData['active'] ?? true;
      _showBreaks = _userData['showBreaks'] ?? true;
      _workplaceSame = _userData['workplaceSame'] ?? true;
    } else {
      // Default values for new user
      _userData = {
        'firstName': '',
        'surname': '',
        'email': '',
        'phone': '',
        'roles': [],
        'modules': ['time_tracker'],
        'active': true,
        'workPercent': 100,
        'weeklyHours': 40,
        'annualLeaveDays': 25,
        'overtime': {
          'transferred': 0,
          'current': 0,
          'bonus': 0,
          'used': 0,
        },
        'teamLeaderId': '',
        'showBreaks': true,
        'workplaceSame': true,
        'privateAdress': {},
        'workAddress': {},
      };

      _privateAddress = {};
      _workAddress = {};

      // Use pre-selected roles if provided
      if (widget.preSelectedRoles != null) {
        _selectedRoles = List<String>.from(widget.preSelectedRoles!);
      }
    }
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: _userData['firstName'] ?? '');
    _surnameController =
        TextEditingController(text: _userData['surname'] ?? '');
    _emailController = TextEditingController(text: _userData['email'] ?? '');
    _phoneController = TextEditingController(text: _userData['phone'] ?? '');
    _workloadController =
        TextEditingController(text: '${_userData['workPercent'] ?? 100}');
    _weeklyHoursController =
        TextEditingController(text: '${_userData['weeklyHours'] ?? 40}');
    // Handle both old (integer) and new (map) annualLeaveDays structure
    final annualLeaveDays = _userData['annualLeaveDays'];
    String annualLeaveText = '25.0';
    if (annualLeaveDays is Map<String, dynamic>) {
      final currentValue = annualLeaveDays['current'] ?? 25;
      if (currentValue is double) {
        annualLeaveText = currentValue.toStringAsFixed(1);
      } else {
        annualLeaveText = '${currentValue.toDouble()}';
      }
    } else if (annualLeaveDays is int) {
      annualLeaveText = '${annualLeaveDays.toDouble()}';
    }
    _annualLeaveController = TextEditingController(text: annualLeaveText);
    _passwordController = TextEditingController();

    // Initialize start date controller
    final startDate = _userData['startDate'] ?? '';
    _startDateController = TextEditingController(text: startDate);
  }

  Map<String, dynamic> _buildAnnualLeaveDays() {
    final isEdit = widget.editUser != null;
    final currentValue = double.tryParse(_annualLeaveController.text) ?? 25.0;

    if (isEdit) {
      // Preserve existing transferred, bonus, and used values when editing
      final existingAnnualLeaveDays = _userData['annualLeaveDays'];
      if (existingAnnualLeaveDays is Map<String, dynamic>) {
        return {
          'transferred':
              _convertToDouble(existingAnnualLeaveDays['transferred'] ?? 0),
          'current': currentValue,
          'bonus': _convertToDouble(existingAnnualLeaveDays['bonus'] ?? 0),
          'used': _convertToDouble(existingAnnualLeaveDays['used'] ?? 0),
        };
      } else if (existingAnnualLeaveDays is int) {
        // Convert old integer format to new map format
        return {
          'transferred': 0.0,
          'current': currentValue,
          'bonus': 0.0,
          'used': 0.0,
        };
      }
    }

    // For new users, start with default values
    return {
      'transferred': 0.0,
      'current': currentValue,
      'bonus': 0.0,
      'used': 0.0,
    };
  }

  double _convertToDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Start Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).extension<AppColors>()!.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: CustomCalendar(
                  initialDateRange: _startDateController.text.isNotEmpty
                      ? DateRange(
                          startDate: DateTime.parse(_startDateController.text))
                      : null,
                  onDateRangeChanged: (dateRange) {
                    if (dateRange.startDate != null) {
                      setState(() {
                        // Store as ISO for backend consistency, display as EU format in UI
                        _startDateController.text = DateFormat('yyyy-MM-dd')
                            .format(dateRange.startDate!);
                      });
                      Navigator.of(context)
                          .pop(); // Close dialog after selection
                    }
                  },
                  maxDate: DateTime.now(), // Can't select future dates
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildOvertimeDays() {
    final isEdit = widget.editUser != null;

    if (isEdit) {
      // Preserve existing overtime values when editing
      final existingOvertimeDays = _userData['overtime'];
      if (existingOvertimeDays is Map<String, dynamic>) {
        return {
          'transferred': existingOvertimeDays['transferred'] ?? 0,
          'current': existingOvertimeDays['current'] ?? 0,
          'bonus': existingOvertimeDays['bonus'] ?? 0,
          'used': existingOvertimeDays['used'] ?? 0,
        };
      }
    }

    // For new users, start with default values
    return {
      'transferred': 0,
      'current': 0,
      'bonus': 0,
      'used': 0,
    };
  }

  void _onPrivateAddressChanged(Map<String, dynamic> address) {
    if (mounted) {
      setState(() {
        _privateAddress = address;
        if (_workplaceSame) {
          _workAddress = Map<String, dynamic>.from(address);
        }
      });
    }
  }

  void _onWorkAddressChanged(Map<String, dynamic> address) {
    if (mounted) {
      setState(() {
        _workAddress = address;
      });
    }
  }

  void _onWorkplaceSameChanged(bool value) {
    if (mounted) {
      setState(() {
        _workplaceSame = value;
        if (value) {
          _workAddress = Map<String, dynamic>.from(_privateAddress);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _errorText = '';
      });
    }

    try {
      final isEdit = widget.editUser != null;

      // Prepare user data
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'roles': _selectedRoles,
        'modules': _selectedModules,
        'active': _isActive,
        'workPercent': int.tryParse(_workloadController.text) ?? 100,
        'weeklyHours': int.tryParse(_weeklyHoursController.text) ?? 40,
        'annualLeaveDays': _buildAnnualLeaveDays(),
        'overtime': _buildOvertimeDays(),
        'startDate': _startDateController.text.trim().isEmpty
            ? null
            : _startDateController.text.trim(),
        'teamLeaderId':
            _selectedTeamLeaderId.isEmpty ? null : _selectedTeamLeaderId,
        'showBreaks': _showBreaks,
        'workplaceSame': _workplaceSame,
        'privateAdress': _privateAddress,
        'workAddress': _workAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!isEdit) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (isEdit) {
        // Update existing user
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(widget.editUser!.id)
            .update(userData);
      } else {
        // Create new user
        if (_passwordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters long');
        }

        // Save current user (super admin) credentials before creating new user
        final currentUser = FirebaseAuth.instance.currentUser;
        String? currentUserEmail;

        if (currentUser != null) {
          currentUserEmail = currentUser.email;
        }

        // Check user limit before creating new user (while super admin is still logged in)
        final canAddUser =
            await CompanyModuleService.canAddUser(widget.companyId);
        if (!canAddUser) {
          final userLimit =
              await CompanyModuleService.getCompanyUserLimit(widget.companyId);
          final userCount =
              await CompanyModuleService.getCompanyUserCount(widget.companyId);
          throw Exception(
              'User limit reached. Current: $userCount, Limit: $userLimit. Contact your administrator to increase the limit.');
        }

        // Create user in Firebase Auth
        UserCredential userCredential;
        try {
          userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (authError) {
          String errorMessage = 'Failed to create user account';
          if (authError is FirebaseAuthException) {
            switch (authError.code) {
              case 'email-already-in-use':
                errorMessage =
                    'This email is already registered. Please use a different email.';
                break;
              case 'invalid-email':
                errorMessage = 'Please enter a valid email address.';
                break;
              case 'weak-password':
                errorMessage =
                    'Password is too weak. Please choose a stronger password.';
                break;
              case 'operation-not-allowed':
                errorMessage =
                    'User registration is not enabled. Please contact your administrator.';
                break;
              default:
                errorMessage = 'Authentication error: ${authError.message}';
            }
          }
          throw Exception(errorMessage);
        }

        // Sign out the newly created user immediately
        await FirebaseAuth.instance.signOut();

        // Re-authenticate the super admin
        if (currentUserEmail != null) {
          final success = await _showAdminPasswordDialog(currentUserEmail);
          if (!success) {
            throw Exception('Failed to re-authenticate as super admin');
          }
        }

        // Now add user data to Firestore (with super admin authenticated)
        try {
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);
        } catch (firestoreError) {
          // Clean up the Firebase Auth user if Firestore fails
          try {
            await userCredential.user!.delete();
          } catch (deleteError) {
            AppLogger.warn('Could not delete Firebase Auth user: $deleteError');
          }
          throw Exception('Failed to save user data: $firestoreError');
        }

        // Create userCompany entry
        try {
          await FirebaseFirestore.instance
              .collection('userCompany')
              .doc(userCredential.user!.uid)
              .set({
            'email': _emailController.text.trim(),
            'companyId': widget.companyId,
          });
        } catch (firestoreError) {
          // Clean up the Firebase Auth user if userCompany creation fails
          try {
            await userCredential.user!.delete();
          } catch (deleteError) {
            AppLogger.warn('Could not delete Firebase Auth user: $deleteError');
          }
          throw Exception('Failed to create user mapping: $firestoreError');
        }

        // Increment company user count
        try {
          await CompanyModuleService.incrementUserCount(widget.companyId);
        } catch (countError) {
          AppLogger.warn('Could not increment user count: $countError');
          // Don't fail the entire operation if count increment fails
        }
      }

      if (!mounted) return;
      widget.onUserAdded();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.editUser != null;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? l10n.editUser : l10n.addNewUser,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.primaryBlue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: appColors.textColor),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Limit Indicator (only for new users)
            if (!isEdit) ...[
              FutureBuilder<Map<String, int>>(
                future: _getUserLimitInfo(),
                builder: (context, snapshot) {
                  if (!mounted) return const SizedBox.shrink();

                  if (snapshot.hasData) {
                    final userCount = snapshot.data!['userCount'] ?? 0;
                    final userLimit = snapshot.data!['userLimit'] ?? 10;
                    final isOverLimit = userCount >= userLimit;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isOverLimit
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOverLimit ? Colors.red : Colors.blue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOverLimit ? Icons.warning : Icons.info,
                            color: isOverLimit ? Colors.red : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isOverLimit
                                  ? 'User limit reached ($userCount/$userLimit). Cannot add more users.'
                                  : 'User limit: $userCount/$userLimit',
                              style: TextStyle(
                                color: isOverLimit ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            // Form
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: l10n.firstName,
                              validator: (value) =>
                                  value?.isEmpty == true ? l10n.required : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _surnameController,
                              label: l10n.surname,
                              validator: (value) =>
                                  value?.isEmpty == true ? l10n.required : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: l10n.email,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isEdit,
                              validator: (value) {
                                if (value?.isEmpty == true) {
                                  return l10n.required;
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value!)) {
                                  return l10n.invalidEmail;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: '${l10n.phone} (${l10n.optional})',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Private Address label
                      Text(
                        l10n.privateAddress,
                        style: TextStyle(
                          color: appColors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Private Address fields (no Card)
                      UserAddress(
                        addressData: _privateAddress,
                        onAddressChanged: _onPrivateAddressChanged,
                        title: '',
                        isSwissAddress: true,
                        showCard: false,
                      ),
                      // Workplace same as private address toggle
                      const SizedBox(height: 8),
                      _buildSwitchRow(
                        l10n.workplaceSame,
                        _workplaceSame,
                        _onWorkplaceSameChanged,
                      ),
                      const SizedBox(height: 16),
                      // Work Address label and fields (if needed)
                      if (!_workplaceSame) ...[
                        Text(
                          l10n.workAddress,
                          style: TextStyle(
                            color: appColors.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        UserAddress(
                          addressData: _workAddress,
                          onAddressChanged: _onWorkAddressChanged,
                          title: '',
                          isSwissAddress: false,
                          showCard: false,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Roles as buttons
                      _buildButtonGroup(
                        label: l10n.roles,
                        options: _getAvailableRoles(),
                        values: _selectedRoles,
                        onChanged: (values) =>
                            setState(() => _selectedRoles = values),
                      ),
                      const SizedBox(height: 16),

                      // Modules with locked time tracker
                      _buildModuleButtons(
                        label: l10n.modules,
                        options: [
                          {
                            'label': l10n.timeTracker,
                            'value': 'time_tracker',
                            'locked': true
                          },
                          {
                            'label': l10n.admin,
                            'value': 'admin',
                            'locked': false
                          },
                        ],
                        values: _selectedModules,
                        onChanged: (values) =>
                            setState(() => _selectedModules = values),
                      ),
                      const SizedBox(height: 16),

                      // Work Settings

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _workloadController,
                              label: '${l10n.workload} (%)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = int.tryParse(value ?? '');
                                if (num == null || num < 0 || num > 100) {
                                  return '${l10n.workload} must be between 0-100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _weeklyHoursController,
                              label: l10n.weeklyHours,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = int.tryParse(value ?? '');
                                if (num == null || num < 0) {
                                  return '${l10n.weeklyHours} must be positive';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _annualLeaveController,
                              label: l10n.annualLeave,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = double.tryParse(value ?? '');
                                if (num == null || num < 0) {
                                  return '${l10n.annualLeave} must be a positive number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Start Date field
                      GestureDetector(
                        onTap: () => _showDatePicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white24
                                  : Colors.black26,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? appColors.cardColorDark
                                    : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _startDateController.text.isEmpty
                                      ? 'Select Start Date'
                                      : 'Start Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_startDateController.text))}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: appColors.textColor,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: appColors.primaryBlue,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Team Leader assignment
                      DropdownButtonFormField<String>(
                        value: _selectedTeamLeaderId.isEmpty
                            ? null
                            : _selectedTeamLeaderId,
                        decoration: InputDecoration(
                          labelText: l10n.assignToTeamLeader,
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? appColors.cardColorDark
                                  : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white24
                                  : Colors.black26,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white24
                                  : Colors.black26,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: appColors.primaryBlue, width: 2),
                          ),
                          labelStyle: TextStyle(color: appColors.textColor),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(l10n.none,
                                style: TextStyle(color: appColors.textColor)),
                          ),
                          ...widget.teamLeaders.map((tl) {
                            return DropdownMenuItem(
                              value: tl['id'],
                              child: Text(
                                '${tl['firstName']} ${tl['surname']}',
                                style: TextStyle(color: appColors.textColor),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedTeamLeaderId = value ?? ''),
                        style: TextStyle(color: appColors.textColor),
                      ),
                      const SizedBox(height: 16),

                      // Switches
                      _buildSwitchRow(l10n.active, _isActive,
                          (value) => setState(() => _isActive = value)),
                      const SizedBox(height: 8),
                      _buildSwitchRow(l10n.showBreaks, _showBreaks,
                          (value) => setState(() => _showBreaks = value)),
                      // Password field (only for new users)
                      if (!isEdit) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: l10n.password,
                          obscureText: true,
                          validator: (value) {
                            if (value?.isEmpty == true) {
                              return l10n.required;
                            }
                            if (value!.length < 6) {
                              return l10n.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.passwordMinLength,
                          style: TextStyle(
                              color: appColors.darkGray, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Error text
                      if (_errorText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorText,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBlue,
                            foregroundColor: appColors.whiteTextOnBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        appColors.whiteTextOnBlue),
                                  ),
                                )
                              : Text(
                                  isEdit ? l10n.updateUser : l10n.createUser,
                                  style: TextStyle(
                                    color: appColors.whiteTextOnBlue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? appColors.cardColorDark
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : Colors.black26,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : Colors.black26,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
        ),
        labelStyle: TextStyle(color: appColors.textColor),
      ),
      style: TextStyle(color: appColors.textColor),
    );
  }

  List<Map<String, String>> _getAvailableRoles() {
    final l10n = AppLocalizations.of(context)!;
    final allRoles = [
      {'label': l10n.companyAdmin, 'value': 'company_admin'},
      {'label': l10n.admin, 'value': 'admin'},
      {'label': l10n.teamLeader, 'value': 'team_leader'},
      {'label': l10n.worker, 'value': 'worker'},
    ];

    // Role hierarchy: super_admin > company_admin > admin > team_leader > worker
    if (widget.currentUserRoles.contains('super_admin')) {
      return allRoles; // Super admin can assign all roles
    } else if (widget.currentUserRoles.contains('company_admin')) {
      return allRoles
          .where((role) => role['value'] != 'super_admin')
          .toList(); // Company admin can assign all except super_admin
    } else if (widget.currentUserRoles.contains('admin')) {
      return allRoles
          .where((role) =>
              !['super_admin', 'company_admin'].contains(role['value']))
          .toList(); // Admin can assign team_leader and worker
    } else {
      return []; // Lower level users cannot assign roles
    }
  }

  Widget _buildButtonGroup({
    required String label,
    required List<Map<String, String>> options,
    required List<String> values,
    required Function(List<String>) onChanged,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = values.contains(option['value']);
            return InkWell(
              onTap: () {
                final newValues = List<String>.from(values);
                if (isSelected) {
                  newValues.remove(option['value']!);
                } else {
                  newValues.add(option['value']!);
                }
                onChanged(newValues);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? appColors.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? appColors.primaryBlue : appColors.darkGray,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : appColors.textColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModuleButtons({
    required String label,
    required List<Map<String, dynamic>> options,
    required List<String> values,
    required Function(List<String>) onChanged,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = values.contains(option['value']);
            final isLocked = option['locked'] == true;

            return InkWell(
              onTap: isLocked
                  ? null
                  : () {
                      final newValues = List<String>.from(values);
                      if (isSelected) {
                        newValues.remove(option['value']!);
                      } else {
                        newValues.add(option['value']!);
                      }
                      onChanged(newValues);
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLocked || isSelected
                      ? appColors.primaryBlue
                      : Colors.transparent,
                  border: Border.all(
                    color: isLocked || isSelected
                        ? appColors.primaryBlue
                        : appColors.darkGray,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option['label']!,
                      style: TextStyle(
                        color: isLocked || isSelected
                            ? Colors.white
                            : appColors.textColor,
                        fontWeight: isLocked || isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: appColors.primaryBlue,
        ),
      ],
    );
  }

  Future<Map<String, int>> _getUserLimitInfo() async {
    try {
      final userCount =
          await CompanyModuleService.getCompanyUserCount(widget.companyId);
      final userLimit =
          await CompanyModuleService.getCompanyUserLimit(widget.companyId);
      return {
        'userCount': userCount,
        'userLimit': userLimit,
      };
    } catch (e) {
      AppLogger.error('Error getting user limit info: $e');
      return {
        'userCount': 0,
        'userLimit': 10,
      };
    }
  }

  Future<bool> _showAdminPasswordDialog(String adminEmail) async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    final appColors = Theme.of(context).extension<AppColors>()!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Admin Authentication'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please enter your admin password to continue:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Admin Password',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) async {
                      if (passwordController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          // Sign in as admin
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: adminEmail,
                            password: passwordController.text,
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            errorMessage =
                                'Invalid password. Please try again.';
                            isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                if (!isLoading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (passwordController.text.isNotEmpty) {
                        setState(() => isLoading = true);
                        try {
                          // Sign in as admin
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: adminEmail,
                            password: passwordController.text,
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            errorMessage =
                                'Invalid password. Please try again.';
                            isLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primaryBlue,
                      foregroundColor: appColors.whiteTextOnBlue,
                    ),
                    child: const Text('OK'),
                  ),
                ],
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workloadController.dispose();
    _weeklyHoursController.dispose();
    _annualLeaveController.dispose();
    _passwordController.dispose();
    _startDateController.dispose();
    super.dispose();
  }
}
