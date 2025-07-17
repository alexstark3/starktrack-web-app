import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';

class AddNewSessionDialog extends StatefulWidget {
  final String companyId;
  final String userId;
  final String userName;
  final VoidCallback onSessionAdded;

  const AddNewSessionDialog({
    Key? key,
    required this.companyId,
    required this.userId,
    required this.userName,
    required this.onSessionAdded,
  }) : super(key: key);

  @override
  State<AddNewSessionDialog> createState() => _AddNewSessionDialogState();
}

class _AddNewSessionDialogState extends State<AddNewSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectController = TextEditingController();
  final _noteController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _expenses = {};
  bool _isLoading = false;
  List<String> _availableProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _startTimeController.text = '09:00';
    _endTimeController.text = '17:00';
  }

  @override
  void dispose() {
    _projectController.dispose();
    _noteController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('projects')
          .get();
      
      setState(() {
        _availableProjects = snapshot.docs
            .map((doc) => doc.data()['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (time != null) {
      // Format as 24-hour time
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      controller.text = '$hour:$minute';
    }
  }

  Future<bool> _checkPerDiemExists(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .collection('all_logs')
          .where('sessionDate', isEqualTo: dateStr)
          .get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final expenses = data['expenses'] as Map<String, dynamic>? ?? {};
        if (expenses.containsKey('Per diem')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking per diem: $e');
      return false;
    }
  }

  void _addExpense() async {
    // Check if per diem already exists for this date
    final perDiemExists = await _checkPerDiemExists(_selectedDate);
    
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final amountController = TextEditingController();
        
        Map<String, dynamic> tempExpenses = Map<String, dynamic>.from(_expenses);
        bool tempPerDiem = tempExpenses.containsKey('Per Diem') || tempExpenses.containsKey('Per diem');
        final colors = Theme.of(context).extension<AppColors>()!;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool canAddExpense() {
              final name = nameController.text.trim();
              final amountStr = amountController.text.trim();
              final amount = double.tryParse(amountStr.replaceAll(',', '.'));
              return name.isNotEmpty &&
                  amountStr.isNotEmpty &&
                  amount != null &&
                  amount > 0 &&
                  !tempExpenses.containsKey(name) &&
                  name != 'Per Diem' &&
                  name != 'Per diem';
            }

            void addExpense() {
              final name = nameController.text.trim();
              final amountStr = amountController.text.trim();
              if (!canAddExpense()) return;
              setDialogState(() {
                tempExpenses[name] = double.parse(amountStr.replaceAll(',', '.'));
                nameController.clear();
                amountController.clear();
              });
            }

            void handlePerDiemChange(bool? checked) {
              setDialogState(() {
                tempPerDiem = checked ?? false;
                if (tempPerDiem) {
                  tempExpenses['Per Diem'] = 16.00;
                } else {
                  tempExpenses.remove('Per Diem');
                  tempExpenses.remove('Per diem');
                }
              });
            }

            void handleExpenseChange(String key, bool? checked) {
              if (checked == false) {
                setDialogState(() => tempExpenses.remove(key));
              }
            }

            // Expenses for display (Per diem last)
            final List<String> otherExpenseKeys =
                tempExpenses.keys.where((k) => k != 'Per Diem' && k != 'Per diem').toList();
            final List<Widget> expenseWidgets = [
              for (final key in otherExpenseKeys)
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (checked) => handleExpenseChange(key, checked),
                      activeColor: colors.primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Text(
                      key,
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      '${(tempExpenses[key] as num).toStringAsFixed(2)} CHF',
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 16),
                    ),
                  ],
                ),
              Row(
                children: [
                  Checkbox(
                    value: tempPerDiem,
                    onChanged: !perDiemExists ? handlePerDiemChange : null,
                    activeColor: colors.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Text(
                    'Per Diem',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                      color: !perDiemExists ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '16.00 CHF',
                    style: TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 16),
                  ),
                  if (perDiemExists)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Tooltip(
                        message: "Per Diem already used for this day",
                        child: Icon(Icons.lock, color: Colors.grey, size: 17),
                      ),
                    ),
                ],
              ),
            ];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Expenses'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...expenseWidgets,
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: amountController,
                            decoration: const InputDecoration(
                              hintText: 'Amount',
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => canAddExpense() ? addExpense() : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: colors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: canAddExpense() ? addExpense : null,
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: colors.primaryBlue, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      _expenses = Map<String, dynamic>.from(tempExpenses);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeExpense(String name) {
    setState(() {
      _expenses.remove(name);
    });
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse times
      final startTime = TimeOfDay.fromDateTime(DateFormat.Hm().parse(_startTimeController.text));
      final endTime = TimeOfDay.fromDateTime(DateFormat.Hm().parse(_endTimeController.text));
      
      // Create DateTime objects
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        startTime.hour,
        startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      // Calculate duration
      final duration = endDateTime.difference(startDateTime);
      final durationMinutes = duration.inMinutes;

      // Check if per diem is included and set the perDiem field
      final hasPerDiem = _expenses.containsKey('Per Diem') || _expenses.containsKey('perDiem');
      
      // Generate custom log ID (same pattern as time tracker)
      String _generateLogId(DateTime dt) {
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final h = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        final s = dt.second.toString().padLeft(2, '0');
        return '$y$m$d$h$min$s';
      }
      
      final logId = _generateLogId(startDateTime);
      
      // Create session data
      final sessionData = {
        'sessionDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'begin': Timestamp.fromDate(startDateTime),
        'end': Timestamp.fromDate(endDateTime),
        'duration_minutes': durationMinutes,
        'project': _projectController.text.trim(),
        'note': _noteController.text.trim(),
        'expenses': _expenses,
        'perDiem': hasPerDiem,
        'approved': false,
        'created_at': Timestamp.now(),
        'created_by_team_leader': true,
      };

      // Add to user's logs with custom ID
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .collection('all_logs')
          .doc(logId)
          .set(sessionData);

      widget.onSessionAdded();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session added successfully for ${widget.userName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Session for ${widget.userName}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              
              // Date selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                      onTap: _selectDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Time selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _selectTime(_startTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter start time';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _selectTime(_endTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter end time';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Project selection
              DropdownButtonFormField<String>(
                value: _projectController.text.isEmpty ? null : _projectController.text,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                items: _availableProjects.map((project) {
                  return DropdownMenuItem(
                    value: project,
                    child: Text(project),
                  );
                }).toList(),
                onChanged: (value) {
                  _projectController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Note field
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Expenses section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExpense,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Expenses list
              if (_expenses.isNotEmpty)
                Container(
                  height: 100,
                  child: ListView(
                    children: _expenses.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        subtitle: Text('${entry.value.toStringAsFixed(2)} CHF'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeExpense(entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSession,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Session'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
