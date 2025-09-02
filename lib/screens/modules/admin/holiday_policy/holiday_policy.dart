import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/l10n/app_localizations.dart';
import 'package:starktrack/widgets/calendar.dart';
import 'package:starktrack/services/holiday_translation_service.dart';

import 'package:starktrack/screens/modules/admin/user_address.dart';
import 'holiday_settings.dart';

class HolidayPolicyListDialog extends StatefulWidget {
  final String companyId;
  final Function() onPolicyAdded;

  const HolidayPolicyListDialog({
    super.key,
    required this.companyId,
    required this.onPolicyAdded,
  });

  @override
  State<HolidayPolicyListDialog> createState() =>
      _HolidayPolicyListDialogState();
}

class _HolidayPolicyListDialogState extends State<HolidayPolicyListDialog> {
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
              maxHeight: availableHeight * 0.90, // Max 90% of screen height
              minHeight: 400, // Minimum height for very small content
            ),
            padding: const EdgeInsets.all(10.0), // Reduced from 24px to 10px
            decoration: BoxDecoration(
              color: appColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.holidayPolicies,
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
                        .collection('holiday_policies')
                        .orderBy('period.start', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '${l10n.error}: ${snapshot.error}',
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
                            l10n.noHolidayPoliciesFound,
                            style: TextStyle(color: appColors.textColor),
                          ),
                        );
                      }

                      return ListView.builder(
                        key: ValueKey('holiday_policies_list'),
                        itemCount: policies.length,
                        itemBuilder: (context, index) {
                          final policy =
                              policies[index].data() as Map<String, dynamic>;
                          final policyId = policies[index].id;

                          return _buildPolicyCard(
                              policy, policyId, appColors, l10n);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Settings cog button
                    IconButton(
                      onPressed: () {
                        _showSwissHolidaysDialog();
                      },
                      icon: Icon(Icons.settings, color: appColors.primaryBlue),
                      tooltip: l10n.settings,
                    ),

                    // Action buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel,
                              style: TextStyle(color: appColors.textColor)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Removed Navigator.of(context).pop(); here
                            _showCreateDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(l10n.createNew,
                              style: TextStyle(
                                  color: Colors.white)), // Localized button
                        ),
                      ],
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

  Widget _buildPolicyCard(Map<String, dynamic> policy, String policyId,
      AppColors appColors, AppLocalizations l10n) {
    final name = policy['name'] ?? '';
    final color = Color(policy['color'] ?? 0xFF000000);
    final period = policy['period'] as Map<String, dynamic>?;
    final startDate = period?['start'] as Timestamp?;
    final endDate = period?['end'] as Timestamp?;
    final paid = policy['paid'] ?? false;
    final repeatAnnually = policy['repeatAnnually'] ?? false;
    final assignTo = policy['assignTo'] as String? ?? 'all';

    String dateText = '';
    if (startDate != null && endDate != null) {
      final start = startDate.toDate();
      final end = endDate.toDate();
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        dateText = '${start.day}/${start.month}/${start.year}';
      } else {
        dateText =
            '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: appColors.cardColorDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                ),
                const SizedBox(width: 16),

                // Policy details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HolidayTranslationService.getLocalizedHolidayName(
                          name, l10n),
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
                        color: appColors.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // National holiday indicator (FIRST)
                        if (name.contains('(National)') ||
                            policy['isNational'] == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'N',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        // Paid badge (SECOND)
                        if (paid) ...[
                          if (name.contains('(National)') ||
                              policy['isNational'] == true)
                            const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.paid,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                        // Repeats annually badge (THIRD)
                        if (repeatAnnually) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: appColors.primaryBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.repeatsAnnually,
                              style: TextStyle(
                                fontSize: 12,
                                color: appColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.assignedTo}: ${assignTo == 'all' ? l10n.everyone : l10n.selection}',
                      style: TextStyle(
                        fontSize: 12,
                        color: appColors.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
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
                  onPressed: () => _editPolicy(policyId, policy),
                  icon: Icon(Icons.edit, color: appColors.primaryBlue),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  onPressed: () => _deletePolicy(policyId, name),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPolicy(String policyId, Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => HolidayPolicyDialog(
        companyId: widget.companyId,
        onPolicyAdded: widget.onPolicyAdded,
        policyId: policyId,
        existingPolicy: policy,
      ),
    );
  }

  void _deletePolicy(String policyId, String policyName) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHolidayPolicy),
        content: Text('${l10n.deleteHolidayPolicyConfirm} "$policyName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('companies')
                    .doc(widget.companyId)
                    .collection('holiday_policies')
                    .doc(policyId)
                    .delete();

                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.holidayPolicyDeleted)),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.error}: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
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

  void _showSwissHolidaysDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            Theme.of(context).extension<AppColors>()!.backgroundLight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;

            final dialogWidth =
                availableWidth > 800 ? 800.0 : availableWidth * 0.95;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: availableHeight * 0.90, // Max 90% of screen height
                minHeight: 400, // Minimum height for very small content
              ),
              padding: const EdgeInsets.all(10.0), // Reduced from 24px to 10px
              decoration: BoxDecoration(
                color:
                    Theme.of(context).extension<AppColors>()!.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Holidays',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .extension<AppColors>()!
                              .primaryBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close),
                        color:
                            Theme.of(context).extension<AppColors>()!.textColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Expanded(
                    child: HolidaySettingsScreen(
                      companyId: widget.companyId,
                      onHolidaysAdded: () {
                        widget.onPolicyAdded();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HolidayPolicyDialog extends StatefulWidget {
  final String companyId;
  final Function() onPolicyAdded;
  final String? policyId; // For editing existing policy
  final Map<String, dynamic>? existingPolicy; // For editing existing policy

  const HolidayPolicyDialog({
    super.key,
    required this.companyId,
    required this.onPolicyAdded,
    this.policyId,
    this.existingPolicy,
  });

  @override
  State<HolidayPolicyDialog> createState() => _HolidayPolicyDialogState();
}

class _HolidayPolicyDialogState extends State<HolidayPolicyDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.red;
  DateRange? _selectedDateRange;
  bool _assignToEveryone = true; // Pre-selected
  bool _repeatsAnnually = false;
  bool _isPaid = true; // Pre-selected
  bool _isSubmitting = false;
  List<String> _selectedUsers = [];
  List<String> _selectedGroups = [];

  // Region filter data (without street and number)
  Map<String, dynamic> _regionFilter = {
    'country': 'Switzerland',
    'area': '',
    'city': '',
    'postCode': '',
  };

  // Predefined colors with good contrast
  final List<Color> _predefinedColors = [
    Colors.red,
    const Color(0xFF29ABE2),
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
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadExistingPolicy() {
    if (widget.existingPolicy != null) {
      final policy = widget.existingPolicy!;

      // Load existing data
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

      _assignToEveryone = policy['assignTo'] == 'all';
      _repeatsAnnually = policy['repeatAnnually'] ?? false;
      _isPaid = policy['paid'] ?? false;

      // Load region filter
      final region = policy['region'] as Map<String, dynamic>?;
      if (region != null) {
        _regionFilter = {
          'country': region['country'] ?? '',
          'area': region['area'].isNotEmpty
              ? (region['area'] as List).first.toString()
              : '',
          'city': region['city'] ?? '',
          'postCode': region['postCode'] ?? '',
        };
      }

      // Load selected users and groups
      _selectedUsers = List<String>.from(policy['selectedUsers'] ?? []);
      _selectedGroups = List<String>.from(policy['selectedGroups'] ?? []);

      // Force UI update with loaded data
      setState(() {});
    }
  }

  void _showColorPicker() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pickAColor),
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
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _onDateRangeChanged(DateRange dateRange) {
    setState(() {
      _selectedDateRange = dateRange;
    });
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CustomCalendar(
          initialDateRange: _selectedDateRange,
          onDateRangeChanged: _onDateRangeChanged,
          minDate: DateTime.now().subtract(const Duration(days: 365)),
          maxDate: DateTime.now().add(const Duration(days: 365)),
        ),
      ),
    );
  }

  void _onRegionChanged(Map<String, dynamic> newRegion) {
    setState(() {
      _regionFilter = newRegion;
    });
  }

  Widget _buildUserGroupSelection() {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: appColors.lightGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Users: ${_selectedUsers.length}',
            style: TextStyle(
              fontSize: 14,
              color: appColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected Groups: ${_selectedGroups.length}',
            style: TextStyle(
              fontSize: 14,
              color: appColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Direct search interface
          _buildDirectSearchInterface(),
        ],
      ),
    );
  }

  Future<void> _savePolicy() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseEnterPolicyName)),
        );
      }
      return;
    }

    if (_selectedDateRange == null || !_selectedDateRange!.isComplete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectDate)),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare the data according to Firestore structure
      final policyData = {
        'name': _nameController.text.trim(),
        'color': _selectedColor.toARGB32(),
        'assignTo':
            _assignToEveryone ? 'all' : 'selection', // 'all' or 'selection'
        'selectedUsers': _assignToEveryone ? [] : _selectedUsers,
        'selectedGroups': _assignToEveryone ? [] : _selectedGroups,
        'region': {
          'country': _regionFilter['country'],
          'area':
              _regionFilter['area'].isNotEmpty ? [_regionFilter['area']] : [],
          'city': _regionFilter['city'],
          'postCode': _regionFilter['postCode'],
        },
        'period': {
          'start': Timestamp.fromDate(_selectedDateRange!.startDate!),
          'end': Timestamp.fromDate(_selectedDateRange!.endDate!),
        },
        'repeatAnnually': _repeatsAnnually,
        'paid': _isPaid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.policyId != null) {
        // Update existing policy
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('holiday_policies')
            .doc(widget.policyId)
            .update(policyData);
      } else {
        // Create new policy
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('holiday_policies')
            .add(policyData);
      }

      if (!mounted) return;
      widget.onPolicyAdded();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
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
              maxHeight: availableHeight * 0.90, // Max 90% of screen height
              minHeight: 400, // Minimum height for very small content
            ),
            padding: const EdgeInsets.all(10.0), // Reduced from 24px to 10px
            decoration: BoxDecoration(
              color: appColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.policyId != null
                        ? l10n.editHolidayPolicy
                        : l10n.createHolidayPolicy,
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
                        hintText: l10n.policyName,
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
                    label: Text(l10n.customColor),
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

                  // Paid toggle after name
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
                        activeThumbColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
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
                                  : l10n.selectDate,
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

                  // Repeats annually toggle after date
                  Row(
                    children: [
                      Text(
                        l10n.repeatsAnnually,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: appColors.textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _repeatsAnnually,
                        onChanged: (value) {
                          setState(() {
                            _repeatsAnnually = value;
                          });
                        },
                        activeThumbColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Assign to everyone toggle
                  Row(
                    children: [
                      Text(
                        l10n.assignToEveryone,
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
                        activeThumbColor: appColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User/Group selection (only show if not assigning to everyone)
                  if (!_assignToEveryone) ...[
                    _buildUserGroupSelection(),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 20),

                  // Region filter (at the end)
                  Text(
                    l10n.region,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  UserAddress(
                    addressData: _regionFilter,
                    onAddressChanged: _onRegionChanged,
                    title: l10n.region,
                    isSwissAddress: true,
                    showCard: false,
                    showStreetAndNumber: false,
                  ),

                  const SizedBox(height: 24), // Add spacing before buttons

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel,
                            style: TextStyle(color: appColors.textColor)),
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
                            : Text(l10n.save,
                                style: TextStyle(color: Colors.white)),
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

  Widget _buildDirectSearchInterface() {
    return _DirectSearchInterface(
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
    );
  }
}

class _DirectSearchInterface extends StatefulWidget {
  final String companyId;
  final List<String> selectedUsers;
  final List<String> selectedGroups;
  final Function(List<String>, List<String>) onSelectionChanged;

  const _DirectSearchInterface({
    super.key,
    required this.companyId,
    required this.selectedUsers,
    required this.selectedGroups,
    required this.onSelectionChanged,
  });

  @override
  State<_DirectSearchInterface> createState() => _DirectSearchInterfaceState();
}

class _DirectSearchInterfaceState extends State<_DirectSearchInterface> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  bool _isLoading = true;

  // Local selection state
  List<String> _localSelectedUsers = [];
  List<String> _localSelectedGroups = [];

  @override
  void initState() {
    super.initState();
    _localSelectedUsers = List<String>.from(widget.selectedUsers);
    _localSelectedGroups = List<String>.from(widget.selectedGroups);
    _loadUsersAndGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DirectSearchInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state with parent state
    _localSelectedUsers = List<String>.from(widget.selectedUsers);
    _localSelectedGroups = List<String>.from(widget.selectedGroups);
  }

  Future<void> _loadUsersAndGroups() async {
    try {
      setState(() => _isLoading = true);

      // Load users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .get();

      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = data['firstName'] ?? '';
        final surname = data['surname'] ?? '';
        final fullName = '$firstName $surname'.trim();
        return {
          'id': doc.id,
          'name': fullName,
          'email': data['email'] ?? '',
        };
      }).toList();

      // Load groups
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('groups')
          .get();

      final groups = groupsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();

      setState(() {
        _users = users;
        _groups = groups;
        _filteredUsers = users;
        _filteredGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Error loading users and groups: $e
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
        _filteredGroups = _groups;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredUsers = _users.where((user) {
          return user['name'].toLowerCase().contains(lowercaseQuery) ||
              user['email'].toLowerCase().contains(lowercaseQuery);
        }).toList();
        _filteredGroups = _groups.where((group) {
          return group['name'].toLowerCase().contains(lowercaseQuery);
        }).toList();
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_localSelectedUsers.contains(userId)) {
        _localSelectedUsers.remove(userId);
      } else {
        _localSelectedUsers.add(userId);
      }
      // Sync with parent
      widget.onSelectionChanged(_localSelectedUsers, _localSelectedGroups);
    });
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_localSelectedGroups.contains(groupId)) {
        _localSelectedGroups.remove(groupId);
      } else {
        _localSelectedGroups.add(groupId);
      }
      // Sync with parent
      widget.onSelectionChanged(_localSelectedUsers, _localSelectedGroups);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: appColors.lightGray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchUsersAndGroups,
                prefixIcon: Icon(Icons.search, color: appColors.primaryBlue),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: _filterItems,
            ),
          ),

          // Results area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: appColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty && _filteredGroups.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noUsersOrGroupsFound,
                            style: TextStyle(color: appColors.textColor),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            if (_filteredUsers.isNotEmpty) ...[
                              Text(
                                l10n.users,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              ..._filteredUsers.map((user) => CheckboxListTile(
                                    title: Text(user['name']),
                                    subtitle: Text(user['email']),
                                    value: _localSelectedUsers
                                        .contains(user['id']),
                                    onChanged: (value) {
                                      _toggleUserSelection(user['id']);
                                    },
                                    checkColor: appColors.primaryBlue,
                                    dense: true,
                                  )),
                            ],
                            if (_filteredGroups.isNotEmpty) ...[
                              Text(
                                l10n.groups,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              ..._filteredGroups
                                  .map((group) => CheckboxListTile(
                                        title: Text(group['name']),
                                        value: _localSelectedGroups
                                            .contains(group['id']),
                                        onChanged: (value) {
                                          _toggleGroupSelection(group['id']);
                                        },
                                        checkColor: appColors.primaryBlue,
                                        dense: true,
                                      )),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
