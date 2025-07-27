import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../../../services/holiday_api_service.dart';
import '../../../services/country_region_service.dart';
import 'user_address.dart';

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
  List<ApiHoliday> _nationalHolidays = [];
  List<ApiHoliday> _areaHolidays = [];

  // Holiday type selection
  bool _includeNationalHolidays = true;
  bool _includeAreaHolidays = false;

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

      // Load holidays from API
      final holidays = await HolidayApiService.getHolidaysFromNagerApi(
        countryCode: countryCode,
        year: _selectedYear,
      );

      print('DEBUG: Loaded ${holidays.length} total holidays for $countryCode');
      print('DEBUG: Selected areas: $_selectedAreas');

      // Separate national and area holidays
      final national = holidays.where((h) => h.isNational).toList();
      final area = holidays.where((h) => !h.isNational).toList();

      print('DEBUG: Found ${national.length} national holidays');
      print('DEBUG: Found ${area.length} area holidays');

      // Filter area holidays based on selected areas
      List<ApiHoliday> filteredAreaHolidays = [];
      if (_selectedAreas.isNotEmpty) {
        for (final holiday in area) {
          // Check if this holiday applies to any of the selected areas
          if (holiday.regions != null && holiday.regions!.isNotEmpty) {
            // Extract region codes from API format (e.g., "CH-LU" -> "LU")
            final holidayRegions = holiday.regions!
                .map((r) => r.contains('-') ? r.split('-').last : r)
                .map((r) => r.toUpperCase())
                .toList();
            final selectedRegions =
                _selectedAreas.map((a) => a.toUpperCase()).toList();

            print(
                'DEBUG: Holiday "${holiday.name}" has regions: $holidayRegions (original: ${holiday.regions})');

            // Check if there's any overlap between holiday regions and selected regions
            final hasOverlap = holidayRegions
                .any((region) => selectedRegions.contains(region));
            if (hasOverlap) {
              filteredAreaHolidays.add(holiday);
              print(
                  'DEBUG: Added holiday "${holiday.name}" - matches selected areas');
            } else {
              print(
                  'DEBUG: Skipped holiday "${holiday.name}" - no match with selected areas');
            }
          } else {
            // If holiday has no specific regions, it might be a general area holiday
            // Include it if we have selected areas
            filteredAreaHolidays.add(holiday);
            print(
                'DEBUG: Added holiday "${holiday.name}" - no specific regions');
          }
        }
      } else {
        // If no specific areas selected, show all area holidays
        filteredAreaHolidays = area;
        print(
            'DEBUG: No areas selected, showing all ${area.length} area holidays');
      }

      print(
          'DEBUG: Final filtered area holidays: ${filteredAreaHolidays.length}');

      setState(() {
        _nationalHolidays = _includeNationalHolidays ? national : [];
        _areaHolidays = _includeAreaHolidays ? filteredAreaHolidays : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
    });
  }

  Future<void> _addNationalHolidays() async {
    if (_nationalHolidays.isEmpty) {
      _showErrorSnackBar('No national holidays found for the selected year');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final countryName = _regionFilter['country'];

      for (final holiday in _nationalHolidays) {
        final holidayConfig = holiday.toHolidayConfig();
        final docRef = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('holiday_policies')
            .doc();

        batch.set(docRef, {
          'name': holidayConfig.name,
          'date': Timestamp.fromDate(holidayConfig.date),
          'color': _nationalHolidayColor,
          'assignTo': 'all',
          'region': {
            'country': countryName,
            'area': ['all'],
            'city': '',
            'postCode': '',
          },
          'period': {
            'start': Timestamp.fromDate(holidayConfig.date),
            'end': Timestamp.fromDate(holidayConfig.date),
          },
          'repeatAnnually': holidayConfig.repeatAnnually,
          'paid': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (widget.onHolidaysAdded != null) {
        widget.onHolidaysAdded!();
      }

      _showSuccessSnackBar(
          'Added ${_nationalHolidays.length} national holidays');
    } catch (e) {
      _showErrorSnackBar('Failed to add national holidays: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAreaHolidays() async {
    if (_areaHolidays.isEmpty) {
      _showErrorSnackBar('No area holidays found for the selected year');
      return;
    }

    if (_selectedAreas.isEmpty) {
      _showErrorSnackBar('Please select at least one area');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final countryName = _regionFilter['country'];

      for (final holiday in _areaHolidays) {
        final holidayConfig = holiday.toHolidayConfig();
        final docRef = FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('holiday_policies')
            .doc();

        batch.set(docRef, {
          'name': holidayConfig.name,
          'date': Timestamp.fromDate(holidayConfig.date),
          'color': _areaHolidayColor,
          'assignTo': 'region',
          'region': {
            'country': countryName,
            'area': _selectedAreas,
            'city': '',
            'postCode': '',
          },
          'period': {
            'start': Timestamp.fromDate(holidayConfig.date),
            'end': Timestamp.fromDate(holidayConfig.date),
          },
          'repeatAnnually': holidayConfig.repeatAnnually,
          'paid': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (widget.onHolidaysAdded != null) {
        widget.onHolidaysAdded!();
      }

      _showSuccessSnackBar(
          'Added ${_areaHolidays.length} area holidays for ${_selectedAreas.length} areas');
    } catch (e) {
      _showErrorSnackBar('Failed to add area holidays: $e');
    } finally {
      setState(() => _isLoading = false);
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Form Layout
            Card(
              color: appColors.cardColorDark,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 12),

                    // Area Field (using UserAddress)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                            Expanded(
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
                    const SizedBox(height: 20),

                    // National Holidays Row
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'National:',
                            style: TextStyle(
                              color: appColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _includeNationalHolidays,
                          onChanged: (value) {
                            setState(() {
                              _includeNationalHolidays = value ?? true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'National Holidays',
                          style: TextStyle(color: appColors.textColor),
                        ),
                        const Spacer(),
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
                    const SizedBox(height: 8),

                    // Area Holidays Row
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Area:',
                            style: TextStyle(
                              color: appColors.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _includeAreaHolidays,
                          onChanged: (value) {
                            setState(() {
                              _includeAreaHolidays = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Area Holidays',
                          style: TextStyle(color: appColors.textColor),
                        ),
                        const Spacer(),
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
                    const SizedBox(height: 20),

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
                          itemCount: _nationalHolidays.length,
                          itemBuilder: (context, index) {
                            final holiday = _nationalHolidays[index];
                            return ListTile(
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(_nationalHolidayColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                holiday.name,
                                style: TextStyle(color: appColors.textColor),
                              ),
                              subtitle: Text(
                                '${holiday.date.day}/${holiday.date.month}/${holiday.date.year}',
                                style: TextStyle(
                                    color: appColors.textColor
                                        .withValues(alpha: 0.7)),
                              ),
                              trailing: holiday.toHolidayConfig().repeatAnnually
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
                            backgroundColor: Colors.green,
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
                          itemCount: _areaHolidays.length,
                          itemBuilder: (context, index) {
                            final holiday = _areaHolidays[index];
                            return ListTile(
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(_areaHolidayColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                holiday.name,
                                style: TextStyle(color: appColors.textColor),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${holiday.date.day}/${holiday.date.month}/${holiday.date.year}',
                                    style: TextStyle(
                                        color: appColors.textColor
                                            .withValues(alpha: 0.7)),
                                  ),
                                  if (holiday.regions != null &&
                                      holiday.regions!.isNotEmpty)
                                    Text(
                                      'Regions: ${holiday.regions!.join(', ')}',
                                      style: TextStyle(
                                          color: appColors.textColor
                                              .withValues(alpha: 0.7),
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: holiday.toHolidayConfig().repeatAnnually
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
                            backgroundColor: Colors.blue,
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
