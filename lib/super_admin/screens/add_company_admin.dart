import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/modules/admin/add_user.dart';

class AddCompanyAdminDialog extends StatefulWidget {
  final String companyId;
  final Function() onAdminAdded;

  const AddCompanyAdminDialog({
    super.key,
    required this.companyId,
    required this.onAdminAdded,
  });

  @override
  State<AddCompanyAdminDialog> createState() => _AddCompanyAdminDialogState();
}

class _AddCompanyAdminDialogState extends State<AddCompanyAdminDialog> {
  @override
  Widget build(BuildContext context) {
    return AddUserDialog(
      companyId: widget.companyId,
      teamLeaders: [], // No team leaders for super admin context
      onUserAdded: () {
        // Update company user count
        FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .update({'userCount': 1});

        // Call callback to refresh parent
        widget.onAdminAdded();

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company admin created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      currentUserRoles: [
        'super_admin'
      ], // Super admin can create company admins
    );
  }
}
