import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/overtime_calculation_service.dart';

class OvertimeTab extends StatefulWidget {
  final String companyId;

  const OvertimeTab({
    super.key,
    required this.companyId,
  });

  @override
  State<OvertimeTab> createState() => _OvertimeTabState();
}

class _OvertimeTabState extends State<OvertimeTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _bonusControllers = {};
  final Map<String, bool> _editingBonus = {};

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _bonusControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar in a card
          Card(
            elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
            color: Theme.of(context).brightness == Brightness.dark
                ? colors.cardColorDark
                : colors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchMembers,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)
                        : colors.textColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7)
                        : colors.darkGray,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? colors.lightGray
                      : Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.26),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.26),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.primaryBlue, width: 2),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : colors.textColor,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Workers list with overtime balance
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
                  key: ValueKey('overtime_list_$_searchQuery'),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['firstName'] ?? '';
                    final surname = data['surname'] ?? '';
                    final fullName = '$firstName $surname'.trim();

                    return Card(
                      key: ValueKey('overtime_item_${doc.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: Theme.of(context).brightness == Brightness.dark
                          ? 0
                          : 2,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        'Type: Overtime',
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
                            // Overtime balance data
                            _buildOvertimeBalance(doc.id, colors),
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
      ),
    );
  }

  Widget _buildOvertimeBalance(String userId, AppColors colors) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('overtime_calculation_$userId'),
      future: _calculateAndUpdateOvertime(userId),
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
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Based on last 4 weeks of time logs',
                style: TextStyle(
                  color: colors.midGray,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceRow(
    String label,
    int value,
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

    // Convert minutes to HH:mm format
    final hours = value ~/ 60;
    final minutes = value % 60;
    final displayValue =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} h';

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
    int value,
    AppColors colors,
    String userId,
  ) {
    final isEditing = _editingBonus[userId] ?? false;

    // Convert minutes to HH:mm format
    final hours = value ~/ 60;
    final minutes = value % 60;
    final displayValue =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} h';

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
              if (isEditing)
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _bonusControllers[userId],
                    keyboardType: TextInputType.text,
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
                      hintText: '01:30',
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
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _toggleBonusEditing(userId, value),
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: isEditing ? colors.success : colors.primaryBlue,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleBonusEditing(String userId, int currentValue) {
    final isEditing = _editingBonus[userId] ?? false;

    if (isEditing) {
      // Save the value
      final timeText = _bonusControllers[userId]?.text ?? '';
      final newValue = _parseTimeToMinutes(timeText);
      _saveBonusValue(userId, newValue);
    } else {
      // Initialize controller with the current value
      final hours = currentValue ~/ 60;
      final minutes = currentValue % 60;
      _bonusControllers[userId] = TextEditingController(
          text:
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}');
    }

    setState(() {
      _editingBonus[userId] = !isEditing;
    });
  }

  int _parseTimeToMinutes(String timeText) {
    final parts = timeText.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }

  Future<void> _saveBonusValue(String userId, int newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(userId)
          .update({
        'overtime.bonus': newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bonus overtime updated successfully'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update bonus overtime'),
            backgroundColor: Theme.of(context).extension<AppColors>()!.error,
          ),
        );
      }
    }
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
      
      // Calculate new overtime values (from user start date, same as other modules)
      final newOvertimeData = await OvertimeCalculationService.calculateOvertimeFromLogs(
        widget.companyId,
        userId,
      );
      
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
}
