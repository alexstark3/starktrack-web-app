import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:starktrack/theme/app_colors.dart';

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
    };

    if (isEdit) {
      userData.addAll(editUser.data() as Map<String, dynamic>);
      if (!(userData['modules'] as List).contains('time_tracker')) {
        (userData['modules'] as List).add('time_tracker'); // Enforce on edit, too
      }
    }

    String password = '';
    bool manualPassword = false;
    String errorText = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final appColors = Theme.of(ctx).extension<AppColors>()!;
        return StatefulBuilder(builder: (ctx, setState) {
          return Dialog(
            backgroundColor: appColors.backgroundLight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isEdit ? 'Edit User' : 'Add New User',
                          style: TextStyle(
                            fontSize: 22,
                            color: appColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 20),

                      _themedTextField(
                        ctx,
                        label: 'First Name',
                        initialValue: userData['firstName'],
                        onChanged: (v) => userData['firstName'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: 'Surname',
                        initialValue: userData['surname'],
                        onChanged: (v) => userData['surname'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: 'Email',
                        initialValue: userData['email'],
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => userData['email'] = v,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: 'Phone (optional)',
                        initialValue: userData['phone'] ?? '',
                        keyboardType: TextInputType.phone,
                        onChanged: (v) => userData['phone'] = v,
                      ),
                      const SizedBox(height: 10),

                      _themedTextField(
                        ctx,
                        label: 'Address (optional)',
                        initialValue: userData['address'] ?? '',
                        onChanged: (v) => userData['address'] = v,
                      ),
                      const SizedBox(height: 16),

                      _themedCheckboxGroup(
                        ctx: ctx,
                        label: 'Roles',
                        options: const [
                          {'label': 'Company Admin', 'value': 'company_admin'},
                          {'label': 'Admin', 'value': 'admin'},
                          {'label': 'Team Leader', 'value': 'team_leader'},
                          {'label': 'Worker', 'value': 'worker'},
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
                          Text('Time Tracker (required, includes History)',
                              style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      _themedCheckboxGroup(
                        ctx: ctx,
                        label: 'Additional Modules',
                        options: const [
                          {'label': 'Admin', 'value': 'admin'},
                          // Add more modules here if needed in future
                        ],
                        values: List<String>.from(userData['modules'])
                            .where((m) => m != 'time_tracker')
                            .toList(),
                        onChanged: (val) {
                          // Always include 'time_tracker'
                          final modules = <String>{'time_tracker', ...val};
                          setState(() => userData['modules'] = modules.toList());
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active',
                              style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w500)),
                          Switch(
                            value: userData['active'],
                            activeColor: appColors.primaryBlue,
                            inactiveThumbColor: appColors.lightGray,
                            onChanged: (v) =>
                                setState(() => userData['active'] = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _themedTextField(
                        ctx,
                        label: 'Workload (%)',
                        initialValue: '${userData['workPercent'] ?? 100}',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => userData['workPercent'] =
                            int.tryParse(v) ?? 100,
                      ),
                      const SizedBox(height: 8),

                      _themedTextField(
                        ctx,
                        label: 'Weekly Hours',
                        initialValue: '${userData['weeklyHours'] ?? 40}',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => userData['weeklyHours'] =
                            int.tryParse(v) ?? 40,
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: userData['teamLeaderId'] == ''
                            ? null
                            : userData['teamLeaderId'],
                        decoration: InputDecoration(
                          labelText: 'Assign to Team Leader',
                          filled: true,
                          fillColor: appColors.lightGray,
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: appColors.darkGray, width: 1.2),
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text('None',
                                style: TextStyle(color: appColors.textColor)),
                          ),
                          ..._teamLeaders.map((tl) {
                            return DropdownMenuItem(
                              value: tl['id'],
                              child: Text(
                                  '${tl['firstName']} ${tl['surname']}',
                                  style: TextStyle(color: appColors.textColor)),
                            );
                          }),
                        ],
                        onChanged: (v) =>
                            setState(() => userData['teamLeaderId'] = v ?? ''),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Checkbox(
                            value: manualPassword,
                            activeColor: appColors.primaryBlue,
                            onChanged: (val) =>
                                setState(() => manualPassword = val ?? false),
                          ),
                          Text('Set password manually',
                              style: TextStyle(
                                  color: appColors.textColor, fontSize: 15)),
                        ],
                      ),
                      if (manualPassword)
                        _themedTextField(
                          ctx,
                          label: 'Password',
                          obscureText: true,
                          onChanged: (v) => password = v,
                        ),
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

                                  // VALIDATION
                                  if ((userData['firstName'] ?? '').isEmpty ||
                                      (userData['surname'] ?? '').isEmpty ||
                                      (userData['email'] ?? '').isEmpty) {
                                    setState(() {
                                      errorText =
                                          'First Name, Surname, and Email are required!';
                                      isSubmitting = false;
                                    });
                                    return;
                                  }
                                  if (userData['roles'] == null ||
                                      (userData['roles'] as List).isEmpty) {
                                    setState(() {
                                      errorText = 'At least one role is required!';
                                      isSubmitting = false;
                                    });
                                    return;
                                  }
                                  // Make sure modules always includes 'time_tracker'
                                  final modules = Set<String>.from(userData['modules'] ?? []);
                                  modules.add('time_tracker');
                                  userData['modules'] = modules.toList();

                                  if (userData['modules'] == null ||
                                      (userData['modules'] as List).isEmpty) {
                                    setState(() {
                                      errorText = 'At least one module is required!';
                                      isSubmitting = false;
                                    });
                                    return;
                                  }
                                  if (manualPassword && password.length < 6) {
                                    setState(() {
                                      errorText = 'Password must be at least 6 characters!';
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  // Check if email already exists in Firestore
                                  if (!manualPassword && !isEdit) {
                                    var existing = await FirebaseFirestore
                                        .instance
                                        .collection('companies')
                                        .doc(widget.companyId)
                                        .collection('users')
                                        .where('email', isEqualTo: userData['email'])
                                        .get();
                                    if (existing.docs.isNotEmpty) {
                                      setState(() {
                                        errorText =
                                            'A user with this email already exists.';
                                        isSubmitting = false;
                                      });
                                      return;
                                    }
                                  }

                                  try {
                                    if (isEdit) {
                                      final isCompanyAdmin = (userData['roles'] as List<dynamic>).contains('company_admin');
                                      if (isCompanyAdmin && !isSuperAdmin) {
                                        setState(() {
                                          errorText = "Only super admin can edit the company admin.";
                                          isSubmitting = false;
                                        });
                                        return;
                                      }
                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(widget.companyId)
                                          .collection('users')
                                          .doc(editUser.id)
                                          .update(userData);
                                    } else {
                                      UserCredential? newAuthUser;
                                      // === Create Auth user first ===
                                      if (manualPassword) {
                                        try {
                                          newAuthUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                            email: userData['email'],
                                            password: password,
                                          );
                                        } on FirebaseAuthException catch (e) {
                                          setState(() {
                                            errorText = e.message ?? 'Auth error';
                                            isSubmitting = false;
                                          });
                                          return;
                                        }
                                      } else {
                                        setState(() {
                                          errorText = 'Registration by invite link is not yet supported in this dialog.';
                                          isSubmitting = false;
                                        });
                                        return;
                                      }
                                      // === Try to create Firestore doc with Auth UID ===
                                      try {
                                        print('==== DEBUG: About to write userData to Firestore ====');
                                        print('userData = $userData');
                                        print('companyId = ${widget.companyId}');
                                        print('newAuthUser UID = ${newAuthUser.user!.uid}');
                                        await FirebaseFirestore.instance
                                            .collection('companies')
                                            .doc(widget.companyId)
                                            .collection('users')
                                            .doc(newAuthUser.user!.uid)
                                            .set(userData);
                                      } on FirebaseException catch (e) {
                                        await newAuthUser.user!.delete();
                                        setState(() {
                                          errorText = 'Permission denied: ${e.message}';
                                          isSubmitting = false;
                                        });
                                        return;
                                      }
                                    }
                                    Navigator.of(ctx).pop();
                                  } catch (e) {
                                    setState(() {
                                      errorText = 'Unknown error: $e';
                                      isSubmitting = false;
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: appColors.whiteTextOnBlue,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(isEdit ? 'Save Changes' : 'Create User',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: appColors.whiteTextOnBlue,
                                      fontSize: 16)),
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
          borderSide: BorderSide(
              color: appColors.darkGray, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(color: appColors.darkGray),
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

  String _roleLabel(dynamic v) {
    switch (v) {
      case 'company_admin':
        return 'Company Admin';
      case 'admin':
        return 'Admin';
      case 'team_leader':
        return 'Team Leader';
      case 'worker':
        return 'Worker';
      default:
        return v.toString();
    }
  }

  String _moduleLabel(dynamic v) {
    switch (v) {
      case 'time_tracker':
        return 'Time Tracker';
      case 'admin':
        return 'Admin';
      default:
        return v.toString();
    }
  }

  String _teamLeaderName(dynamic id) {
    if (id == null || id == '') return '-';
    try {
      final match = _teamLeaders.firstWhere((tl) => tl['id'] == id, orElse: () => {});
      if (match.isEmpty) return '-';
      return '${match['firstName']} ${match['surname']}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      color: appColors.dashboardBackground,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: appColors.darkGray),
                    hintText: 'Search by name, email, or role',
                    hintStyle: TextStyle(color: appColors.darkGray),
                    filled: true,
                    fillColor: appColors.lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.darkGray),
                    ),
                  ),
                  style: TextStyle(color: appColors.textColor),
                  onChanged: (v) => setState(() => _searchText = v.trim()),
                ),
              ),
              const SizedBox(width: 18),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add, color: appColors.whiteTextOnBlue),
                label: Text('Add New User',
                    style: TextStyle(
                        color: appColors.whiteTextOnBlue,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showUserDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final s = _searchText.toLowerCase();
                    return (d['firstName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(s) ||
                        (d['surname'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(s) ||
                        (d['email'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(s) ||
                        (d['roles'] ?? [])
                            .toString()
                            .toLowerCase()
                            .contains(s);
                  }).toList();
                }
                return Card(
                  color: appColors.lightGray,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.all(appColors.primaryBlue.withOpacity(0.14)),
                      dataRowColor: MaterialStateProperty.all(appColors.lightGray),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Roles')),
                        DataColumn(label: Text('Modules')),
                        DataColumn(label: Text('Active')),
                        DataColumn(label: Text('Team Leader')),
                        DataColumn(label: Text('Workload')),
                        DataColumn(label: Text('Weekly Hours')),
                        DataColumn(label: Text('Edit')),
                        DataColumn(label: Text('Delete')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final bool isCompanyAdmin = (data['roles'] as List<dynamic>?)?.contains('company_admin') == true;

                        return DataRow(cells: [
                          DataCell(Text(
                            '${data['firstName'] ?? ''} ${data['surname'] ?? ''}',
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Text(
                            data['email'] ?? '',
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Text(
                            (data['roles'] as List<dynamic>? ?? [])
                                .map((e) => _roleLabel(e))
                                .join(', '),
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Text(
                            (data['modules'] as List<dynamic>? ?? [])
                                .map((e) => _moduleLabel(e))
                                .join(', '),
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Switch(
                            value: data['active'] ?? true,
                            activeColor: appColors.primaryBlue,
                            inactiveThumbColor: appColors.lightGray,
                            onChanged: (v) {
                              FirebaseFirestore.instance
                                  .collection('companies')
                                  .doc(widget.companyId)
                                  .collection('users')
                                  .doc(doc.id)
                                  .update({'active': v});
                            },
                          )),
                          DataCell(Text(
                            _teamLeaderName(data['teamLeaderId']),
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Text(
                            '${data['workPercent'] ?? 100}%',
                            style: TextStyle(color: appColors.textColor),
                          )),
                          DataCell(Text(
                            '${data['weeklyHours'] ?? 40}h',
                            style: TextStyle(color: appColors.textColor),
                          )),
                          // EDIT
                          DataCell(
                            isCompanyAdmin && !isSuperAdmin
                              ? Icon(Icons.lock, color: appColors.darkGray)
                              : IconButton(
                                  icon: Icon(Icons.edit, color: appColors.primaryBlue),
                                  onPressed: () => _showUserDialog(editUser: doc),
                                ),
                          ),
                          // DELETE
                          DataCell(
                            isCompanyAdmin && !isSuperAdmin
                              ? Icon(Icons.lock, color: appColors.darkGray)
                              : IconButton(
                                  icon: Icon(Icons.delete, color: appColors.red),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: const Text('Are you sure you want to delete this user? This cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                          ),
                                          ElevatedButton(
                                            child: const Text('Delete'),
                                            style: ElevatedButton.styleFrom(backgroundColor: appColors.red),
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(widget.companyId)
                                          .collection('users')
                                          .doc(doc.id)
                                          .delete();
                                    }
                                  },
                                ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
