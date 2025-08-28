import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../utils/calendar_storage.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  const DateRange({
    this.startDate, 
    this.endDate, 
    this.startTime, 
    this.endTime,
  });

  bool get isSingleDate =>
      startDate != null &&
      endDate != null &&
      startDate!.isAtSameMomentAs(endDate!);
  bool get hasSelection => startDate != null || endDate != null;
  bool get isComplete => startDate != null && endDate != null;
  bool get hasTime => startTime != null || endTime != null;
  
  // Calculate total working days (excluding weekends) including half-days
  double get totalDays {
    if (startDate == null || endDate == null) return 0.0;
    
    // Count only working days (Monday-Friday) - this is the default behavior
    // For more accurate calculation, use calculateWorkingDays() method with user's working days config
    int workingDaysCount = 0;
    for (DateTime date = startDate!; !date.isAfter(endDate!); date = date.add(const Duration(days: 1))) {
      // Monday = 1, Tuesday = 2, ..., Friday = 5
      if (date.weekday >= 1 && date.weekday <= 5) {
        workingDaysCount++;
      }
    }
    
    double total = workingDaysCount.toDouble();
    
    // Adjust for half-days
    if (startTime != null && endTime != null) {
      // If start time is 13:00 (second half), reduce by 0.5
      if (startTime!.hour == 13) total -= 0.5;
      // If end time is 12:00 (first half), reduce by 0.5
      if (endTime!.hour == 12) total -= 0.5;
    }
    
    return total;
  }

  /// Calculate working days based on user's working days configuration
  double calculateWorkingDays(List<String> userWorkingDays) {
    if (startDate == null || endDate == null) return 0.0;
    
    // Convert user's working days to weekday numbers
    final workingDaysList = userWorkingDays.map((dayName) {
      switch (dayName.toString()) {
        case 'Monday': return 1;
        case 'Tuesday': return 2;
        case 'Wednesday': return 3;
        case 'Thursday': return 4;
        case 'Friday': return 5;
        case 'Saturday': return 6;
        case 'Sunday': return 7;
        default: return 0;
      }
    }).where((d) => d > 0).toList();
    
    // Count only user's configured working days
    int workingDaysCount = 0;
    for (DateTime date = startDate!; !date.isAfter(endDate!); date = date.add(const Duration(days: 1))) {
      if (workingDaysList.contains(date.weekday)) {
        workingDaysCount++;
      }
    }
    
    double total = workingDaysCount.toDouble();
    
    // Adjust for half-days
    if (startTime != null && endTime != null) {
      // If start time is 13:00 (second half), reduce by 0.5
      if (startTime!.hour == 13) total -= 0.5;
      // If end time is 12:00 (first half), reduce by 0.5
      if (endTime!.hour == 12) total -= 0.5;
    }
    
    return total;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    return ' ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    if (startDate == null && endDate == null) {
      return 'No dates selected';
    }
    if (startDate == null) {
      return 'End: ${DateFormat('MMM dd, yyyy').format(endDate!)}${_formatTime(endTime)}';
    }
    if (endDate == null) {
      return 'Start: ${DateFormat('MMM dd, yyyy').format(startDate!)}${_formatTime(startTime)}';
    }
    if (isSingleDate) {
      return '${DateFormat('MMM dd, yyyy').format(startDate!)}${_formatTime(startTime)}';
    }
    
    return '${DateFormat('MMM dd, yyyy').format(startDate!)}${_formatTime(startTime)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}${_formatTime(endTime)}';
  }
}

class CalendarSettingsDialog extends StatefulWidget {
  final int startWeekday;
  final bool showWeekNumbers;
  final bool showTime;
  final Function(int, bool, bool) onSettingsChanged;

  const CalendarSettingsDialog({
    super.key,
    required this.startWeekday,
    required this.showWeekNumbers,
    required this.showTime,
    required this.onSettingsChanged,
  });

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late int _startWeekday;
  late bool _showWeekNumbers;
  late bool _showTime;

  @override
  void initState() {
    super.initState();
    _startWeekday = widget.startWeekday;
    _showWeekNumbers = widget.showWeekNumbers;
    _showTime = widget.showTime; // Use the widget's showTime value
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: appColors.backgroundLight,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Starting day of week
            Text(
              AppLocalizations.of(context)!.startingDayOfWeek,
              style: theme.textTheme.titleMedium?.copyWith(
                color: appColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _startWeekday,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColors.lightGray),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                    value: 1,
                    child: Text(AppLocalizations.of(context)!.monday)),
                DropdownMenuItem(
                    value: 2,
                    child: Text(AppLocalizations.of(context)!.tuesday)),
                DropdownMenuItem(
                    value: 3,
                    child: Text(AppLocalizations.of(context)!.wednesday)),
                DropdownMenuItem(
                    value: 4,
                    child: Text(AppLocalizations.of(context)!.thursday)),
                DropdownMenuItem(
                    value: 5,
                    child: Text(AppLocalizations.of(context)!.friday)),
                DropdownMenuItem(
                    value: 6,
                    child: Text(AppLocalizations.of(context)!.saturday)),
                DropdownMenuItem(
                    value: 7,
                    child: Text(AppLocalizations.of(context)!.sunday)),
              ],
              onChanged: (value) {
                setState(() {
                  _startWeekday = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Show week numbers toggle
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.showWeekNumbers,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: appColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showWeekNumbers,
                  onChanged: (value) {
                    setState(() {
                      _showWeekNumbers = value;
                    });
                  },
                  activeThumbColor: appColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Show time toggle
            Row(
              children: [
                Text(
                  'Show Time',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: appColors.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showTime,
                  onChanged: (value) {
                    setState(() {
                      _showTime = value;
                    });
                  },
                  activeThumbColor: appColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(color: appColors.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onSettingsChanged(_startWeekday, _showWeekNumbers, _showTime);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.save,
                    style: TextStyle(color: appColors.whiteTextOnBlue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCalendar extends StatefulWidget {
  final DateRange? initialDateRange;
  final Function(DateRange) onDateRangeChanged;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool showTodayIndicator;
  final String? title;
  final int startWeekday; // 1 = Monday, 7 = Sunday
  final bool showWeekNumbers;
  final bool showTime;
  final String? companyId; // Add company ID to fetch approved requests

  const CustomCalendar({
    super.key,
    this.initialDateRange,
    required this.onDateRangeChanged,
    this.minDate,
    this.maxDate,
    this.showTodayIndicator = true,
    this.title,
    this.startWeekday = 1, // Default to Monday
    this.showWeekNumbers = false,
    this.showTime = false,
    this.companyId, // Add company ID to fetch approved requests
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _focusedDate;
  DateRange? _dateRange;
  late int _startWeekday;
  late bool _showWeekNumbers;
  late bool _showTime;
  DateTime? _hoveredDate;
  String? _hoveredHalf; // 'first' or 'second'
  Map<String, List<Map<String, dynamic>>> _approvedRequests = {}; // Date string -> List of approved requests

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _dateRange = widget.initialDateRange;
    _startWeekday = widget.startWeekday;
    _showWeekNumbers = widget.showWeekNumbers;
    _showTime = widget.showTime;
    _loadSettings();
    _loadApprovedRequests();
  }

  Future<void> _loadApprovedRequests() async {
    if (widget.companyId == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('timeoff_requests')
          .where('status', isEqualTo: 'approved')
          .get();
      
      final Map<String, List<Map<String, dynamic>>> requests = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        final endDate = (data['endDate'] as Timestamp?)?.toDate();
        
        if (startDate != null && endDate != null) {
          // Only add to working days (Monday-Friday by default)
          DateTime current = startDate;
          while (!current.isAfter(endDate)) {
            // Check if this is a working day (Monday = 1, Tuesday = 2, ..., Friday = 5)
            if (current.weekday >= 1 && current.weekday <= 5) {
              final dateKey = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
              requests.putIfAbsent(dateKey, () => []).add(data);
            }
            current = current.add(const Duration(days: 1));
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _approvedRequests = requests;
        });
      }
    } catch (e) {
      // Ignore errors for now
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      if (_dateRange == null) {
        // First selection - set as start date
        _dateRange = DateRange(startDate: selectedDate);
        
        // If time is enabled, show start time picker immediately
        if (_showTime) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStartTimePicker();
          });
        }
      } else if (_dateRange!.startDate == null) {
        // Start date is null, set as start date
        _dateRange = DateRange(startDate: selectedDate);
        
        // If time is enabled, show start time picker immediately
        if (_showTime) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStartTimePicker();
          });
        }
      } else if (_dateRange!.endDate == null) {
        // End date is null, set as end date
        if (selectedDate.isBefore(_dateRange!.startDate!)) {
          // If selected date is before start date, swap them
          _dateRange = DateRange(
              startDate: selectedDate, endDate: _dateRange!.startDate);
        } else {
          _dateRange = DateRange(
              startDate: _dateRange!.startDate, endDate: selectedDate);
        }
        
        // If time is enabled, show end time picker immediately
        if (_showTime) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEndTimePicker();
          });
        } else {
          // For Days policies, auto-close when both dates are selected
          widget.onDateRangeChanged(_dateRange!);
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(_dateRange!);
          }
        }
      } else {
        // Both dates are set, start new selection
        _dateRange = DateRange(startDate: selectedDate);
        
        // If time is enabled, show start time picker immediately
        if (_showTime) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showStartTimePicker();
          });
        }
      }
    });

    // Update callback immediately for first date
    if (_dateRange!.startDate != null && _dateRange!.endDate == null) {
      widget.onDateRangeChanged(_dateRange!);
    }
  }

  Future<void> _showStartTimePicker() async {
    if (_dateRange == null || _dateRange!.startDate == null) return;
    
    // Show start time picker with 24-hour format
    final startTime = await showTimePicker(
      context: context,
      initialTime: _dateRange!.startTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (startTime != null) {
      setState(() {
        _dateRange = DateRange(
          startDate: _dateRange!.startDate,
          endDate: _dateRange!.endDate,
          startTime: startTime,
          endTime: _dateRange!.endTime,
        );
      });
      
      // Update callback after start time is set
      widget.onDateRangeChanged(_dateRange!);
    }
  }

  Future<void> _showEndTimePicker() async {
    if (_dateRange == null || !_dateRange!.isComplete) return;
    
    // Show end time picker with 24-hour format
    final endTime = await showTimePicker(
      context: context,
      initialTime: _dateRange!.endTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (endTime != null) {
      setState(() {
        _dateRange = DateRange(
          startDate: _dateRange!.startDate,
          endDate: _dateRange!.endDate,
          startTime: _dateRange!.startTime,
          endTime: endTime,
        );
      });
      
              // Update callback and close calendar after end time is set
        widget.onDateRangeChanged(_dateRange!);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(_dateRange!);
        }
    }
  }

  // Half-day selection methods
  void _onHalfDaySelected(DateTime date, String half) {
    setState(() {
      if (_dateRange == null) {
        // First selection - set as start date
        if (half == 'first') {
          // First half = only first half (08:00-12:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 8, minute: 0),
            endTime: const TimeOfDay(hour: 12, minute: 0),
          );
        } else {
          // Second half = only second half (13:00-17:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 13, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          );
        }
      } else if (_dateRange!.startDate == null) {
        // Start date is null, set as start date
        if (half == 'first') {
          // First half = only first half (08:00-12:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 8, minute: 0),
            endTime: const TimeOfDay(hour: 12, minute: 0),
          );
        } else {
          // Second half = only second half (13:00-17:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 13, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          );
        }
      } else if (_dateRange!.endDate == null) {
        // End date is null, set as end date
        if (date.isBefore(_dateRange!.startDate!)) {
          // If selected date is before start date, swap them
          if (half == 'first') {
            // First half = only first half (08:00-12:00)
            _dateRange = DateRange(
              startDate: date,
              endDate: _dateRange!.startDate,
              startTime: const TimeOfDay(hour: 8, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
            );
          } else {
            // Second half = only second half (13:00-17:00)
            _dateRange = DateRange(
              startDate: date,
              endDate: _dateRange!.startDate,
              startTime: const TimeOfDay(hour: 13, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            );
          }
        } else {
          // End date selection - OPPOSITE logic from start date
          if (half == 'first') {
            // First half = only first half (08:00-12:00)
            _dateRange = DateRange(
              startDate: _dateRange!.startDate,
              endDate: date,
              startTime: _dateRange!.startTime,
              endTime: const TimeOfDay(hour: 12, minute: 0),
            );
          } else {
            // Second half = only second half (13:00-17:00)
            _dateRange = DateRange(
              startDate: _dateRange!.startDate,
              endDate: date,
              startTime: _dateRange!.startTime,
              endTime: const TimeOfDay(hour: 17, minute: 0),
            );
          }
        }
        
        // Update callback and close calendar when both dates are selected
        widget.onDateRangeChanged(_dateRange!);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(_dateRange!);
        }
      } else {
        // Both dates are set, start new selection
        if (half == 'first') {
          // First half = only first half (08:00-12:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 8, minute: 0),
            endTime: const TimeOfDay(hour: 12, minute: 0),
          );
        } else {
          // Second half = only second half (13:00-17:00)
          _dateRange = DateRange(
            startDate: date,
            startTime: const TimeOfDay(hour: 13, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          );
        }
      }
    });

    // Update callback immediately for first date
    if (_dateRange!.startDate != null && _dateRange!.endDate == null) {
      widget.onDateRangeChanged(_dateRange!);
    }
  }

  bool _isHalfDaySelected(DateTime date, String half) {
    if (_dateRange == null) return false;
    
    // Check if this date is selected as start date with this half
    if (_dateRange!.startDate != null &&
        _dateRange!.startDate!.year == date.year &&
        _dateRange!.startDate!.month == date.month &&
        _dateRange!.startDate!.day == date.day) {
      if (half == 'first' && _dateRange!.startTime?.hour == 8 && _dateRange!.endTime?.hour == 12) return true;
      if (half == 'second' && _dateRange!.startTime?.hour == 13 && _dateRange!.endTime?.hour == 17) return true;
    }
    
    // Check if this date is selected as end date with this half
    if (_dateRange!.endDate != null &&
        _dateRange!.endDate!.year == date.year &&
        _dateRange!.endDate!.month == date.month &&
        _dateRange!.endDate!.day == date.day) {
      if (half == 'first' && _dateRange!.endTime?.hour == 12) return true;
      if (half == 'second' && _dateRange!.endTime?.hour == 17) return true;
    }
    
    return false;
  }



  bool _isDateInRange(DateTime date) {
    if (_dateRange == null || !_dateRange!.isComplete) return false;

    // Don't show range background for start and end dates if they're half-day selections
    bool isStartDate = _dateRange!.startDate != null &&
        date.year == _dateRange!.startDate!.year &&
        date.month == _dateRange!.startDate!.month &&
        date.day == _dateRange!.startDate!.day;
        
    bool isEndDate = _dateRange!.endDate != null &&
        date.year == _dateRange!.endDate!.year &&
        date.month == _dateRange!.endDate!.month &&
        date.day == _dateRange!.endDate!.day;

    // If this is the start or end date and it has time (half-day), don't show range background
    if (isStartDate && _dateRange!.startTime != null) return false;
    if (isEndDate && _dateRange!.endTime != null) return false;

    // Show range background for dates between start and end (excluding start/end if they're half-days)
    return date.isAfter(_dateRange!.startDate!) &&
           date.isBefore(_dateRange!.endDate!);
  }

  bool _isDateSelected(DateTime date) {
    if (_dateRange == null) return false;

    // Check if this date is selected as start or end date
    bool isStartDate = _dateRange!.startDate != null &&
        date.year == _dateRange!.startDate!.year &&
        date.month == _dateRange!.startDate!.month &&
        date.day == _dateRange!.startDate!.day;
        
    bool isEndDate = _dateRange!.endDate != null &&
        date.year == _dateRange!.endDate!.year &&
        date.month == _dateRange!.endDate!.month &&
        date.day == _dateRange!.endDate!.day;

    // Only show full selection if it's a complete day (not half-day)
    if (isStartDate) {
      // Check if start date has time (half-day) or is full day
      if (_dateRange!.startTime != null) {
        // Half-day selection - don't show full selection
        return false;
      }
      return true;
    }
    
    if (isEndDate) {
      // Check if end date has time (half-day) or is full day
      if (_dateRange!.endTime != null) {
        // Half-day selection - don't show full selection
        return false;
      }
      return true;
    }

    return false;
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) return true;
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) return true;
    
    // Disable dates that already have approved requests
    if (widget.companyId != null) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final requests = _approvedRequests[dateKey];
      if (requests != null && requests.isNotEmpty) {
        return true; // Disable dates with approved requests
      }
    }
    
    return false;
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  void _clearSelection() {
    setState(() {
      _dateRange = null;
    });
    widget.onDateRangeChanged(const DateRange());
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => CalendarSettingsDialog(
        startWeekday: _startWeekday,
        showWeekNumbers: _showWeekNumbers,
        showTime: _showTime,
        onSettingsChanged: (startWeekday, showWeekNumbers, showTime) {
          setState(() {
            _startWeekday = startWeekday;
            _showWeekNumbers = showWeekNumbers;
            _showTime = showTime;
          });
          // Save settings to shared preferences immediately
          _saveSettings();
        },
      ),
    );
  }

  void _saveSettings() async {
    try {
      await CalendarStorage.saveSettings(_startWeekday, _showWeekNumbers, _showTime);
    } catch (e) {
      // Saving settings failed; ignore to avoid blocking UI
      debugPrint('Calendar: failed to save settings: $e');
    }
  }

  void _loadSettings() async {
    try {
      final settings = await CalendarStorage.loadSettings();

      if (mounted) {
        setState(() {
          _startWeekday = settings['startWeekday'] ?? widget.startWeekday;
          _showWeekNumbers =
              settings['showWeekNumbers'] ?? widget.showWeekNumbers;
          _showTime = settings['showTime'] ?? widget.showTime;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _startWeekday = widget.startWeekday;
          _showWeekNumbers = widget.showWeekNumbers;
          _showTime = widget.showTime;
        });
      }
    }
  }

  void _showMonthYearPicker() {
    showDialog(
      context: context,
      builder: (context) => MonthYearPickerDialog(
        currentDate: _focusedDate,
        onDateSelected: (DateTime newDate) {
          setState(() {
            _focusedDate = DateTime(newDate.year, newDate.month, 1);
          });
        },
      ),
    );
  }

  List<String> _getDayHeaders() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> headers = [];

    for (int i = 0; i < 7; i++) {
      final dayIndex = (_startWeekday - 1 + i) % 7;
      headers.add(dayNames[dayIndex]);
    }

    return headers;
  }

  int _getWeekNumber(DateTime date) {
    // ISO week number calculation
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // January 4th is always in week 1
    final jan4 = DateTime(year, 1, 4);
    final week1Start = jan4.subtract(Duration(days: jan4.weekday - 1));

    final targetDate = DateTime(year, month, day);
    final weekNumber =
        ((targetDate.difference(week1Start).inDays) / 7).floor() + 1;

    return weekNumber;
  }

  Widget _buildWeekNumberCell(
      DateTime weekStartDate, AppColors appColors, ThemeData theme) {
    final weekNumber = _getWeekNumber(weekStartDate);

    return SizedBox(
      width: 40,
      child: Container(
        height: 28, // Further reduced to match day cells
        margin: const EdgeInsets.all(1), // Reduced from 2 to match day cells
        decoration: BoxDecoration(
          color: appColors.backgroundLight,
          borderRadius: BorderRadius.circular(6), // Reduced from 8
          border: Border.all(color: appColors.lightGray.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            '$weekNumber',
            style: theme.textTheme.bodySmall?.copyWith(
              color: appColors.midGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minWidth: 350,
        // Remove maxHeight constraint to let content determine size naturally
      ),
      decoration: BoxDecoration(
        color: appColors.cardColorDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(Icons.chevron_left,
                      color: appColors.whiteTextOnBlue),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showMonthYearPicker,
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedDate),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: appColors.whiteTextOnBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right,
                      color: appColors.whiteTextOnBlue),
                ),
              ],
            ),
          ),

          // Calendar Grid
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day headers
                  Row(
                    children: [
                      if (_showWeekNumbers)
                        SizedBox(
                          width: 40,
                          child: Text(
                            AppLocalizations.of(context)!.weekAbbreviation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: appColors.midGray,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ..._getDayHeaders().map((day) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4), // Reduced from 8
                              child: Text(
                                day,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: appColors.midGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                    ],
                  ),

                  // Calendar days
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildCalendarDays(appColors, theme),
                    ),
                  ),



                  const SizedBox(height: 4), // Reduced spacing

                  // Action buttons
                  Row(
                    children: [
                      // Settings cog button
                      IconButton(
                        onPressed: _showSettings,
                        icon:
                            Icon(Icons.settings, color: appColors.primaryBlue),
                        tooltip: AppLocalizations.of(context)!.calendarSettings,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _goToToday,
                        child: Text(
                          AppLocalizations.of(context)!.today,
                          style: TextStyle(color: appColors.primaryBlue),
                        ),
                      ),
                      if (_dateRange?.hasSelection == true) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearSelection,
                          child: Text(
                            AppLocalizations.of(context)!.clear,
                            style: TextStyle(color: appColors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarDays(AppColors appColors, ThemeData theme) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);

    // Calculate the first day of the week based on custom start weekday
    final firstWeekday = firstDayOfMonth.weekday;
    final daysFromPreviousMonth = (firstWeekday - _startWeekday + 7) % 7;

    // Calculate the first date to display (from previous month)
    final firstDisplayDate =
        firstDayOfMonth.subtract(Duration(days: daysFromPreviousMonth));

    final List<Widget> rows = [];

    // Calculate total weeks needed (5 weeks is usually enough and more compact)
    final totalWeeks = 5;

    for (int week = 0; week < totalWeeks; week++) {
      final List<Widget> currentRow = [];

      // Add week number if enabled
      if (_showWeekNumbers) {
        final weekStartDate = firstDisplayDate.add(Duration(days: week * 7));
        currentRow.add(_buildWeekNumberCell(weekStartDate, appColors, theme));
      }

      // Add 7 days for this week
      for (int day = 0; day < 7; day++) {
        final date = firstDisplayDate.add(Duration(days: week * 7 + day));
        final isCurrentMonth = date.month == _focusedDate.month;

        currentRow.add(_buildDayCell(date, appColors, theme,
            isCurrentMonth: isCurrentMonth));
      }

      rows.add(Row(children: currentRow));
      if (week < totalWeeks - 1) {
        rows.add(const SizedBox(height: 2)); // Reduced spacing between rows
      }
    }

    return rows;
  }

  Widget _buildDayCell(DateTime date, AppColors appColors, ThemeData theme,
      {required bool isCurrentMonth}) {
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final isDisabled = _isDateDisabled(date);
    final isWeekend =
        date.weekday == 6 || date.weekday == 7; // Saturday or Sunday

    Color backgroundColor = Colors.transparent;
    Color textColor = isCurrentMonth ? appColors.textColor : appColors.midGray;

    if (isSelected) {
      backgroundColor = appColors.primaryBlue;
      textColor = appColors.whiteTextOnBlue;
    } else if (isInRange) {
      backgroundColor = appColors.primaryBlue.withValues(alpha: 0.2);
      textColor = appColors.primaryBlue;
    }

    if (isDisabled) {
      textColor = appColors.lightGray;
    } else if (isWeekend) {
      backgroundColor = appColors.lightGray.withValues(alpha: 0.3);
    }

    return Expanded(
      child: MouseRegion(
        cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isDisabled ? null : () => _onDateSelected(date),
          child: Container(
            height: 28,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: isToday && widget.showTodayIndicator
                  ? Border.all(color: appColors.primaryBlue, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                // Date number
                Center(
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Half-day selection overlays (show on hover or when selected)
                if (!isDisabled) ...[
                  // Use Positioned.fill with Row for perfect 50/50 split
                  Positioned.fill(
                    child: Row(
                      children: [
                        // First half (left side)
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => setState(() {
                              _hoveredDate = date;
                              _hoveredHalf = 'first';
                            }),
                            onExit: (_) => setState(() {
                              _hoveredDate = null;
                              _hoveredHalf = null;
                            }),
                            child: GestureDetector(
                              onTap: () => _onHalfDaySelected(date, 'first'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isHalfDaySelected(date, 'first') 
                                      ? appColors.primaryBlue.withValues(alpha: 0.7)
                                      : (_hoveredDate == date && _hoveredHalf == 'first')
                                          ? appColors.primaryBlue.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Second half (right side)
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => setState(() {
                              _hoveredDate = date;
                              _hoveredHalf = 'second';
                            }),
                            onExit: (_) => setState(() {
                              _hoveredDate = null;
                              _hoveredHalf = null;
                            }),
                            child: GestureDetector(
                              onTap: () => _onHalfDaySelected(date, 'second'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isHalfDaySelected(date, 'second') 
                                      ? appColors.primaryBlue.withValues(alpha: 0.7)
                                      : (_hoveredDate == date && _hoveredHalf == 'second')
                                          ? appColors.primaryBlue.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Approved request indicators
                  if (widget.companyId != null) ...[
                    Positioned(
                      top: 2,
                      right: 2,
                      child: _buildApprovedRequestIndicator(date),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedRequestIndicator(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final requests = _approvedRequests[dateKey];
    
    if (requests == null || requests.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Show a small green checkmark icon for approved requests
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        size: 8,
        color: Colors.white,
      ),
    );
  }
}

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime currentDate;
  final Function(DateTime) onDateSelected;

  const MonthYearPickerDialog({
    super.key,
    required this.currentDate,
    required this.onDateSelected,
  });

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _showingYearPicker = true;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.currentDate.year;
    _selectedMonth = widget.currentDate.month;
  }

  void _selectYear(int year) {
    setState(() {
      _selectedYear = year;
      _showingYearPicker = false;
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = month;
    });
    final newDate = DateTime(_selectedYear, month, 1);
    widget.onDateSelected(newDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the dialog content
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
              decoration: BoxDecoration(
                color: appColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _showingYearPicker
                  ? _buildYearGrid(appColors, theme)
                  : _buildMonthGrid(appColors, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearGrid(AppColors appColors, ThemeData theme) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final year = DateTime.now().year - 10 + index;
        final isSelected = year == _selectedYear;

        return GestureDetector(
          onTap: () => _selectYear(year),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? appColors.primaryBlue
                  : appColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? appColors.primaryBlue : appColors.lightGray,
              ),
            ),
            child: Center(
              child: Text(
                '$year',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? appColors.whiteTextOnBlue
                      : appColors.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(AppColors appColors, ThemeData theme) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        final isSelected = month == _selectedMonth;

        return GestureDetector(
          onTap: () => _selectMonth(month),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? appColors.primaryBlue
                  : appColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? appColors.primaryBlue : appColors.lightGray,
              ),
            ),
            child: Center(
              child: Text(
                monthNames[index],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? appColors.whiteTextOnBlue
                      : appColors.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
