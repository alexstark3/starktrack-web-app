import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/overtime_calculation_service.dart';
import '../../../../widgets/app_search_field.dart';

class BalanceTab extends StatefulWidget {
  final String companyId;

  const BalanceTab({
    super.key,
    required this.companyId,
  });

  @override
  State<BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<BalanceTab> {
  String _searchQuery = '';
  String _selectedType = 'overtime';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _editingBonus =
      {}; // Track which users are editing bonus
  final Map<String, TextEditingController> _bonusControllers =
      {}; // Controllers for bonus editing

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all text controllers
    for (final controller in _bonusControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTypeButton(String value, String label, AppColors colors) {
    final bool selected = _selectedType == value;
    return SizedBox(
      width: 120,
      height: 38,
      child: Material(
        color: Colors.transparent,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected
                ? colors.primaryBlue
                : Theme.of(context).colorScheme.surface,
            foregroundColor: selected ? colors.whiteTextOnBlue : colors.textColor,
            elevation: selected ? 2 : 0, // Add elevation for selected state
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected
                    ? colors.primaryBlue
                    : Theme.of(context).brightness == Brightness.dark
                        ? colors.borderColorDark
                        : colors.borderColorLight,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          onPressed: () {
            setState(() {
              _selectedType = value;
              // Reset edit states
              _editingBonus.clear();
              for (final controller in _bonusControllers.values) {
                controller.dispose();
              }
              _bonusControllers.clear();
            });
          },
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar and radio buttons
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      hintText: l10n.searchMembers,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.start,
                alignment: WrapAlignment.start,
                children: [
                  _buildTypeButton('overtime', 'Overtime', colors),
                  _buildTypeButton('vacations', 'Vacations', colors),
                ],
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Workers list with time off balance
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 64,
                        color: colors.darkGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noMembersFound,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.darkGray,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allUsers = snapshot.data!.docs;
              final filteredUsers = allUsers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final firstName =
                    (data['firstName'] ?? '').toString().toLowerCase();
                final surname =
                    (data['surname'] ?? '').toString().toLowerCase();
                final fullName = '$firstName $surname'.toLowerCase();
                return fullName.contains(_searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMembersMatchSearch,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.darkGray,
                    ),
                  ),
                );
              }

              return ListView.builder(
                key: ValueKey('balance_list_${_selectedType}_$_searchQuery'),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final doc = filteredUsers[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final firstName = data['firstName'] ?? '';
                  final surname = data['surname'] ?? '';
                  final fullName = '$firstName $surname'.trim();

                  return Card(
                    key: ValueKey('balance_item_${doc.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colors.cardColorDark
                        : colors.backgroundLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colors.borderColorDark
                            : colors.borderColorLight,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Worker name and type
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colors.primaryBlue,
                                child: Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colors.whiteTextOnBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colors.textColor,
                                      ),
                                    ),
                                    Text(
                                      'Type: ${_selectedType == 'vacations' ? 'Vacations' : 'Overtime'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Balance data based on selected type
                          _selectedType == 'vacations'
                              ? _buildVacationsBalance(doc.id, colors)
                              : _buildOvertimeBalance(doc.id, colors),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceRow(
    String label,
    dynamic value,
    AppColors colors, {
    bool isTotal = false,
    bool isUsed = false,
    bool isAvailable = false,
  }) {
    Color textColor = colors.textColor;
    Color valueColor = colors.primaryBlue;
    FontWeight fontWeight = FontWeight.normal;

    if (isTotal) {
      fontWeight = FontWeight.bold;
      valueColor = colors.primaryBlue;
    } else if (isUsed) {
      valueColor = colors.error;
    } else if (isAvailable) {
      valueColor = colors.success;
    }

    String displayValue;
    if (_selectedType == 'vacations') {
      // Handle decimal values for vacations (e.g., 5.5 days)
      if (value is double) {
        displayValue = '${value.toStringAsFixed(1)} Days';
      } else {
        displayValue = '$value Days';
      }
    } else {
      // Convert minutes to HH:mm format for overtime
      final intValue = value is int ? value : value.toInt();
      final hours = intValue ~/ 60;
      final minutes = intValue % 60;
      displayValue =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: fontWeight,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRowWithButton(
    String label,
    dynamic value,
    AppColors colors,
    String userId,
  ) {
    final isEditing = _editingBonus[userId] ?? false;

    String displayValue;
    if (_selectedType == 'vacations') {
      // Handle decimal values for vacations
      if (value is double) {
        displayValue = '${value.toStringAsFixed(1)} Days';
      } else {
        displayValue = '$value Days';
      }
    } else {
      // Convert minutes to HH:mm format for overtime
      final intValue = value is int ? value : value.toInt();
      final hours = intValue ~/ 60;
      final minutes = intValue % 60;
      displayValue =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: colors.textColor,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _toggleBonusEditing(userId, value),
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: isEditing ? colors.success : colors.primaryBlue,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (isEditing)
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _bonusControllers[userId],
                    keyboardType: _selectedType == 'vacations'
                        ? TextInputType.number
                        : TextInputType.text,
                    style: TextStyle(
                      color: colors.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: colors.primaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            BorderSide(color: colors.primaryBlue, width: 2),
                      ),
                      hintText: _selectedType == 'vacations' ? '25' : '01:30',
                    ),
                  ),
                )
              else
                Text(
                  displayValue,
                  style: TextStyle(
                    color: colors.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleBonusEditing(String userId, dynamic currentValue) {
    final isEditing = _editingBonus[userId] ?? false;

    if (isEditing) {
      // Save the value
      dynamic newValue;
      if (_selectedType == 'vacations') {
        // Parse decimal values for vacations
        final text = _bonusControllers[userId]?.text ?? '';
        newValue = double.tryParse(text) ??
            (currentValue is double ? currentValue : currentValue.toDouble());
      } else {
        // Parse HH:mm format for overtime
        final timeText = _bonusControllers[userId]?.text ?? '';
        newValue = _parseTimeToMinutes(timeText);
      }
      _saveBonusValue(userId, newValue);
    } else {
      // Initialize controller with the correct value when starting to edit
      if (_selectedType == 'vacations') {
        // Handle decimal values for vacations
        if (currentValue is double) {
          _bonusControllers[userId] =
              TextEditingController(text: currentValue.toStringAsFixed(1));
        } else {
          _bonusControllers[userId] =
              TextEditingController(text: currentValue.toString());
        }
      } else {
        // Convert minutes to HH:mm format for overtime
        final intValue =
            currentValue is int ? currentValue : currentValue.toInt();
        final hours = intValue ~/ 60;
        final minutes = intValue % 60;
        _bonusControllers[userId] = TextEditingController(
            text:
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}');
      }
    }

    setState(() {
      _editingBonus[userId] = !isEditing;
    });
  }

  int _parseTimeToMinutes(String timeText) {
    // Parse HH:mm format to minutes
    final parts = timeText.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    // Fallback: try to parse as number (assuming hours)
    return int.tryParse(timeText) ?? 0;
  }

  void _saveBonusValue(String userId, dynamic newValue) {
    // Update Firestore
    final field = _selectedType == 'vacations' ? 'annualLeaveDays' : 'overtime';
    final subField = 'bonus';

    FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({
      '$field.$subField': newValue,
    }).then((_) {
      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bonus ${_selectedType == 'vacations' ? 'days' : 'hours'} updated successfully'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
          ),
        );
      }
    }).catchError((error) {
      // Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bonus value'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    });
  }

  Widget _buildVacationsBalance(String userId, AppColors colors) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Column(
            children: [
              _buildBalanceRow('Transferred', 0.0, colors),
              _buildBalanceRow('Current', 0.0, colors),
              _buildBalanceRowWithButton('Bonus', 0.0, colors, userId),
              _buildBalanceRow('Total', 0.0, colors, isTotal: true),
              const SizedBox(height: 8),
              _buildBalanceRow('Used', 0.0, colors, isUsed: true),
              _buildBalanceRow('Available', 0.0, colors, isAvailable: true),
            ],
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final annualLeaveDays =
            userData?['annualLeaveDays'] as Map<String, dynamic>? ?? {};

        // Convert to double for decimal support
        final transferred =
            _convertToDouble(annualLeaveDays['transferred'] ?? 0);
        final current = _convertToDouble(annualLeaveDays['current'] ?? 0);
        final bonus = _convertToDouble(annualLeaveDays['bonus'] ?? 0);
        final used = _convertToDouble(annualLeaveDays['used'] ?? 0);
        final total = transferred + current + bonus;
        final available = total - used;

        return Column(
          children: [
            _buildBalanceRow('Transferred', transferred, colors),
            _buildBalanceRow('Current', current, colors),
            _buildBalanceRowWithButton('Bonus', bonus, colors, userId),
            _buildBalanceRow('Total', total, colors, isTotal: true),
            const SizedBox(height: 8),
            _buildBalanceRow('Used', used, colors, isUsed: true),
            _buildBalanceRow('Available', available, colors, isAvailable: true),
          ],
        );
      },
    );
  }

  double _convertToDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildOvertimeBalance(String userId, AppColors colors) {
    return FutureBuilder<Map<String, dynamic>>(
      future: OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
        // Remove the date range to use user's start date (default behavior)
      ),
      builder: (context, overtimeSnapshot) {
        if (overtimeSnapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildBalanceRow('Transferred', 0, colors),
              _buildBalanceRow('Current', 0, colors),
              _buildBalanceRowWithButton('Bonus', 0, colors, userId),
              _buildBalanceRow('Total', 0, colors, isTotal: true),
              const SizedBox(height: 8),
              _buildBalanceRow('Used', 0, colors, isUsed: true),
              _buildBalanceRow('Available', 0, colors, isAvailable: true),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Calculating overtime from logs...',
                  style: TextStyle(
                    color: colors.midGray,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        }

        if (!overtimeSnapshot.hasData) {
          return Column(
            children: [
              _buildBalanceRow('Transferred', 0, colors),
              _buildBalanceRow('Current', 0, colors),
              _buildBalanceRowWithButton('Bonus', 0, colors, userId),
              _buildBalanceRow('Total', 0, colors, isTotal: true),
              const SizedBox(height: 8),
              _buildBalanceRow('Used', 0, colors, isUsed: true),
              _buildBalanceRow('Available', 0, colors, isAvailable: true),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'No overtime data available',
                  style: TextStyle(
                    color: colors.midGray,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        }

        final overtimeData = overtimeSnapshot.data!;

        final transferred = overtimeData['transferred'] ?? 0;
        final current = overtimeData['current'] ?? 0;
        final bonus = overtimeData['bonus'] ?? 0;
        final used = overtimeData['used'] ?? 0;

        final total = transferred + current + bonus;
        final available = total - used;

        return Column(
          children: [
            _buildBalanceRow('Transferred', transferred, colors),
            _buildBalanceRow('Current', current, colors),
            _buildBalanceRowWithButton('Bonus', bonus, colors, userId),
            _buildBalanceRow('Total', total, colors, isTotal: true),
            const SizedBox(height: 8),
            _buildBalanceRow('Used', used, colors, isUsed: true),
            _buildBalanceRow('Available', available, colors, isAvailable: true),
          ],
        );
      },
    );
  }
}