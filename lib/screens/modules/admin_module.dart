import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  final String companyId;

  const AdminPanel({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Admin Panel for $companyId',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
