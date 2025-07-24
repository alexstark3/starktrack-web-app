import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'user_address.dart';

class AddUserDialog extends StatefulWidget {
  final String companyId;
  final List<Map<String, dynamic>> teamLeaders;
  final DocumentSnapshot? editUser;
  final Function() onUserAdded;
  final List<String> currentUserRoles;

  const AddUserDialog({
    Key? key,
    required this.companyId,
    required this.teamLeaders,
    this.editUser,
    required this.onUserAdded,
    required this.currentUserRoles,
  }) : super(key: key);

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
      _privateAddress = Map<String, dynamic>.from(_userData['privateAdress'] ?? {});
      _workAddress = Map<String, dynamic>.from(_userData['workAddress'] ?? {});
      
      // Initialize form values
      _selectedRoles = List<String>.from(_userData['roles'] ?? []);
      _selectedModules = List<String>.from(_userData['modules'] ?? ['time_tracker']);
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
        'teamLeaderId': '',
        'showBreaks': true,
        'workplaceSame': true,
        'privateAdress': {},
        'workAddress': {},
      };
      
      _privateAddress = {};
      _workAddress = {};
    }
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: _userData['firstName'] ?? '');
    _surnameController = TextEditingController(text: _userData['surname'] ?? '');
    _emailController = TextEditingController(text: _userData['email'] ?? '');
    _phoneController = TextEditingController(text: _userData['phone'] ?? '');
    _workloadController = TextEditingController(text: '${_userData['workPercent'] ?? 100}');
    _weeklyHoursController = TextEditingController(text: '${_userData['weeklyHours'] ?? 40}');
    _annualLeaveController = TextEditingController(text: '${_userData['annualLeaveDays'] ?? 25}');
    _passwordController = TextEditingController();
  }

  void _onPrivateAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _privateAddress = address;
      if (_workplaceSame) {
        _workAddress = Map<String, dynamic>.from(address);
      }
    });
  }

  void _onWorkAddressChanged(Map<String, dynamic> address) {
    setState(() {
      _workAddress = address;
    });
  }

  void _onWorkplaceSameChanged(bool value) {
    setState(() {
      _workplaceSame = value;
      if (value) {
        _workAddress = Map<String, dynamic>.from(_privateAddress);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _errorText = '';
    });

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
        'annualLeaveDays': int.tryParse(_annualLeaveController.text) ?? 25,
        'teamLeaderId': _selectedTeamLeaderId.isEmpty ? null : _selectedTeamLeaderId,
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

        // Create user in Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Add user data to Firestore
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
      }

      widget.onUserAdded();
      Navigator.of(context).pop();
      
    } catch (e) {
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.editUser != null;

    return Dialog(
      backgroundColor: appColors.backgroundDark,
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24.0),
        child: Column(
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

            // Form
            Expanded(
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
                              validator: (value) => value?.isEmpty == true ? l10n.required : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _surnameController,
                              label: l10n.surname,
                              validator: (value) => value?.isEmpty == true ? l10n.required : null,
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
                                if (value?.isEmpty == true) return l10n.required;
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
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
                        onChanged: (values) => setState(() => _selectedRoles = values),
                      ),
                      const SizedBox(height: 16),

                      // Modules with locked time tracker
                      _buildModuleButtons(
                        label: l10n.modules,
                        options: [
                          {'label': l10n.timeTracker, 'value': 'time_tracker', 'locked': true},
                          {'label': l10n.admin, 'value': 'admin', 'locked': false},
                        ],
                        values: _selectedModules,
                        onChanged: (values) => setState(() => _selectedModules = values),
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
                                final num = int.tryParse(value ?? '');
                                if (num == null || num < 0) {
                                  return '${l10n.annualLeave} must be positive';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Team Leader assignment
                      DropdownButtonFormField<String>(
                        value: _selectedTeamLeaderId.isEmpty ? null : _selectedTeamLeaderId,
                        decoration: InputDecoration(
                          labelText: l10n.assignToTeamLeader,
                          filled: true,
                          fillColor: appColors.lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: appColors.darkGray, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: appColors.darkGray, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(l10n.none, style: TextStyle(color: appColors.textColor)),
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
                        onChanged: (value) => setState(() => _selectedTeamLeaderId = value ?? ''),
                      ),
                      const SizedBox(height: 16),

                      // Switches
                      _buildSwitchRow(l10n.active, _isActive, (value) => setState(() => _isActive = value)),
                      const SizedBox(height: 8),
                      _buildSwitchRow(l10n.showBreaks, _showBreaks, (value) => setState(() => _showBreaks = value)),
                      // Password field (only for new users)
                      if (!isEdit) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: l10n.password,
                          obscureText: true,
                          validator: (value) {
                            if (value?.isEmpty == true) return l10n.required;
                            if (value!.length < 6) return l10n.passwordMinLength;
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.passwordMinLength,
                          style: TextStyle(color: appColors.darkGray, fontSize: 12),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(appColors.backgroundDark),
                                  ),
                                )
                              : Text(
                                  isEdit ? l10n.updateUser : l10n.createUser,
                                  style: TextStyle(
                                    color: appColors.backgroundDark,
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
        fillColor: appColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: appColors.darkGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: appColors.darkGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
        ),
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
      return allRoles.where((role) => role['value'] != 'super_admin').toList(); // Company admin can assign all except super_admin
    } else if (widget.currentUserRoles.contains('admin')) {
      return allRoles.where((role) => !['super_admin', 'company_admin'].contains(role['value'])).toList(); // Admin can assign team_leader and worker
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? appColors.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? appColors.primaryBlue : appColors.darkGray,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : appColors.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              onTap: isLocked ? null : () {
                final newValues = List<String>.from(values);
                if (isSelected) {
                  newValues.remove(option['value']!);
                } else {
                  newValues.add(option['value']!);
                }
                onChanged(newValues);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLocked || isSelected ? appColors.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isLocked || isSelected ? appColors.primaryBlue : appColors.darkGray,
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
                        color: isLocked || isSelected ? Colors.white : appColors.textColor,
                        fontWeight: isLocked || isSelected ? FontWeight.w600 : FontWeight.normal,
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
    super.dispose();
  }
}
