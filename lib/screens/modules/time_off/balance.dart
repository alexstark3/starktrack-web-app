import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../services/overtime_calculation_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_search_field.dart';

class TimeOffBalance extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeOffBalance({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<TimeOffBalance> createState() => _TimeOffBalanceState();
}

class _TimeOffBalanceState extends State<TimeOffBalance> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _editingBonus = {};
  final Map<String, TextEditingController> _bonusControllers = {};

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _bonusControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar in a card (same style as Team Balance)
        Card(
          elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
          color: Theme.of(context).brightness == Brightness.dark
              ? colors.cardColorDark
              : colors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        controller: _searchController,
                        hintText: l10n.search,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Single user personal card
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(widget.companyId)
                .collection('users')
                .doc(widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    l10n.noMembersFound,
                    style: TextStyle(color: colors.darkGray, fontSize: 16),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final firstName = (data['firstName'] ?? '').toString();
              final surname = (data['surname'] ?? '').toString();
              final fullName = '$firstName $surname'.trim();

              if (_searchQuery.isNotEmpty &&
                  !fullName.toLowerCase().contains(_searchQuery)) {
                return Center(
                  child: Text(
                    l10n.noMembersMatchSearch,
                    style: TextStyle(color: colors.darkGray, fontSize: 16),
                  ),
                );
              }

              return ListView(
                children: [
                  // Vacations card
                  Card(
                    key: ValueKey('timeoff_vacations_${widget.userId}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation:
                        Theme.of(context).brightness == Brightness.dark ? 0 : 2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colors.cardColorDark
                        : colors.backgroundLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vacations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Builder(builder: (context) {
                            final annualLeaveDays = data['annualLeaveDays']
                                    as Map<String, dynamic>? ??
                                {};
                            final transferred = _convertToDouble(
                                annualLeaveDays['transferred'] ?? 0);
                            final current = _convertToDouble(
                                annualLeaveDays['current'] ?? 0);
                            final bonus =
                                _convertToDouble(annualLeaveDays['bonus'] ?? 0);
                            final used =
                                _convertToDouble(annualLeaveDays['used'] ?? 0);
                            final total = transferred + current + bonus;
                            final available = total - used;
                            return Column(
                              children: [
                                _buildBalanceRow(
                                    'Transferred', transferred, colors),
                                _buildBalanceRow('Current', current, colors),
                                _buildBonusRow(bonus, widget.userId, colors),
                                _buildBalanceRow('Total', total, colors,
                                    isTotal: true),
                                const SizedBox(height: 8),
                                _buildBalanceRow('Used', used, colors,
                                    isUsed: true),
                                _buildBalanceRow('Available', available, colors,
                                    isAvailable: true),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Overtime card
                  Card(
                    key: ValueKey('timeoff_overtime_${widget.userId}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation:
                        Theme.of(context).brightness == Brightness.dark ? 0 : 2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colors.cardColorDark
                        : colors.backgroundLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overtime',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildOvertimeBalance(widget.userId, colors),
                        ],
                      ),
                    ),
                  ),
                ],
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
    if (value is double) {
      displayValue = '${value.toStringAsFixed(1)} Days';
    } else {
      displayValue = '$value Days';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:'),
          Text(
            displayValue,
            style: TextStyle(color: valueColor, fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusRow(
    double value,
    String userId,
    AppColors colors,
  ) {
    final isEditing = _editingBonus[userId] ?? false;
    final controller = _bonusControllers[userId] ??
        TextEditingController(text: value.toStringAsFixed(1));
    _bonusControllers[userId] = controller;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Bonus:'),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (isEditing) {
                    final newValue = double.tryParse(controller.text) ?? value;
                    _saveBonusValue(userId, newValue);
                  }
                  setState(() => _editingBonus[userId] = !isEditing);
                },
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
                    controller: controller,
                    keyboardType: TextInputType.number,
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
                      hintText: '25',
                    ),
                  ),
                )
              else
                Text(
                  '${value.toStringAsFixed(1)} Days',
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

  Widget _buildOvertimeBalance(String userId, AppColors colors) {
    return FutureBuilder<Map<String, dynamic>>(
      future: OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildOvertimeRow('Transferred', 0, colors),
              _buildOvertimeRow('Current', 0, colors),
              _buildOvertimeBonusRow(0, userId, colors),
              _buildOvertimeRow('Total', 0, colors, isTotal: true),
              const SizedBox(height: 8),
              _buildOvertimeRow('Used', 0, colors, isUsed: true),
              _buildOvertimeRow('Available', 0, colors, isAvailable: true),
            ],
          );
        }

        if (!snapshot.hasData) {
          return Column(
            children: [
              _buildOvertimeRow('Transferred', 0, colors),
              _buildOvertimeRow('Current', 0, colors),
              _buildOvertimeBonusRow(0, userId, colors),
              _buildOvertimeRow('Total', 0, colors, isTotal: true),
              const SizedBox(height: 8),
              _buildOvertimeRow('Used', 0, colors, isUsed: true),
              _buildOvertimeRow('Available', 0, colors, isAvailable: true),
            ],
          );
        }

        final data = snapshot.data!;

        final transferred = data['transferred'] ?? 0;
        final current = data['current'] ?? 0;
        final bonus = data['bonus'] ?? 0;
        final used = data['used'] ?? 0;
        final total = transferred + current + bonus;
        final available = total - used;

        return Column(
          children: [
            _buildOvertimeRow('Transferred', transferred, colors),
            _buildOvertimeRow('Current', current, colors),
            _buildOvertimeBonusRow(bonus, userId, colors),
            _buildOvertimeRow('Total', total, colors, isTotal: true),
            const SizedBox(height: 8),
            _buildOvertimeRow('Used', used, colors, isUsed: true),
            _buildOvertimeRow('Available', available, colors,
                isAvailable: true),
          ],
        );
      },
    );
  }

  Widget _buildOvertimeRow(
    String label,
    int value,
    AppColors colors, {
    bool isTotal = false,
    bool isUsed = false,
    bool isAvailable = false,
  }) {
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
    final display = _formatMinutes(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:'),
          Text(display,
              style: TextStyle(color: valueColor, fontWeight: fontWeight)),
        ],
      ),
    );
  }

  Widget _buildOvertimeBonusRow(int value, String userId, AppColors colors) {
    final isEditing = _editingBonus[userId] ?? false;
    final controller = _bonusControllers[userId] ??
        TextEditingController(text: _formatMinutes(value));
    _bonusControllers[userId] = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Bonus:'),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (isEditing) {
                    final minutes = _parseTimeToMinutes(controller.text);
                    _saveOvertimeBonusValue(userId, minutes);
                  }
                  setState(() => _editingBonus[userId] = !isEditing);
                },
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
                    controller: controller,
                    keyboardType: TextInputType.text,
                    style: TextStyle(color: colors.primaryBlue, fontSize: 14),
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
                      hintText: '01:30',
                    ),
                  ),
                )
              else
                Text(
                  _formatMinutes(value),
                  style: TextStyle(color: colors.primaryBlue, fontSize: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final isNegative = minutes < 0;
    final abs = minutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    final s = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return isNegative ? '-$s' : s;
  }

  int _parseTimeToMinutes(String timeText) {
    final parts = timeText.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return h * 60 + m;
    }
    return int.tryParse(timeText) ?? 0;
  }

  void _saveOvertimeBonusValue(String userId, int minutes) {
    FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'overtime.bonus': minutes}).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bonus hours updated successfully'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.success,
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update bonus value'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    });
  }

  double _convertToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _saveBonusValue(String userId, double newValue) {
    FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({
      'annualLeaveDays.bonus': newValue,
    }).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bonus days updated successfully'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.success,
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update bonus value'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    });
  }
}
