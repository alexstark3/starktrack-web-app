import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';

class HolidayPolicyListDialog extends StatefulWidget {
  final String companyId;
  final Function() onPolicyAdded;

  const HolidayPolicyListDialog({
    Key? key,
    required this.companyId,
    required this.onPolicyAdded,
  }) : super(key: key);

  @override
  State<HolidayPolicyListDialog> createState() =>
      _HolidayPolicyListDialogState();
}

class _HolidayPolicyListDialogState extends State<HolidayPolicyListDialog> {
  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        width: 400,
        height: 300,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Holiday Policies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'Holiday policies list will be implemented here',
                  style: TextStyle(color: appColors.textColor),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: TextStyle(color: appColors.textColor)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCreateDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      Text('Create New', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => HolidayPolicyDialog(
        companyId: widget.companyId,
        onPolicyAdded: widget.onPolicyAdded,
      ),
    );
  }
}

class HolidayPolicyDialog extends StatefulWidget {
  final String companyId;
  final Function() onPolicyAdded;

  const HolidayPolicyDialog({
    Key? key,
    required this.companyId,
    required this.onPolicyAdded,
  }) : super(key: key);

  @override
  State<HolidayPolicyDialog> createState() => _HolidayPolicyDialogState();
}

class _HolidayPolicyDialogState extends State<HolidayPolicyDialog> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePolicy() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('holiday_policies')
          .add({
        'name': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      widget.onPolicyAdded();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Holiday Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Policy Name',
                filled: true,
                fillColor: appColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColors.darkGray, width: 1),
                ),
              ),
              style: TextStyle(color: appColors.textColor),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: TextStyle(color: appColors.textColor)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _savePolicy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
