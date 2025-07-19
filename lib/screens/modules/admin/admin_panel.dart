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

  // --- NEW: Show Breaks Toggle ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Show Breaks',
                            style: TextStyle(
                                color: appColors.textColor,
                                fontWeight: FontWeight.w500)),
                        Switch(
                          value: userData['showBreaks'],
                          activeColor: appColors.primaryBlue,
                          inactiveThumbColor: appColors.lightGray,
                          onChanged: (v) =>
                              setState(() => userData['showBreaks'] = v),
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

                      if (!isEdit) ...[
                        _themedTextField(
                          ctx,
                          label: 'Password (manual entry)',
                          obscureText: true,
                          onChanged: (v) => password = v,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Password must be at least 6 characters.',
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
                                  // Only require password on create
                                  if (!isEdit) {
                                    if (password.length < 6) {
                                      setState(() {
                                        errorText = 'Password must be at least 6 characters!';
                                        isSubmitting = false;
                                      });
                                      return;
                                    }
                                  }

                                  // Check if email already exists in Firestore
                                  if (!isEdit) {
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
                                      // === Try to create Firestore doc with Auth UID ===
                                      try {
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
                          child: Text(isEdit ? 'Save Changes' : 'Create User',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appColors.whiteTextOnBlue,
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
                              label: Text("Send password reset email",
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
                                        content: Text("Password reset email sent to ${userData['email']}"),
                                        backgroundColor: appColors.primaryBlue,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to send reset email: $e"),
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



  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: appColors.backgroundDark,
      padding: const EdgeInsets.all(10), // Reduced from 16 to 10
      child: Card(
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10), // Reduced from 16 to 10
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black26,
                          width: 1,
                        ),
                        color: appColors.lightGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by name, email, or role',
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: TextStyle(color: appColors.textColor),
                        onChanged: (v) => setState(() => _searchText = v.trim()),
                      ),
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
              const SizedBox(height: 10), // Reduced from 16 to 10
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('companies')
                      .doc(widget.companyId)
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
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
                    return SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                                                  child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.transparent),//WidgetStateProperty Previously MaterialStateProperty
                            dataRowColor: WidgetStateProperty.all(Colors.transparent), //MaterialStateProperty
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
                                (data['roles'] as List<dynamic>?)?.join(', ') ?? '',
                                style: TextStyle(color: appColors.textColor),
                              )),
                              DataCell(Text(
                                (data['modules'] as List<dynamic>?)?.join(', ') ?? '',
                                style: TextStyle(color: appColors.textColor),
                              )),
                              DataCell(
                                Checkbox(
                                  value: data['active'] == true,
                                  onChanged: (checked) => _toggleActive(doc.id, checked ?? false),
                                  activeColor: appColors.primaryBlue,
                                  checkColor: Colors.white,
                                ),
                              ),
                              DataCell(
                                DropdownButton<String>(
                                  value: data['teamLeader'] ?? 'none',
                                  items: [
                                    const DropdownMenuItem(value: 'none', child: Text('None')),
                                    ..._teamLeaders.map((tl) => DropdownMenuItem(
                                          value: tl['id'],
                                          child: Text('${tl['firstName']} ${tl['surname']}'),
                                        )),
                                  ],
                                  onChanged: (val) => _updateTeamLeader(doc.id, val),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: TextEditingController(text: '${data['workPercent'] ?? 100}'),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (val) => _updateWorkPercent(doc.id, int.tryParse(val) ?? 100),
                                    style: TextStyle(color: appColors.textColor),
                                    decoration: InputDecoration(
                                      suffixText: '%',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: TextEditingController(text: data['weeklyHours']?.toString() ?? '40'),
                                    keyboardType: TextInputType.number,
                                    onSubmitted: (val) => _updateWeeklyHours(doc.id, int.tryParse(val) ?? 40),
                                    style: TextStyle(color: appColors.textColor),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: appColors.primaryBlue,
                                  onPressed: () => _showUserDialog(editUser: doc),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: appColors.red,
                                  onPressed: isCompanyAdmin ? null : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text('Are you sure you want to delete this user?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            child: const Text('Delete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: appColors.red,
                                              foregroundColor: appColors.whiteTextOnBlue,
                                            ),
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
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
        ),
      ),
    );
  }

  void _toggleActive(String userId, bool active) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'active': active});
  }

  void _updateTeamLeader(String userId, String? teamLeaderId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'teamLeader': teamLeaderId ?? 'none'});
  }

  void _updateWeeklyHours(String userId, int hours) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'weeklyHours': hours});
  }

  void _updateWorkPercent(String userId, int workPercent) async {
    // Ensure workPercent is between 0 and 100
    int clampedPercent = workPercent.clamp(0, 100);
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'workPercent': clampedPercent});
  }
}
