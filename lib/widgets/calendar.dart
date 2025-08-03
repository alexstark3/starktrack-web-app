import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/calendar_storage.dart';
import '../theme/app_colors.dart';

class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRange({this.startDate, this.endDate});

  bool get isSingleDate =>
      startDate != null &&
      endDate != null &&
      startDate!.isAtSameMomentAs(endDate!);
  bool get hasSelection => startDate != null || endDate != null;
  bool get isComplete => startDate != null && endDate != null;

  @override
  String toString() {
    if (startDate == null && endDate == null) return 'No dates selected';
    if (startDate == null)
      return 'End: ${DateFormat('MMM dd, yyyy').format(endDate!)}';
    if (endDate == null)
      return 'Start: ${DateFormat('MMM dd, yyyy').format(startDate!)}';
    if (isSingleDate) return DateFormat('MMM dd, yyyy').format(startDate!);
    return '${DateFormat('MMM dd, yyyy').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}';
  }
}

class CalendarSettingsDialog extends StatefulWidget {
  final int startWeekday;
  final bool showWeekNumbers;
  final Function(int, bool) onSettingsChanged;

  const CalendarSettingsDialog({
    super.key,
    required this.startWeekday,
    required this.showWeekNumbers,
    required this.onSettingsChanged,
  });

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late int _startWeekday;
  late bool _showWeekNumbers;

  @override
  void initState() {
    super.initState();
    _startWeekday = widget.startWeekday;
    _showWeekNumbers = widget.showWeekNumbers;
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
              'Starting day of week',
              style: theme.textTheme.titleMedium?.copyWith(
                color: appColors.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _startWeekday,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appColors.lightGray),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text('Monday')),
                DropdownMenuItem(value: 2, child: Text('Tuesday')),
                DropdownMenuItem(value: 3, child: Text('Wednesday')),
                DropdownMenuItem(value: 4, child: Text('Thursday')),
                DropdownMenuItem(value: 5, child: Text('Friday')),
                DropdownMenuItem(value: 6, child: Text('Saturday')),
                DropdownMenuItem(value: 7, child: Text('Sunday')),
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
                  'Show week numbers',
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
                  activeColor: appColors.primaryBlue,
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
                    'Cancel',
                    style: TextStyle(color: appColors.textColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onSettingsChanged(_startWeekday, _showWeekNumbers);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
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
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _focusedDate;
  DateRange? _dateRange;
  late int _startWeekday;
  late bool _showWeekNumbers;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _dateRange = widget.initialDateRange;
    _startWeekday = widget.startWeekday;
    _showWeekNumbers = widget.showWeekNumbers;
    _loadSettings();
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      if (_dateRange == null) {
        // First selection - set as start date
        _dateRange = DateRange(startDate: selectedDate);
      } else if (_dateRange!.startDate == null) {
        // Start date is null, set as start date
        _dateRange = DateRange(startDate: selectedDate);
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
        // Update the callback and auto-close when end date is selected
        widget.onDateRangeChanged(_dateRange!);
        // Auto-close the dialog when both dates are selected
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        // Both dates are set, start new selection
        _dateRange = DateRange(startDate: selectedDate);
      }
    });

    widget.onDateRangeChanged(_dateRange!);
  }

  bool _isDateInRange(DateTime date) {
    if (_dateRange == null || !_dateRange!.isComplete) return false;

    return date.isAfter(
            _dateRange!.startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_dateRange!.endDate!.add(const Duration(days: 1)));
  }

  bool _isDateSelected(DateTime date) {
    if (_dateRange == null) return false;

    if (_dateRange!.startDate != null &&
        date.year == _dateRange!.startDate!.year &&
        date.month == _dateRange!.startDate!.month &&
        date.day == _dateRange!.startDate!.day) {
      return true;
    }

    if (_dateRange!.endDate != null &&
        date.year == _dateRange!.endDate!.year &&
        date.month == _dateRange!.endDate!.month &&
        date.day == _dateRange!.endDate!.day) {
      return true;
    }

    return false;
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) return true;
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) return true;
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
        onSettingsChanged: (startWeekday, showWeekNumbers) {
          setState(() {
            _startWeekday = startWeekday;
            _showWeekNumbers = showWeekNumbers;
          });
          // Save settings to shared preferences immediately
          _saveSettings();
          print(
              'Settings changed and saved: startWeekday=$startWeekday, showWeekNumbers=$showWeekNumbers');
        },
      ),
    );
  }

  void _saveSettings() async {
    print(
        'Attempting to save settings: startWeekday=$_startWeekday, showWeekNumbers=$_showWeekNumbers');
    try {
      await CalendarStorage.saveSettings(_startWeekday, _showWeekNumbers);
      print('Settings saved successfully via CalendarStorage');
    } catch (e) {
      print('Error saving calendar settings: $e');
    }
  }

  void _loadSettings() async {
    print('Attempting to load calendar settings...');
    try {
      final settings = await CalendarStorage.loadSettings();

      if (mounted) {
        setState(() {
          _startWeekday = settings['startWeekday'] ?? widget.startWeekday;
          _showWeekNumbers =
              settings['showWeekNumbers'] ?? widget.showWeekNumbers;
        });
        print(
            'Settings loaded: startWeekday=$_startWeekday, showWeekNumbers=$_showWeekNumbers');
      }
    } catch (e) {
      print('Error loading calendar settings: $e');
      if (mounted) {
        setState(() {
          _startWeekday = widget.startWeekday;
          _showWeekNumbers = widget.showWeekNumbers;
        });
        print(
            'Using widget defaults due to error: startWeekday=$_startWeekday, showWeekNumbers=$_showWeekNumbers');
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
        height: 32, // Reduced from 40 to match day cells
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
        maxHeight: 400, // Reduced from 500 to prevent overflow
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
                            'Wk',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: appColors.midGray,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ..._getDayHeaders().map((day) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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

                  const SizedBox(height: 8), // Reduced from 16

                  // Action buttons
                  Row(
                    children: [
                      // Settings cog button
                      IconButton(
                        onPressed: _showSettings,
                        icon:
                            Icon(Icons.settings, color: appColors.primaryBlue),
                        tooltip: 'Calendar Settings',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _goToToday,
                        child: Text(
                          'Today',
                          style: TextStyle(color: appColors.primaryBlue),
                        ),
                      ),
                      if (_dateRange?.hasSelection == true) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearSelection,
                          child: Text(
                            'Clear',
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

    // Calculate total weeks needed (6 weeks is usually enough)
    final totalWeeks = 6;

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
      child: GestureDetector(
        onTap: isDisabled ? null : () => _onDateSelected(date),
        child: Container(
          height: 32, // Reduced from 40 to save space
          margin: const EdgeInsets.all(1), // Reduced from 2 to save space
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6), // Reduced from 8
            border: isToday && widget.showTodayIndicator
                ? Border.all(color: appColors.primaryBlue, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                // Changed from bodyMedium to bodySmall
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
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
