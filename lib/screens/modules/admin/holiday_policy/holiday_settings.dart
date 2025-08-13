import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starktrack/theme/app_colors.dart';
import 'package:starktrack/services/country_region_service.dart';
import 'package:starktrack/screens/modules/admin/user_address.dart';
import 'add_national_holidays.dart';
import 'add_area_holidays.dart';

class HolidaySettingsScreen extends StatefulWidget {
  final String companyId;
  final Function()? onHolidaysAdded;

  const HolidaySettingsScreen({
    super.key,
    required this.companyId,
    this.onHolidaysAdded,
  });

  @override
  State<HolidaySettingsScreen> createState() => _HolidaySettingsScreenState();
}

class _HolidaySettingsScreenState extends State<HolidaySettingsScreen> {
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  List<CountryData> _availableCountries = [];
  List<Map<String, dynamic>> _nationalHolidays = [];
  List<Map<String, dynamic>> _areaHolidays = [];

  // Holiday type selection
  bool _includeNationalHolidays = true;
  bool _includeAreaHolidays = true;

  // Area selection
  Map<String, dynamic> _regionFilter = {
    'country': 'Switzerland',
    'area': '',
    'city': '',
    'postCode': '',
  };
  List<String> _selectedAreas = [];

  // Color selection
  int _nationalHolidayColor = 0xFF4CAF50; // Green
  int _areaHolidayColor = 0xFF2196F3; // Blue

  @override
  void initState() {
    super.initState();
    _loadAvailableCountries();
  }

  Future<void> _loadAvailableCountries() async {
    setState(() => _isLoading = true);
    try {
      final countries = await CountryRegionService.getCountries();
      setState(() {
        _availableCountries = countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load countries: $e');
    }
  }

  Future<void> _loadHolidays() async {
    if (!_includeNationalHolidays && !_includeAreaHolidays) {
      _showErrorSnackBar('Please select at least one holiday type');
      return;
    }

    // Clear previous holiday lists
    setState(() {
      _nationalHolidays.clear();
      _areaHolidays.clear();
      _isLoading = true;
    });

    try {
      // Get country code from region filter
      final countryCode = _availableCountries
          .firstWhere(
            (c) => c.name == _regionFilter['country'],
            orElse: () => CountryData(
                name: _regionFilter['country'], code: _regionFilter['country']),
          )
          .code;

      // Load national holidays if selected
      if (_includeNationalHolidays) {
        final nationalHolidays =
            await NationalHolidayService.getNationalHolidaysFromApi(
          countryCode: countryCode,
          year: _selectedYear,
          color: _nationalHolidayColor,
        );
        setState(() {
          _nationalHolidays = nationalHolidays;
        });
      }

      // Load area holidays if selected
      if (_includeAreaHolidays) {
        final areaHolidays = await AreaHolidayService.getAreaHolidaysFromApi(
          countryCode: countryCode,
          year: _selectedYear,
          selectedAreas: _selectedAreas,
          color: _areaHolidayColor,
        );
        setState(() {
          _areaHolidays = areaHolidays;
        });

        // Debug logging removed
      }

      setState(() {
        _isLoading = false;
      });

      // Debug logging removed
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load holidays: $e');
    }
  }

  void _onRegionChanged(Map<String, dynamic> regionData) {
    setState(() {
      _regionFilter = regionData;
      // Update selected areas based on region filter
      if (regionData['area'] != null &&
          regionData['area'].toString().isNotEmpty) {
        final areas = regionData['area']
            .toString()
            .split(',')
            .map((e) => e.trim())
            .toList();
        _selectedAreas = areas.where((area) => area.isNotEmpty).toList();
      } else {
        _selectedAreas = [];
      }
      // Clear holiday lists when region changes
      _nationalHolidays.clear();
      _areaHolidays.clear();

      // Debug logging
      print(
          'DEBUG: Region changed - Country: ${regionData['country']}, Area: ${regionData['area']}');
      print('DEBUG: Selected areas: $_selectedAreas');
    });
  }

  Future<void> _addNationalHolidays() async {
    if (_nationalHolidays.isEmpty) {
      _showErrorSnackBar('No national holidays to add');
      return;
    }

    setState(() => _isLoading = true);

    try {
      int addedCount = 0;
      for (final holiday in _nationalHolidays) {
        try {
          final policyData = {
            'name': holiday['name'],
            'color': holiday['color'],
            'assignTo': 'all',
            'region': {
              'country': _regionFilter['country'],
              'area': ['all'],
              'city': '',
              'postCode': '',
            },
            'period': {
              'start': Timestamp.fromDate(holiday['date'] as DateTime),
              'end': Timestamp.fromDate(holiday['date'] as DateTime),
            },
            'repeatAnnually': holiday['repeatAnnually'],
            'paid': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('holiday_policies')
              .add(policyData);

          addedCount++;
        } catch (e) {
          print('Error adding ${holiday['name']}: $e');
        }
      }

      setState(() => _isLoading = false);
      _showSuccessSnackBar('Added $addedCount national holidays');

      // Don't close the dialog automatically - let user add area holidays too
      // if (widget.onHolidaysAdded != null) {
      //   widget.onHolidaysAdded!();
      // }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to add national holidays: $e');
    }
  }

  Future<void> _addAreaHolidays() async {
    if (_areaHolidays.isEmpty) {
      _showErrorSnackBar('No area holidays to add');
      return;
    }

    setState(() => _isLoading = true);

    try {
      int addedCount = 0;
      for (final holiday in _areaHolidays) {
        try {
          final policyData = {
            'name': holiday['name'],
            'color': holiday['color'],
            'assignTo': 'region',
            'region': {
              'country': _regionFilter['country'],
              'area': holiday['regions'] ?? _selectedAreas,
              'city': '',
              'postCode': '',
            },
            'period': {
              'start': Timestamp.fromDate(holiday['date'] as DateTime),
              'end': Timestamp.fromDate(holiday['date'] as DateTime),
            },
            'repeatAnnually': holiday['repeatAnnually'],
            'paid': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('holiday_policies')
              .add(policyData);

          addedCount++;
        } catch (e) {
          print('Error adding ${holiday['name']}: $e');
        }
      }

      setState(() => _isLoading = false);
      _showSuccessSnackBar('Added $addedCount area holidays');

      // Don't close the dialog automatically - let user add more holidays
      // if (widget.onHolidaysAdded != null) {
      //   widget.onHolidaysAdded!();
      // }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to add area holidays: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Form Layout
            Card(
              color: appColors.cardColorDark,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Holiday Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Year Field
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Year:',
                            style: TextStyle(
                              color: appColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? appColors.cardColorDark
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white24
                                      : Colors.black26,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white24
                                      : Colors.black26,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: appColors.primaryBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: List.generate(10, (index) {
                              final year = DateTime.now().year + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value!;
                                _nationalHolidays.clear();
                                _areaHolidays.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Area Field (using UserAddress)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Region:',
                                style: TextStyle(
                                  color: appColors.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: UserAddress(
                                addressData: _regionFilter,
                                onAddressChanged: _onRegionChanged,
                                title: '',
                                isSwissAddress: true,
                                showCard: false,
                                showStreetAndNumber: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // National Holidays Row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            'National:',
                            style: TextStyle(
                              color: appColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _includeNationalHolidays,
                          onChanged: (value) {
                            setState(() {
                              _includeNationalHolidays = value ?? true;
                            });
                          },
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'National Holidays',
                            style: TextStyle(color: appColors.textColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showColorPicker(true),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(_nationalHolidayColor),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Area Holidays Row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Area:',
                            style: TextStyle(
                              color: appColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _includeAreaHolidays,
                          onChanged: (value) {
                            setState(() {
                              _includeAreaHolidays = value ?? false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'Area Holidays',
                            style: TextStyle(color: appColors.textColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showColorPicker(false),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(_areaHolidayColor),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Load Holidays Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loadHolidays,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Load Holidays',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // National Holidays Section
            if (_nationalHolidays.isNotEmpty) ...[
              Card(
                color: appColors.cardColorDark,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'National Holidays (${_nationalHolidays.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These holidays apply to the entire country',
                        style: TextStyle(
                          color: appColors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          key: ValueKey('national_holidays_list'),
                          itemCount: _nationalHolidays.length,
                          itemBuilder: (context, index) {
                            final holiday = _nationalHolidays[index];
                            return ListTile(
                              key: ValueKey(
                                  'national_holiday_${holiday['date']}'),
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(_nationalHolidayColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                holiday['name'] as String,
                                style: TextStyle(color: appColors.textColor),
                              ),
                              subtitle: Text(
                                '${(holiday['date'] as DateTime).day}/${(holiday['date'] as DateTime).month}/${(holiday['date'] as DateTime).year}',
                                style: TextStyle(
                                    color: appColors.textColor
                                        .withValues(alpha: 0.7)),
                              ),
                              trailing: holiday['repeatAnnually'] as bool
                                  ? const Icon(Icons.repeat,
                                      color: Colors.green)
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addNationalHolidays,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Add ${_nationalHolidays.length} National Holidays',
                                  style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Area Holidays Section
            if (_areaHolidays.isNotEmpty) ...[
              Card(
                color: appColors.cardColorDark,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Area Holidays (${_areaHolidays.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These holidays apply to specific regions',
                        style: TextStyle(
                          color: appColors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          key: ValueKey('area_holidays_list'),
                          itemCount: _areaHolidays.length,
                          itemBuilder: (context, index) {
                            final holiday = _areaHolidays[index];
                            return ListTile(
                              key: ValueKey('area_holiday_${holiday['date']}'),
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(_areaHolidayColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                holiday['name'] as String,
                                style: TextStyle(color: appColors.textColor),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(holiday['date'] as DateTime).day}/${(holiday['date'] as DateTime).month}/${(holiday['date'] as DateTime).year}',
                                    style: TextStyle(
                                        color: appColors.textColor
                                            .withValues(alpha: 0.7)),
                                  ),
                                  if (holiday['regions'] != null &&
                                      (holiday['regions'] as List).isNotEmpty)
                                    Text(
                                      'Regions: ${(holiday['regions'] as List).join(', ')}',
                                      style: TextStyle(
                                          color: appColors.textColor
                                              .withValues(alpha: 0.7),
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: holiday['repeatAnnually'] as bool
                                  ? const Icon(Icons.repeat,
                                      color: Colors.green)
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addAreaHolidays,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Add ${_areaHolidays.length} Area Holidays',
                                  style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Empty state
            if (_nationalHolidays.isEmpty && _areaHolidays.isEmpty) ...[
              Card(
                color: appColors.cardColorDark,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: appColors.textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No holidays loaded',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Load Holidays" to fetch holidays for the selected country and year',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appColors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showColorPicker(bool isNational) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNational
            ? 'Select National Holiday Color'
            : 'Select Area Holiday Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorOption(0xFF4CAF50, 'Green', isNational),
                  _buildColorOption(0xFF2196F3, 'Blue', isNational),
                  _buildColorOption(0xFFFF9800, 'Orange', isNational),
                  _buildColorOption(0xFF9C27B0, 'Purple', isNational),
                  _buildColorOption(0xFFF44336, 'Red', isNational),
                  _buildColorOption(0xFF00BCD4, 'Cyan', isNational),
                  _buildColorOption(0xFF795548, 'Brown', isNational),
                  _buildColorOption(0xFF607D8B, 'Blue Grey', isNational),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(int color, String label, bool isNational) {
    final isSelected =
        (isNational ? _nationalHolidayColor : _areaHolidayColor) == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isNational) {
            _nationalHolidayColor = color;
          } else {
            _areaHolidayColor = color;
          }
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: Color(color),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
