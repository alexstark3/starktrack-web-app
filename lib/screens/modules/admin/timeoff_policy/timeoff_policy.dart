import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/widgets/user_groups_search.dart';
import 'package:starktrack/l10n/app_localizations.dart';

class TimeOffPolicyListDialog extends StatefulWidget {
  final String companyId;
  final Function() onPolicyAdded;

  const TimeOffPolicyListDialog({
    super.key,
    required this.companyId,
    required this.onPolicyAdded,
  });

  @override
  State<TimeOffPolicyListDialog> createState() =>
      _TimeOffPolicyListDialogState();
}

class _TimeOffPolicyListDialogState extends State<TimeOffPolicyListDialog> {
  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          final dialogWidth =
              availableWidth > 600 ? 600.0 : availableWidth * 0.95;

          return Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: availableHeight * 0.90,
              minHeight: 400,
            ),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: appColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.timeOffPolicies,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(widget.companyId)
                        .collection('timeoff_policies')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: appColors.textColor),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final policies = snapshot.data?.docs ?? [];

                      if (policies.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noTimeOffPoliciesFound,
                            style: TextStyle(color: appColors.textColor),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: policies.length,
                        itemBuilder: (context, index) {
                          final policy =
                              policies[index].data() as Map<String, dynamic>;
                          final policyId = policies[index].id;
                          final name = policy['name'] as String? ?? '';
                          final color =
                              Color(policy['color'] as int? ?? 0xFF0000);
                          final isPaid = policy['isPaid'] as bool? ?? false;
                          final isRepeating =
                              policy['isRepeating'] as bool? ?? true;
                          final repeats =
                              policy['repeats'] as String? ?? 'Yearly';
                          final assignedTo = policy['assignTo'] == 'all'
                              ? 'Everyone'
                              : 'Selection';
                          final period =
                              policy['period'] as Map<String, dynamic>?;

                          String dateText = 'No date selected';
                          if (period != null) {
                            final start = period['start'] as Timestamp?;
                            final end = period['end'] as Timestamp?;
                            if (start != null && end != null) {
                              final startDate = start.toDate();
                              final endDate = end.toDate();
                              if (startDate.isAtSameMomentAs(endDate)) {
                                dateText =
                                    '${startDate.day}/${startDate.month}/${startDate.year}';
                              } else {
                                dateText =
                                    '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
                              }
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: appColors.cardColorDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white24
                                    : Colors.black26,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row with color indicator and policy details
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Color indicator
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.grey, width: 1),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Policy details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: appColors.textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: appColors.textColor
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                // Paid badge
                                                if (isPaid)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withValues(
                                                              alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      l10n.paid,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                // Repeats badge
                                                if (isRepeating) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withValues(
                                                              alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      '${l10n.repeats}: $repeats',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${l10n.assignedTo}: $assignedTo',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: appColors.textColor
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            // Show accruing info
                                            if (policy['isAccruing'] ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${l10n.accruing}: ${policy['accruingAmount'] ?? 1.0} ${policy['timeUnit'] ?? 'Days'} ${l10n.per} ${policy['accruingPeriod'] ?? 'Month'}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: appColors.textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                            // Show time unit
                                            const SizedBox(height: 4),
                                            Text(
                                              '${l10n.timeUnit}: ${policy['timeUnit'] ?? 'Days'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: appColors.textColor
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            // Show does not count info
                                            if (policy['doesNotCount'] ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Builder(
                                                builder: (context) {
                                                  List<String> notCountItems =
                                                      [];

                                                  // Add holidays toggle
                                                  if (policy[
                                                          'notCountHolidays'] ==
                                                      true) {
                                                    notCountItems
                                                        .add(l10n.holidays);
                                                  }

                                                  // Add selected time off policies
                                                  final notCountTimeOffPolicyIds =
                                                      List<String>.from(policy[
                                                              'notCountTimeOffPolicyIds'] ??
                                                          []);
                                                  if (notCountTimeOffPolicyIds
                                                      .isNotEmpty) {
                                                    notCountItems.add(
                                                        '${notCountTimeOffPolicyIds.length} ${l10n.timeOffPolicies}');
                                                  }

                                                  if (notCountItems
                                                      .isNotEmpty) {
                                                    return Text(
                                                      '${l10n.doesNotCount}: ${notCountItems.join(', ')}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: appColors
                                                            .textColor
                                                            .withValues(
                                                                alpha: 0.6),
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox
                                                      .shrink();
                                                },
                                              ),
                                            ],
                                            // Show include overtime
                                            if (policy['includeOvertime'] ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.includeOvertime,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: appColors.textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                            // Show negative balance
                                            if (policy[
                                                    'allowNegativeBalance'] ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${l10n.negativeBalance}: ${policy['negativeBalanceDays'] ?? 5.0} ${l10n.days}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: appColors.textColor
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Action buttons at bottom left
                                  Row(
                                    children: [
                                      const SizedBox(
                                          width:
                                              34), // Align with text (20px color indicator + 16px SizedBox - 2px adjustment)
                                      IconButton(
                                        onPressed: () =>
                                            _editPolicy(policyId, policy),
                                        icon: Icon(Icons.edit,
                                            color: appColors.primaryBlue),
                                        tooltip: l10n.edit,
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deletePolicy(policyId, name),
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: l10n.delete,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(color: appColors.textColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _createPolicy(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.createTimeOffPolicy,
                        style: TextStyle(color: appColors.whiteTextOnBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _createPolicy() {
    showDialog(
      context: context,
      builder: (context) => TimeOffPolicyDialog(
        companyId: widget.companyId,
        onPolicyAdded: widget.onPolicyAdded,
      ),
    );
  }

  void _editPolicy(String policyId, Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => TimeOffPolicyDialog(
        companyId: widget.companyId,
        policyId: policyId,
        existingPolicy: policy,
        onPolicyAdded: widget.onPolicyAdded,
      ),
    );
  }

  void _deletePolicy(String policyId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Policy'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('timeoff_policies')
                  .doc(policyId)
                  .delete();
              if (mounted) {
                navigator.pop();
                widget.onPolicyAdded();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class TimeOffPolicyDialog extends StatefulWidget {
  final String companyId;
  final String? policyId;
  final Map<String, dynamic>? existingPolicy;
  final Function() onPolicyAdded;

  const TimeOffPolicyDialog({
    super.key,
    required this.companyId,
    this.policyId,
    this.existingPolicy,
    required this.onPolicyAdded,
  });

  @override
  State<TimeOffPolicyDialog> createState() => _TimeOffPolicyDialogState();
}

class _TimeOffPolicyDialogState extends State<TimeOffPolicyDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.red;
  DateRange? _selectedDateRange;
  bool _isPaid = true;
  bool _isSubmitting = false;
  bool _isRepeating = true; // New toggle for repeating
  String _repeats = 'Yearly';
  bool _assignToEveryone = true;
  List<String> _selectedUsers = [];
  List<String> _selectedGroups = [];

  // Additional toggles for time off policy
  bool _isAccruing = true;
  String _timeUnit = 'Days'; // 'Days' or 'Hours'
  bool _doesNotCount = false;
  bool _includeOvertime = false;
  bool _allowNegativeBalance = false;

  // Accruing details
  String _accruingPeriod = 'Month'; // 'Month' or 'Year'
  double _accruingAmount = 1.0;

  // Does not count selections
  bool _notCountHolidays = false;
  List<String> _notCountTimeOffPolicyIds = [];

  // Data for selections
  List<Map<String, dynamic>> _availableTimeOffPolicies = [];
  bool _isLoadingTimeOffPolicies = false;

  // Negative balance amount
  double _negativeBalanceDays = 5.0;

  // Predefined colors with good contrast
  final List<Color> _predefinedColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingPolicy();
      _loadHolidaysAndPolicies();
    });
  }

  Future<void> _loadHolidaysAndPolicies() async {
    await _loadTimeOffPolicies();
  }

  Future<void> _loadTimeOffPolicies() async {
    setState(() {
      _isLoadingTimeOffPolicies = true;
    });

    try {
      final policiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_policies')
          .get();

      // Filter out the current policy and remove duplicates
      final policies = policiesSnapshot.docs
          .where((doc) => doc.id != widget.policyId) // Exclude current policy
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'type': 'timeoff_policy',
        };
      }).toList();

      // Remove duplicates based on name
      final uniquePolicies = <Map<String, dynamic>>[];
      final seenNames = <String>{};

      for (final policy in policies) {
        final name = policy['name'] as String;
        if (!seenNames.contains(name)) {
          seenNames.add(name);
          uniquePolicies.add(policy);
        }
      }

      setState(() {
        _availableTimeOffPolicies = uniquePolicies;
        _isLoadingTimeOffPolicies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTimeOffPolicies = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadExistingPolicy() {
    if (widget.existingPolicy != null) {
      final policy = widget.existingPolicy!;

      _nameController.text = policy['name'] ?? '';
      _selectedColor = Color(policy['color'] ?? 0xFF000000);

      final period = policy['period'] as Map<String, dynamic>?;
      if (period != null) {
        final startDate = period['start'] as Timestamp?;
        final endDate = period['end'] as Timestamp?;
        if (startDate != null && endDate != null) {
          _selectedDateRange = DateRange(
            startDate: startDate.toDate(),
            endDate: endDate.toDate(),
          );
        }
      }

      _isPaid = policy['isPaid'] ?? false;
      _isRepeating = policy['isRepeating'] ?? true;
      _repeats = policy['repeats'] ?? 'Yearly';
      _assignToEveryone = policy['assignTo'] == 'all';
      _selectedUsers = List<String>.from(policy['selectedUsers'] ?? []);
      _selectedGroups = List<String>.from(policy['selectedGroups'] ?? []);

      // Load additional toggles
      _isAccruing = policy['isAccruing'] ?? true;
      _timeUnit = policy['timeUnit'] ?? 'Days';
      _doesNotCount = policy['doesNotCount'] ?? false;
      _includeOvertime = policy['includeOvertime'] ?? false;
      _allowNegativeBalance = policy['allowNegativeBalance'] ?? false;

      // Load accruing details
      _accruingPeriod = policy['accruingPeriod'] ?? 'Month';
      _accruingAmount = (policy['accruingAmount'] ?? 1.0).toDouble();

      // Load does not count selections
      _notCountHolidays = policy['notCountHolidays'] ?? false;
      _notCountTimeOffPolicyIds =
          List<String>.from(policy['notCountTimeOffPolicyIds'] ?? []);

      // Load negative balance amount
      _negativeBalanceDays = (policy['negativeBalanceDays'] ?? 5.0).toDouble();

      setState(() {});
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CustomCalendar(
          initialDateRange: _selectedDateRange,
          onDateRangeChanged: (dateRange) {
            setState(() {
              _selectedDateRange = dateRange;
            });
          },
          minDate: DateTime.now().subtract(const Duration(days: 365)),
          maxDate: DateTime.now().add(const Duration(days: 365)),
        ),
      ),
    );
  }

  Future<void> _savePolicy() async {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a policy name')),
        );
      }
      return;
    }

    if (_selectedDateRange == null || !_selectedDateRange!.isComplete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date range')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final policyData = {
        'name': _nameController.text.trim(),
        'color': _selectedColor.toARGB32(),
        'isPaid': _isPaid,
        'isRepeating': _isRepeating,
        'repeats': _repeats,
        'assignTo': _assignToEveryone ? 'all' : 'selection',
        'selectedUsers': _assignToEveryone ? [] : _selectedUsers,
        'selectedGroups': _assignToEveryone ? [] : _selectedGroups,
        'isAccruing': _isAccruing,
        'timeUnit': _timeUnit,
        'doesNotCount': _doesNotCount,
        'includeOvertime': _includeOvertime,
        'allowNegativeBalance': _allowNegativeBalance,
        'accruingPeriod': _accruingPeriod,
        'accruingAmount': _accruingAmount,
        'notCountHolidays': _notCountHolidays,
        'notCountTimeOffPolicyIds': _notCountTimeOffPolicyIds,
        'negativeBalanceDays': _negativeBalanceDays,
        'period': {
          'start': Timestamp.fromDate(_selectedDateRange!.startDate!),
          'end': Timestamp.fromDate(_selectedDateRange!.endDate!),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.policyId != null) {
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('timeoff_policies')
            .doc(widget.policyId)
            .update(policyData);
      } else {
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('timeoff_policies')
            .add(policyData);
      }

      if (mounted) {
        widget.onPolicyAdded();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          final dialogWidth =
              availableWidth > 600 ? 600.0 : availableWidth * 0.95;

          return Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: availableHeight * 0.90,
              minHeight: 400,
            ),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: appColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.policyId != null
                        ? l10n.editTimeOffPolicy
                        : l10n.createTimeOffPolicy,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field with member-style border
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black26,
                        width: 1,
                      ),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? appColors.cardColorDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: l10n.enterPolicyName,
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFB3B3B3)
                              : appColors.textColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFCCCCCC)
                            : appColors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Color picker section
                  Text(
                    l10n.color,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Predefined colors
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _predefinedColors.map((color) {
                      final isSelected =
                          _selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Custom color picker
                  ElevatedButton.icon(
                    onPressed: _showColorPicker,
                    icon: Icon(Icons.color_lens, color: _selectedColor),
                    label: const Text('Custom Color'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.cardColorDark,
                      foregroundColor: appColors.textColor,
                      side: BorderSide(
                        color: appColors.lightGray,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Paid toggle
                  Row(
                    children: [
                      Text(
                        l10n.paid,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isPaid,
                        onChanged: (value) {
                          setState(() {
                            _isPaid = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Repeats toggle
                  Row(
                    children: [
                      Text(
                        l10n.repeats,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isRepeating,
                        onChanged: (value) {
                          setState(() {
                            _isRepeating = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Repeats options (only show if repeating is enabled)
                  if (_isRepeating) ...[
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Yearly',
                          groupValue: _repeats,
                          onChanged: (value) {
                            setState(() {
                              _repeats = value!;
                            });
                          },
                          activeColor: appColors.primaryBlue,
                        ),
                        Text(l10n.yearly),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: 'Monthly',
                          groupValue: _repeats,
                          onChanged: (value) {
                            setState(() {
                              _repeats = value!;
                            });
                          },
                          activeColor: appColors.primaryBlue,
                        ),
                        Text(l10n.monthly),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 20),

                  // Date picker
                  Text(
                    l10n.date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showDatePicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black26,
                          width: 1,
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? appColors.cardColorDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: appColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null &&
                                      _selectedDateRange!.hasSelection
                                  ? _selectedDateRange.toString()
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedDateRange != null &&
                                        _selectedDateRange!.hasSelection
                                    ? appColors.textColor
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFFB3B3B3)
                                        : appColors.textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Accruing toggle
                  Row(
                    children: [
                      Text(
                        'Accruing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isAccruing,
                        onChanged: (value) {
                          setState(() {
                            _isAccruing = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  if (_isAccruing) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue: _accruingAmount.toString(),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _accruingAmount = double.tryParse(value) ?? 1.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_timeUnit Per',
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            value: _accruingPeriod,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: ['Month', 'Year'].map((period) {
                              return DropdownMenuItem<String>(
                                value: period,
                                child: Text(period),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _accruingPeriod = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Time Unit radio buttons
                  Text(
                    'Time Unit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Days',
                        groupValue: _timeUnit,
                        onChanged: (value) {
                          setState(() {
                            _timeUnit = value!;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                      Text(l10n.days),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'Hours',
                        groupValue: _timeUnit,
                        onChanged: (value) {
                          setState(() {
                            _timeUnit = value!;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                      Text(l10n.hours),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Does not count toggle
                  Row(
                    children: [
                      Text(
                        'Does not count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _doesNotCount,
                        onChanged: (value) {
                          setState(() {
                            _doesNotCount = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  if (_doesNotCount) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: appColors.lightGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose all that apply:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: appColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Holidays section
                          CheckboxListTile(
                            title: const Text('All Holidays'),
                            value: _notCountHolidays,
                            onChanged: (value) {
                              setState(() {
                                _notCountHolidays = value!;
                              });
                            },
                            activeColor: appColors.primaryBlue,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const SizedBox(height: 8),

                          // Time Off Policies section
                          Text(
                            'Time Off Policies:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: appColors.textColor,
                            ),
                          ),
                          if (_isLoadingTimeOffPolicies)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_availableTimeOffPolicies.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'No time off policies available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textColor
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          else
                            ..._availableTimeOffPolicies
                                .map((policy) => CheckboxListTile(
                                      title: Text(policy['name'] ?? ''),
                                      value: _notCountTimeOffPolicyIds
                                          .contains(policy['id']),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _notCountTimeOffPolicyIds
                                                .add(policy['id']);
                                          } else {
                                            _notCountTimeOffPolicyIds
                                                .remove(policy['id']);
                                          }
                                        });
                                      },
                                      activeColor: appColors.primaryBlue,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Include Overtime toggle
                  Row(
                    children: [
                      Text(
                        'Include Overtime',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _includeOvertime,
                        onChanged: (value) {
                          setState(() {
                            _includeOvertime = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Negative Balance toggle
                  Row(
                    children: [
                      Text(
                        'Negative Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _allowNegativeBalance,
                        onChanged: (value) {
                          setState(() {
                            _allowNegativeBalance = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  if (_allowNegativeBalance) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _negativeBalanceDays.toString(),
                            decoration: InputDecoration(
                              labelText: 'Days',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _negativeBalanceDays =
                                    double.tryParse(value) ?? 5.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Assigned To section
                  Row(
                    children: [
                      Text(
                        'Assign to everyone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _assignToEveryone,
                        onChanged: (value) {
                          setState(() {
                            _assignToEveryone = value;
                          });
                        },
                        activeColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  if (!_assignToEveryone) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: appColors.lightGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: EmbeddedUserGroupSearch(
                        key: ValueKey(
                            'search_${_selectedUsers.join('_')}_${_selectedGroups.join('_')}'),
                        companyId: widget.companyId,
                        selectedUsers: _selectedUsers,
                        selectedGroups: _selectedGroups,
                        onSelectionChanged: (users, groups) {
                          setState(() {
                            _selectedUsers = users;
                            _selectedGroups = groups;
                          });
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24), // Add spacing before buttons

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: appColors.textColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _savePolicy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                widget.policyId != null ? 'Update' : 'Create',
                                style:
                                    TextStyle(color: appColors.whiteTextOnBlue),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
