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
  void initState() {
    super.initState();
    // Validate vacation balance when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateVacationBalance();
    });
  }

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
        // Search bar
        Column(
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
                          Text(
                            l10n.vacations,
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
                                    l10n.transferred, transferred, colors, l10n),
                                _buildBalanceRow(l10n.current, current, colors, l10n),
                                _buildBonusRow(bonus, widget.userId, colors, l10n),
                                _buildBalanceRow(l10n.total, total, colors, l10n,
                                    isTotal: true),
                                const SizedBox(height: 8),
                                _buildBalanceRow(l10n.used, used, colors, l10n,
                                    isUsed: true),
                                _buildBalanceRow(l10n.available, available, colors, l10n,
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
                          Text(
                            l10n.overtime,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildOvertimeBalance(widget.userId, colors, l10n),
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
    AppColors colors,
    AppLocalizations l10n, {
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
      displayValue = '${value.toStringAsFixed(1)} ${l10n.days}';
    } else {
      displayValue = '$value ${l10n.days}';
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
    AppLocalizations l10n,
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
          Text('${l10n.bonus}:'),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (isEditing) {
                    final newValue = double.tryParse(controller.text) ?? value;
                    _saveBonusValue(userId, newValue, l10n);
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
                  '${value.toStringAsFixed(1)} ${l10n.days}',
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

  Widget _buildOvertimeBalance(String userId, AppColors colors, AppLocalizations l10n) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateAndUpdateOvertime(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildOvertimeRow(l10n.transferred, 0, colors, l10n),
              _buildOvertimeRow(l10n.current, 0, colors, l10n),
              _buildOvertimeBonusRow(0, userId, colors, l10n),
              _buildOvertimeRow(l10n.total, 0, colors, l10n, isTotal: true),
              const SizedBox(height: 8),
              _buildOvertimeRow(l10n.used, 0, colors, l10n, isUsed: true),
              _buildOvertimeRow(l10n.available, 0, colors, l10n, isAvailable: true),
            ],
          );
        }

        if (!snapshot.hasData) {
          return Column(
            children: [
              _buildOvertimeRow(l10n.transferred, 0, colors, l10n),
              _buildOvertimeRow(l10n.current, 0, colors, l10n),
              _buildOvertimeBonusRow(0, userId, colors, l10n),
              _buildOvertimeRow(l10n.total, 0, colors, l10n, isTotal: true),
              const SizedBox(height: 8),
              _buildOvertimeRow(l10n.used, 0, colors, l10n, isUsed: true),
              _buildOvertimeRow(l10n.available, 0, colors, l10n, isAvailable: true),
            ],
          );
        }

        final data = snapshot.data!;

        // Use overtime values directly (they're already in minutes from the service)
        final transferred = (data['transferred'] ?? 0) as int;
        final current = (data['current'] ?? 0) as int;
        final bonus = (data['bonus'] ?? 0) as int;
        final used = (data['used'] ?? 0) as int;
        final total = transferred + current + bonus;
        final available = total - used;

        return Column(
          children: [
            _buildOvertimeRow(l10n.transferred, transferred, colors, l10n),
            _buildOvertimeRow(l10n.current, current, colors, l10n),
            _buildOvertimeBonusRow(bonus, userId, colors, l10n),
            _buildOvertimeRow(l10n.total, total, colors, l10n, isTotal: true),
            const SizedBox(height: 8),
            _buildOvertimeRow(l10n.used, used, colors, l10n, isUsed: true),
            _buildOvertimeRow(l10n.available, available, colors, l10n,
                isAvailable: true),
          ],
        );
      },
    );
  }

  Widget _buildOvertimeRow(
    String label,
    int value,
    AppColors colors,
    AppLocalizations l10n, {
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

  Widget _buildOvertimeBonusRow(int value, String userId, AppColors colors, AppLocalizations l10n) {
    final isEditing = _editingBonus[userId] ?? false;
    final controller = _bonusControllers[userId] ??
        TextEditingController(text: _formatMinutes(value));
    _bonusControllers[userId] = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${l10n.bonus}:'),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (isEditing) {
                    final minutes = _parseTimeToMinutes(controller.text);
                    _saveOvertimeBonusValue(userId, minutes, l10n);
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
    final s = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} h';
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

  void _saveOvertimeBonusValue(String userId, int minutes, AppLocalizations l10n) {
    FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(userId)
        .update({'overtime.bonus': minutes}).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.bonus} ${l10n.hours} ${l10n.updatedSuccessfully}'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.success,
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToUpdateBonus),
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



  void _saveBonusValue(String userId, double newValue, AppLocalizations l10n) {
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
          content: Text('${l10n.bonus} ${l10n.days} ${l10n.updatedSuccessfully}'),
          backgroundColor: Theme.of(context).extension<AppColors>()!.success,
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToUpdateBonus),
          backgroundColor: Theme.of(context).extension<AppColors>()!.error,
        ),
      );
    });
  }

  /// Calculate overtime and update database if values have changed
  Future<Map<String, dynamic>> _calculateAndUpdateOvertime(String userId) async {
    try {
      // First, get current overtime data from database
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data();
      final currentOvertimeData = userData?['overtime'] ?? {};
      
      // Calculate new overtime values (from user start date)
      final newOvertimeData = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
      );
      
      // DEBUG: Calculate overtime for different periods to find the real values
      // await _debugOvertimeCalculations(userId); // Temporarily disabled due to linter error
      
      // Check if any values have changed (excluding bonus which is manually set)
      final hasChanged = 
          (currentOvertimeData['transferred'] ?? 0) != (newOvertimeData['transferred'] ?? 0) ||
          (currentOvertimeData['current'] ?? 0) != (newOvertimeData['current'] ?? 0) ||
          (currentOvertimeData['used'] ?? 0) != (newOvertimeData['used'] ?? 0);
      
      // Only update database if values have changed
      if (hasChanged) {
        await OvertimeCalculationService.updateOvertimeData(
          widget.companyId,
          userId,
          {
            'transferred': newOvertimeData['transferred'] ?? 0,
            'current': newOvertimeData['current'] ?? 0,
            'bonus': currentOvertimeData['bonus'] ?? 0, // Preserve manual bonus
            'used': newOvertimeData['used'] ?? 0,
          },
        );
      }
      
      return newOvertimeData;
    } catch (e) {
      // If calculation fails, return empty data (will show error state)
      return {
        'transferred': 0,
        'current': 0,
        'bonus': 0,
        'used': 0,
      };
    }
  }

  /// Validate and recalculate vacation balance based on actual time off requests
  Future<void> _validateVacationBalance() async {
    try {
      // Get current vacation balance from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data();
      final currentVacationData = userData?['annualLeaveDays'] ?? {};
      final currentUsed = _convertToDouble(currentVacationData['used'] ?? 0);
      
      // Get all approved time off requests for this user
      final timeOffSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_requests')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'approved')
          .get();
      
      // Calculate actual used days from requests
      double actualUsed = 0.0;
      for (final doc in timeOffSnapshot.docs) {
        final data = doc.data();
        final totalWorkingDays = data['totalWorkingDays'] ?? 0;
        actualUsed += _convertToDouble(totalWorkingDays);
      }
      
      // Check if there's a discrepancy
      if ((currentUsed - actualUsed).abs() > 0.01) { // Allow small floating point differences
        // Update the vacation balance with correct used days
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('users')
            .doc(widget.userId)
            .update({
          'annualLeaveDays.used': actualUsed,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vacation balance updated: ${actualUsed.toStringAsFixed(1)} days used'),
              backgroundColor: Theme.of(context).extension<AppColors>()!.success,
            ),
          );
        }
      }
    } catch (e) {
      // Silently handle validation errors
    }
  }
}
