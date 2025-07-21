import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:starktrack/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AdminPanel extends StatefulWidget {
  final String companyId;
  final List<String> currentUserRoles;

  const AdminPanel({
    Key? key,
    required this.companyId,
    required this.currentUserRoles,
  }) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _searchText = '';
  List<Map<String, dynamic>> _teamLeaders = [];

  bool get isSuperAdmin => widget.currentUserRoles.contains('super_admin');

  @override
  void initState() {
    super.initState();
    _fetchTeamLeaders();
  }

  Future<void> _fetchTeamLeaders() async {
    final res = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .where('roles', arrayContains: 'team_leader')
        .get();
    _teamLeaders = res.docs
        .map((d) => {
              'id': d.id,
              'firstName': d['firstName'] ?? '',
              'surname': d['surname'] ?? '',
            })
        .toList();
    setState(() {});
  }

  void _showUserDialog({DocumentSnapshot? editUser}) async {
    final isEdit = editUser != null;
    Map<String, dynamic> userData = {
      'firstName': '',
      'surname': '',
      'email': '',
      'phone': '',
      'address': '',
      'roles': <String>[],
      'modules': <String>['time_tracker'], // Always include time_tracker!
      'active': true,
      'workPercent': 100,
      'weeklyHours': 40,
      'teamLeaderId': '',
      'showBreaks': true,
    };

    if (isEdit) {
      userData.addAll(editUser.data() as Map<String, dynamic>);
      if (!(userData['modules'] as List).contains('time_tracker')) {
        (userData['modules'] as List).add('time_tracker'); // Enforce on edit, too
      }
    }
// In case showBreaks is missing in old user, default to true
    if (!userData.containsKey('showBreaks')) {
      userData['showBreaks'] = true;
    }
  
    String password = '';
    String errorText = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final appColors = Theme.of(ctx).extension<AppColors>()!;
        final l10n = AppLocalizations.of(ctx)!;
        return StatefulBuilder(builder: (ctx, setState) {
          return Dialog(
            backgroundColor: appColors.backgroundDark,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [


                      Text(isEdit ? l10n.editUser : l10n.addNewUser,
                          style: TextStyle(
                            fontSize: 22,
                            color: appColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 20),

                      _themedTextField(
                        ctx,
                        label: l10n.firstName,
                        initialValue: userData['firstName'],
                        onChanged: (v) => userData['firstName'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: l10n.surname,
                        initialValue: userData['surname'],
                        onChanged: (v) => userData['surname'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: l10n.email,
                        initialValue: userData['email'],
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => userData['email'] = v,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: '${l10n.phone} (${l10n.optional})',
                        initialValue: userData['phone'] ?? '',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => userData['phone'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: '${l10n.address} (${l10n.optional})',
                        initialValue: userData['address'] ?? '',
                        onChanged: (v) => userData['address'] = v,
                      ),
                      const SizedBox(height: 12),

                      _themedCheckboxGroup(
                        ctx: ctx,
                        label: l10n.roles,
                        options: [
                          {'label': l10n.superAdmin, 'value': 'super_admin'},
                          {'label': l10n.companyAdmin, 'value': 'company_admin'},
                          {'label': l10n.admin, 'value': 'admin'},
                          {'label': l10n.teamLeader, 'value': 'team_leader'},
                          {'label': l10n.worker, 'value': 'worker'},
                        ],
                        values: List<String>.from(userData['roles']),
                        onChanged: (val) => setState(() => userData['roles'] = val),
                      ),
                      const SizedBox(height: 12),

                      // Time Tracker always ON and cannot be disabled
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: null, // disabled
                            activeColor: appColors.primaryBlue,
                          ),
                          Text('${l10n.timeTracker} (${l10n.required}, ${l10n.includesHistory})',
                              style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      _themedCheckboxGroup(
                        ctx: ctx,
                        label: l10n.additionalModules,
                        options: [
                          {'label': l10n.admin, 'value': 'admin'},
                          // Add more modules here if needed in future
                        ],
                        values: List<String>.from(userData['modules'])
                            .where((m) => m != 'time_tracker')
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            userData['modules'] = ['time_tracker', ...val];
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Active status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.active,
                              style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w600)),
                          Switch(
                            value: userData['active'] ?? true,
                            onChanged: (val) => setState(() => userData['active'] = val),
                            activeColor: appColors.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Show breaks option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.showBreaks,
                              style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w600)),
                          Switch(
                            value: userData['showBreaks'] ?? true,
                            onChanged: (val) => setState(() => userData['showBreaks'] = val),
                            activeColor: appColors.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _themedTextField(
                        ctx,
                        label: '${l10n.workload} (%)',
                        initialValue: '${userData['workPercent'] ?? 100}',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => userData['workPercent'] = int.tryParse(v) ?? 100,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: l10n.weeklyHours,
                        initialValue: '${userData['weeklyHours'] ?? 40}',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => userData['weeklyHours'] = int.tryParse(v) ?? 40,
                      ),
                      const SizedBox(height: 12),

                      // Team Leader assignment
                      DropdownButtonFormField<String>(
                        value: userData['teamLeaderId'] == null || userData['teamLeaderId'].toString().isEmpty
                            ? ''
                            : userData['teamLeaderId'],
                        decoration: InputDecoration(
                          labelText: l10n.assignToTeamLeader,
                          filled: true,
                          fillColor: appColors.lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(l10n.none,
                                style: TextStyle(color: appColors.textColor)),
                          ),
                          ..._teamLeaders.map((tl) {
                            return DropdownMenuItem(
                              value: tl['id'],
                              child: Text(
                                '${tl['firstName']} ${tl['surname']}',
                                style: TextStyle(color: appColors.textColor),
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) =>
                            setState(() => userData['teamLeaderId'] = v ?? ''),
                      ),
                      const SizedBox(height: 18),

                      if (!isEdit) ...[
                        _themedTextField(
                          ctx,
                          label: l10n.passwordManualEntry,
                          obscureText: true,
                          onChanged: (v) => password = v,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.passwordMinLength,
                          style: TextStyle(color: appColors.darkGray, fontSize: 13),
                        ),
                      ],

                      if (errorText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(errorText,
                              style: TextStyle(
                                  color: appColors.error, fontSize: 13)),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBlue,
                            foregroundColor: appColors.whiteTextOnBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setState(() {
                                    errorText = '';
                                    isSubmitting = true;
                                  });

                                  // Validation
                                  if (userData['firstName'].toString().trim().isEmpty ||
                                      userData['surname'].toString().trim().isEmpty ||
                                      userData['email'].toString().trim().isEmpty) {
                                    setState(() {
                                      errorText = l10n.firstNameSurnameEmailRequired;
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  if (userData['roles'] == null ||
                                      (userData['roles'] as List).isEmpty) {
                                    setState(() {
                                      errorText = l10n.atLeastOneRoleRequired;
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  if (userData['modules'] == null ||
                                      (userData['modules'] as List).isEmpty) {
                                    setState(() {
                                      errorText = l10n.atLeastOneModuleRequired;
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  if (!isEdit && password.length < 6) {
                                    setState(() {
                                      errorText = l10n.passwordMustBeAtLeast6Characters;
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  try {
                                    if (isEdit) {
                                      // Update existing user
                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(widget.companyId)
                                          .collection('users')
                                          .doc(editUser.id)
                                          .update(userData);
                                    } else {
                                      // Prompt admin for password before creating a new user
                                      final adminEmail = FirebaseAuth.instance.currentUser!.email;
                                      String? adminPassword;
                                      await showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (ctx) {
                                          String tempPassword = '';
                                          return AlertDialog(
                                            title: Text(l10n.adminPasswordRequired),
                                            content: TextField(
                                              obscureText: true,
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                labelText: l10n.enterYourPassword,
                                              ),
                                              onChanged: (v) => tempPassword = v,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                },
                                                child: Text(l10n.cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  adminPassword = tempPassword;
                                                  Navigator.of(ctx).pop();
                                                },
                                                child: Text(l10n.confirm),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (adminPassword == null || adminPassword!.isEmpty) {
                                        setState(() {
                                          errorText = l10n.adminPasswordRequired;
                                          isSubmitting = false;
                                        });
                                        return;
                                      }

                                      // 1. Create the new user (this signs in as the new user)
                                      final newAuthUser = await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                              email: userData['email'],
                                              password: password);

                                      // 2. Immediately sign back in as the admin
                                      await FirebaseAuth.instance.signOut();
                                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                                        email: adminEmail!,
                                        password: adminPassword!,
                                      );

                                      // 3. Write to Firestore as the admin
                                      await FirebaseFirestore.instance
                                          .collection('userCompany')
                                          .doc(newAuthUser.user!.uid)
                                          .set({
                                            'email': userData['email'],
                                            'companyId': widget.companyId,
                                          });
                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(widget.companyId)
                                          .collection('users')
                                          .doc(newAuthUser.user!.uid)
                                          .set(userData);
                                    }

                                    Navigator.of(ctx).pop();
                                    _fetchTeamLeaders(); // Refresh the list
                                  } on FirebaseAuthException catch (e) {
                                    if (e.code == 'email-already-in-use') {
                                      setState(() {
                                        errorText = l10n.userWithThisEmailAlreadyExists;
                                        isSubmitting = false;
                                      });
                                    } else if (e.code == 'permission-denied') {
                                      // Check if trying to edit company admin
                                      final isCompanyAdmin = (userData['roles'] as List).contains('company_admin');
                                      if (isCompanyAdmin && !isSuperAdmin) {
                                        setState(() {
                                          errorText = l10n.onlySuperAdminCanEditCompanyAdmin;
                                          isSubmitting = false;
                                        });
                                        return;
                                      }
                                      try {
                                        // Only try to delete if we have a newAuthUser
                                        if (!isEdit) {
                                          final newAuthUser = await FirebaseAuth.instance
                                              .createUserWithEmailAndPassword(
                                                  email: userData['email'],
                                                  password: password);
                                          await newAuthUser.user!.delete();
                                        }
                                        setState(() {
                                          errorText = l10n.permissionDenied(e.message ?? '');
                                          isSubmitting = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          errorText = l10n.authError;
                                          isSubmitting = false;
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        errorText = e.message ?? l10n.authError;
                                        isSubmitting = false;
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      errorText = l10n.unknownError(e.toString());
                                      isSubmitting = false;
                                    });
                                  }
                                },
                          child: Text(isEdit ? l10n.saveChanges : l10n.createUser,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      // Password reset button only in EDIT mode
                      if (isEdit)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.lock_reset, color: appColors.whiteTextOnBlue),
                              label: Text(l10n.sendPasswordResetEmail,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appColors.whiteTextOnBlue,
                                  fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryBlue,
                                foregroundColor: appColors.whiteTextOnBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                try {
                                  await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: userData['email']);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.passwordResetEmailSent(userData['email'])),
                                        backgroundColor: appColors.primaryBlue,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.failedToSendResetEmail(e.toString())),
                                        backgroundColor: appColors.red,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _themedTextField(
    BuildContext ctx, {
    required String label,
    String? initialValue,
    bool obscureText = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    final appColors = Theme.of(ctx).extension<AppColors>()!;
    final controller = TextEditingController(text: initialValue ?? '');
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(color: appColors.textColor),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: appColors.lightGray,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: appColors.darkGray, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(color: appColors.darkGray),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
    );
  }

  Widget _themedCheckboxGroup({
    required BuildContext ctx,
    required String label,
    required List<Map<String, String>> options,
    required List<String> values,
    required Function(List<String>) onChanged,
  }) {
    final appColors = Theme.of(ctx).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: appColors.textColor, fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final checked = values.contains(option['value']);
            return FilterChip(
              selected: checked,
              label: Text(option['label']!,
                  style: TextStyle(
                      color: checked ? appColors.whiteTextOnBlue : appColors.textColor)),
              selectedColor: appColors.primaryBlue,
              backgroundColor: appColors.lightGray,
              checkmarkColor: appColors.whiteTextOnBlue,
              onSelected: (val) {
                final newValues = List<String>.from(values);
                if (val) {
                  newValues.add(option['value']!);
                } else {
                  newValues.remove(option['value']!);
                }
                onChanged(newValues);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data, DocumentSnapshot doc, AppColors colors, AppLocalizations l10n) {
    // Helper function to get role display names
    String getRoleDisplayName(String role) {
      switch (role) {
        case 'super_admin':
          return l10n.superAdmin;
        case 'company_admin':
          return l10n.companyAdmin;
        case 'admin':
          return l10n.admin;
        case 'team_leader':
          return l10n.teamLeader;
        case 'worker':
          return l10n.worker;
        default:
          return role;
      }
    }

    // Helper function to get module display names
    String getModuleDisplayName(String module) {
      switch (module) {
        case 'time_tracker':
          return l10n.timeTracker;
        case 'admin':
          return l10n.admin;
        default:
          return module;
      }
    }

    // Helper function to get team leader name
    String getTeamLeaderName(String? teamLeaderId) {
      if (teamLeaderId == null || teamLeaderId.isEmpty) {
        return l10n.none;
      }
      final teamLeader = _teamLeaders.firstWhere(
        (tl) => tl['id'] == teamLeaderId,
        orElse: () => {'firstName': l10n.unknown, 'surname': l10n.worker},
      );
      return '${teamLeader['firstName']} ${teamLeader['surname']}';
    }

    final roles = (data['roles'] as List?)?.map((r) => getRoleDisplayName(r.toString())).toList() ?? [];
    final modules = (data['modules'] as List?)?.map((m) => getModuleDisplayName(m.toString())).toList() ?? [];
    final workload = data['workPercent'] ?? 100;
    final weeklyHours = data['weeklyHours'] ?? 40;
    final isActive = data['active'] ?? true;
    final showBreaks = data['showBreaks'] ?? true;
    final isCompanyAdmin = (data['roles'] as List).contains('company_admin');
    final isSuperAdmin = (data['roles'] as List).contains('super_admin');
    final isProtectedUser = isCompanyAdmin || isSuperAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.cardColorDark,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Email
            Text(
              '${data['firstName']} ${data['surname']}',
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['email'] ?? '',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            // Contact Information
            if (data['phone'] != null && data['phone'].toString().isNotEmpty) ...[
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.phone}: ',
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: data['phone'],
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (data['address'] != null && data['address'].toString().isNotEmpty) ...[
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.address}: ',
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: data['address'],
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Roles
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.roles}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: roles.join(', '),
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Modules
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.modules}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: modules.join(', '),
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Workload and Weekly Hours
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.workload}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '$workload%',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.weeklyHours}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '$weeklyHours',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Status information
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.active}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: isActive ? l10n.yes : l10n.no,
                    style: TextStyle(
                      color: isActive ? Colors.green : colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.showBreaks}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: showBreaks ? l10n.yes : l10n.no,
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Team Leader Assignment
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.teamLeader}: ',
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: getTeamLeaderName(data['teamLeaderId']),
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons at the bottom left
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isProtectedUser ? colors.darkGray : colors.primaryBlue,
                    size: 20,
                  ),
                  onPressed: isProtectedUser ? null : () => _showUserDialog(editUser: doc),
                  tooltip: isProtectedUser ? '${isSuperAdmin ? l10n.superAdmin : l10n.companyAdmin} ${l10n.cannotBeEdited}' : l10n.edit,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: isProtectedUser ? colors.darkGray : colors.red,
                    size: 20,
                  ),
                  onPressed: isProtectedUser ? null : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.confirmDelete),
                        content: Text(l10n.confirmDeleteMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            child: Text(l10n.delete),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.red,
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop(true);
                              await doc.reference.delete();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: isProtectedUser ? '${isSuperAdmin ? l10n.superAdmin : l10n.companyAdmin} ${l10n.cannotBeDeleted}' : l10n.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Container(
      color: colors.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
        child: Column(
          children: [
            // Search bar and Add User Button in a Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.cardColorDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchText = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchByNameEmailRole,
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.person_add, color: colors.whiteTextOnBlue),
                  label: Text(l10n.addNewUser,
                      style: TextStyle(
                          color: colors.whiteTextOnBlue,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showUserDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Users List
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(widget.companyId)
                    .collection('users')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMembersFound,
                        style: TextStyle(color: colors.textColor),
                      ),
                    );
                  }

                  final filteredUsers = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final searchLower = _searchText.toLowerCase();
                    return data['firstName'].toString().toLowerCase().contains(searchLower) ||
                           data['surname'].toString().toLowerCase().contains(searchLower) ||
                           data['email'].toString().toLowerCase().contains(searchLower) ||
                           data['roles'].toString().toLowerCase().contains(searchLower);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      return _buildUserCard(data, doc, colors, l10n);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
