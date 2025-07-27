import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'user_address.dart';
import 'holiday_settings.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
                    .orderBy('createdAt', descending: true)
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
                        l10n.noHolidayPoliciesFound,
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
                  tooltip: 'Settings',
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
                        color: appColors.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (paid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
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
                        if (repeatAnnually) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.repeatsAnnually,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
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

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.holidayPolicyDeleted)),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            // Calculate available height (80% of screen height, max 800px)
            final availableHeight = MediaQuery.of(context).size.height * 0.8;
            final maxHeight = 800.0;
            final dialogHeight =
                availableHeight > maxHeight ? maxHeight : availableHeight;

            return Container(
              width: 800,
              height: dialogHeight,
              padding: const EdgeInsets.all(24.0),
              child: Column(
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
    Key? key,
    required this.companyId,
    required this.onPolicyAdded,
    this.policyId,
    this.existingPolicy,
  }) : super(key: key);

  @override
  State<HolidayPolicyDialog> createState() => _HolidayPolicyDialogState();
}

class _HolidayPolicyDialogState extends State<HolidayPolicyDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.red;
  DateTime? _selectedDate;
  bool _assignToEveryone = true; // Pre-selected
  bool _repeatsAnnually = false;
  bool _isPaid = true; // Pre-selected
  bool _isSubmitting = false;
  List<String> _selectedUsers = [];
  List<String> _selectedGroups = [];

  // Region filter data (without street and number)
  Map<String, dynamic> _regionFilter = {
    'country': '',
    'area': '',
    'city': '',
    'postCode': '',
  };

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
        if (startDate != null) {
          _selectedDate = startDate.toDate();
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onRegionChanged(Map<String, dynamic> newRegion) {
    setState(() {
      _regionFilter = newRegion;
    });
  }

  Widget _buildUserGroupSelection() {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Combined search field for users and groups
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black26,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchUsersAndGroups,
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFB3B3B3)
                    : appColors.textColor,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon:
                  Icon(Icons.search, color: appColors.primaryBlue, size: 20),
            ),
            style: TextStyle(color: appColors.textColor),
          ),
        ),
        const SizedBox(height: 8),

        // Combined list of selected users and groups
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black26,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (_selectedUsers.isEmpty && _selectedGroups.isEmpty)
              ? Center(
                  child: Text(
                    l10n.noUsersOrGroupsFound,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFB3B3B3)
                          : appColors.textColor,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _selectedUsers.length + _selectedGroups.length,
                  itemBuilder: (context, index) {
                    if (index < _selectedUsers.length) {
                      // User item
                      return CheckboxListTile(
                        title: Text(
                          _selectedUsers[index],
                          style: TextStyle(color: appColors.textColor),
                        ),
                        subtitle: Text(
                          l10n.user,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textColor.withOpacity(0.7),
                          ),
                        ),
                        value: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedUsers.removeAt(index);
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      );
                    } else {
                      // Group item
                      final groupIndex = index - _selectedUsers.length;
                      return CheckboxListTile(
                        title: Text(
                          _selectedGroups[groupIndex],
                          style: TextStyle(color: appColors.textColor),
                        ),
                        subtitle: Text(
                          l10n.group,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textColor.withOpacity(0.7),
                          ),
                        ),
                        value: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedGroups.removeAt(groupIndex);
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _savePolicy() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPolicyName)),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectDate)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare the data according to Firestore structure
      final policyData = {
        'name': _nameController.text.trim(),
        'color': _selectedColor.value,
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
          'start': Timestamp.fromDate(_selectedDate!),
          'end': Timestamp.fromDate(_selectedDate!),
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
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height (80% of screen height, max 700px)
          final availableHeight = MediaQuery.of(context).size.height * 0.8;
          final maxHeight = 700.0;
          final dialogHeight =
              availableHeight > maxHeight ? maxHeight : availableHeight;

          return Container(
            width: 500,
            height: dialogHeight,
            padding: const EdgeInsets.all(24.0),
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
                      final isSelected = _selectedColor.value == color.value;
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
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? appColors.cardColorDark
                              : Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black26,
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
                        activeColor: appColors.primaryBlue,
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
                    onTap: _selectDate,
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
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : l10n.selectDate,
                            style: TextStyle(
                              color: _selectedDate != null
                                  ? appColors.textColor
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFB3B3B3)
                                      : appColors.textColor),
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
                        activeColor: appColors.primaryBlue,
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
                        activeColor: appColors.primaryBlue,
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
                    key: ValueKey('region_${_regionFilter.hashCode}'),
                    addressData: _regionFilter,
                    onAddressChanged: _onRegionChanged,
                    title: l10n.region,
                    isSwissAddress: true,
                    showCard: false,
                    showStreetAndNumber: false,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel,
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
}
