import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class UserAddress extends StatefulWidget {
  final Map<String, dynamic> addressData;
  final Function(Map<String, dynamic>) onAddressChanged;
  final String title;
  final bool isSwissAddress;
  final bool showCard;
  final bool showStreetAndNumber;

  const UserAddress({
    super.key,
    required this.addressData,
    required this.onAddressChanged,
    required this.title,
    this.isSwissAddress = true,
    this.showCard = true,
    this.showStreetAndNumber = true,
  });

  @override
  State<UserAddress> createState() => _UserAddressState();
}

class _UserAddressState extends State<UserAddress> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  List<Map<String, dynamic>> _countries = [];
  List<String> _areas = [];
  List<Map<String, dynamic>> _swissData = [];

  // Separate state for dialog selection
  List<String> _selectedAreasInDialog = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  @override
  void didUpdateWidget(UserAddress oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if the address data actually changed
    if (oldWidget.addressData != widget.addressData) {
      print(
          '🔍 DEBUG: UserAddress - Address data changed, updating controllers');
      print('🔍 DEBUG: UserAddress - Old: ${oldWidget.addressData}');
      print('🔍 DEBUG: UserAddress - New: ${widget.addressData}');
      _updateControllersFromAddressData();
    }
  }

  void _initializeControllers() {
    print(
        '🔍 DEBUG: UserAddress - Initializing controllers with address data: ${widget.addressData}');

    _countryController.text = widget.addressData['country'] ??
        (widget.isSwissAddress ? 'Switzerland' : '');
    _areaController.text = widget.addressData['area'] ?? '';
    _cityController.text = widget.addressData['city'] ?? '';
    _postCodeController.text = widget.addressData['postCode'] ?? '';
    _streetController.text = widget.addressData['street'] ?? '';
    _numberController.text = widget.addressData['streetNumber'] ?? '';

    print('🔍 DEBUG: UserAddress - Controllers initialized:');
    print('  Country: ${_countryController.text}');
    print('  Area: ${_areaController.text}');
    print('  City: ${_cityController.text}');
    print('  PostCode: ${_postCodeController.text}');
    print('  Street: ${_streetController.text}');
    print('  StreetNumber: ${_numberController.text}');
  }

  void _updateControllersFromAddressData() {
    print(
        '🔍 DEBUG: UserAddress - Updating controllers from address data: ${widget.addressData}');

    // Only update if the data is actually different to avoid unnecessary rebuilds
    final newCountry = widget.addressData['country'] ??
        (widget.isSwissAddress ? 'Switzerland' : '');
    final newArea = widget.addressData['area'] ?? '';
    final newCity = widget.addressData['city'] ?? '';
    final newPostCode = widget.addressData['postCode'] ?? '';
    final newStreet = widget.addressData['street'] ?? '';
    final newStreetNumber = widget.addressData['streetNumber'] ?? '';

    // Check if any values actually changed
    bool hasChanges = false;
    if (_countryController.text != newCountry) {
      _countryController.text = newCountry;
      hasChanges = true;
    }
    if (_areaController.text != newArea) {
      _areaController.text = newArea;
      hasChanges = true;
    }
    if (_cityController.text != newCity) {
      _cityController.text = newCity;
      hasChanges = true;
    }
    if (_postCodeController.text != newPostCode) {
      _postCodeController.text = newPostCode;
      hasChanges = true;
    }
    if (_streetController.text != newStreet) {
      _streetController.text = newStreet;
      hasChanges = true;
    }
    if (_numberController.text != newStreetNumber) {
      _numberController.text = newStreetNumber;
      hasChanges = true;
    }

    // Only call setState if there were actual changes and we're not in the middle of user input
    if (hasChanges) {
      // Use a microtask to avoid rebuilding during user input
      Future.microtask(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    print('🔍 DEBUG: UserAddress - Controllers updated:');
    print('  Country: ${_countryController.text}');
    print('  Area: ${_areaController.text}');
    print('  City: ${_cityController.text}');
    print('  PostCode: ${_postCodeController.text}');
    print('  Street: ${_streetController.text}');
    print('  StreetNumber: ${_numberController.text}');
  }

  Future<void> _loadData() async {
    await _loadCountries();
    if (widget.isSwissAddress) {
      await _loadSwissData();
    }
  }

  Future<void> _loadCountries() async {
    try {
      final jsonString =
          await rootBundle.loadString('lib/data/world_countries.json');
      final data = json.decode(jsonString);
      _countries = List<Map<String, dynamic>>.from(data);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  Future<void> _loadSwissData() async {
    try {
      final jsonString =
          await rootBundle.loadString('lib/data/swiss_cities.json');
      final data = json.decode(jsonString);
      _swissData = List<Map<String, dynamic>>.from(data);

      // Extract unique areas
      final areas =
          _swissData.map((item) => item['area'] as String).toSet().toList();

      setState(() {
        _areas = areas..sort();
      });

      // Debug output
      print(
          'DEBUG: Loaded ${_areas.length} areas: ${_areas.take(10).join(', ')}...');
    } catch (e) {
      debugPrint('Error loading Swiss data: $e');
    }
  }

  List<String> _getCitiesForArea(String area) {
    return _swissData
        .where((item) => item['area'] == area)
        .map((item) => item['city'] as String)
        .toList()
      ..sort();
  }

  List<String> _getCitiesForMultipleAreas(String areasText) {
    if (areasText.isEmpty) {
      return _swissData.map((item) => item['city'] as String).toSet().toList()
        ..sort();
    }

    final areas = areasText.split(',').map((e) => e.trim()).toList();
    final cities = <String>{};

    for (final area in areas) {
      if (area.isNotEmpty) {
        final areaCities = _getCitiesForArea(area);
        cities.addAll(areaCities);
      }
    }

    return cities.toList()..sort();
  }

  List<String> _getPostCodesForCity(String area, String city) {
    final cityData = _swissData.firstWhere(
      (item) => item['area'] == area && item['city'] == city,
      orElse: () => {'postCodes': []},
    );
    return List<String>.from(cityData['postCodes'] ?? [])..sort();
  }

  List<String> _getPostCodesForMultipleAreasAndCity(
      String areasText, String city) {
    if (areasText.isEmpty || city.isEmpty) {
      return [];
    }

    final areas = areasText.split(',').map((e) => e.trim()).toList();
    final postCodes = <String>{};

    for (final area in areas) {
      if (area.isNotEmpty) {
        final areaPostCodes = _getPostCodesForCity(area, city);
        postCodes.addAll(areaPostCodes);
      }
    }

    return postCodes.toList()..sort();
  }

  List<Map<String, dynamic>> _getCitiesForPostCode(String postCode) {
    return _swissData
        .where((item) => (item['postCodes'] as List).contains(postCode))
        .toList();
  }

  void _updateAddressData() {
    final newAddressData = {
      'country': _countryController.text,
      'area': _areaController.text,
      'city': _cityController.text,
      'postCode': _postCodeController.text,
      'street': _streetController.text,
      'streetNumber': _numberController.text,
    };

    widget.onAddressChanged(newAddressData);
  }

  void _onCityChanged(String? value) {
    if (value != null) {
      setState(() {
        _cityController.text = value;
        final postCodes =
            _getPostCodesForMultipleAreasAndCity(_areaController.text, value);
        if (postCodes.isNotEmpty) {
          _postCodeController.text = postCodes.first;
        }
      });
      _updateAddressData();
    }
  }

  void _onPostCodeChanged(String? value) {
    if (value != null) {
      setState(() {
        _postCodeController.text = value;
        final cities = _getCitiesForPostCode(value);

        print('DEBUG: Found ${cities.length} cities for post code $value');
        for (final city in cities) {
          print('DEBUG: - ${city['city']} (${city['area']})');
        }

        if (cities.isEmpty) {
          // No cities found for this post code
          _areaController.text = '';
          _cityController.text = '';
        } else if (cities.length == 1) {
          // Single city found
          final city = cities.first['city'] as String;
          final area = cities.first['area'] as String;
          _areaController.text = area;
          _cityController.text = city;
        } else {
          // Multiple cities found - show selection dialog
          _showCitySelectionDialog(cities, value);
          return; // Don't update address data yet
        }
      });
      _updateAddressData();
    }
  }

  void _showCitySelectionDialog(
      List<Map<String, dynamic>> cities, String postCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Multiple cities found for post code $postCode'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please select the correct city:'),
              const SizedBox(height: 16),
              ...cities.map((city) => ListTile(
                    title: Text('${city['city']} (${city['area']})'),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _areaController.text = city['area'] as String;
                        _cityController.text = city['city'] as String;
                      });
                      _updateAddressData();
                    },
                  )),
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final l10n = AppLocalizations.of(context);

    // Handle null cases
    if (appColors == null || l10n == null) {
      return const Center(
          child: Text('Error: Theme or localization not available'));
    }

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Country field (always show, Switzerland preselected for Swiss addresses)
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return _countries
                .map((c) => c['name'] as String)
                .where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          initialValue: TextEditingValue(text: _countryController.text),
          onSelected: (String selection) {
            setState(() {
              _countryController.text = selection;
            });
            _updateAddressData();
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                labelText: l10n.country,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? appColors.cardColorDark
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black26,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black26,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: appColors.primaryBlue, width: 2),
                ),
              ),
              style: TextStyle(color: appColors.textColor),
              onChanged: (value) {
                _countryController.text = value;
                _updateAddressData();
              },
            );
          },
        ),
        const SizedBox(height: 12),

        // Area field (for Swiss addresses)
        if (widget.isSwissAddress) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: l10n.area,
                  hintText:
                      'Enter areas separated by commas (e.g., LU, ZH, BE)',
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? appColors.cardColorDark
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: appColors.primaryBlue, width: 2),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      // Initialize dialog state with current selection
                      _selectedAreasInDialog = _areaController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      showDialog(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setDialogState) {
                            return Dialog(
                              backgroundColor: appColors.backgroundLight,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableHeight = constraints.maxHeight;

                                  return Container(
                                    constraints: BoxConstraints(
                                      maxHeight: availableHeight * 0.90,
                                      minHeight: 200,
                                      maxWidth:
                                          120, // Reduced from 150 to 120 to make it more compact
                                    ),
                                    padding: const EdgeInsets.all(
                                        10.0), // 10px padding
                                    decoration: BoxDecoration(
                                      color: appColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left:
                                                      6.0), // Align with codes
                                              child: Text(
                                                'Areas',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: appColors.textColor,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              icon: Icon(
                                                Icons.close,
                                                color: appColors.textColor,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _areas.length,
                                            itemBuilder: (context, index) {
                                              final area = _areas[index];
                                              final isSelected =
                                                  _selectedAreasInDialog
                                                      .contains(area);

                                              return Column(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setDialogState(() {
                                                        if (isSelected) {
                                                          _selectedAreasInDialog
                                                              .remove(area);
                                                        } else {
                                                          _selectedAreasInDialog
                                                              .add(area);
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal:
                                                            6, // Reduced from 8 to 6
                                                        vertical:
                                                            4, // Reduced from 6 to 4
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? appColors
                                                                .primaryBlue
                                                                .withValues(
                                                                    alpha: 0.2)
                                                            : Colors
                                                                .transparent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          if (isSelected)
                                                            Icon(
                                                              Icons.check,
                                                              color: appColors
                                                                  .primaryBlue,
                                                              size: 16,
                                                            )
                                                          else
                                                            SizedBox(width: 16),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(
                                                            area,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? appColors
                                                                      .primaryBlue
                                                                  : appColors
                                                                      .textColor,
                                                              fontWeight: isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .normal,
                                                              fontSize:
                                                                  16, // Increased from 15 to 16
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (index <
                                                      _areas.length -
                                                          1) // Add spacing between items
                                                    const SizedBox(
                                                        height:
                                                            2), // 2px spacing between codes
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                // Apply the selection when OK is pressed
                                                _areaController.text =
                                                    _selectedAreasInDialog
                                                        .join(', ');
                                                _updateAddressData();
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: appColors.primaryBlue,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_drop_down),
                  ),
                ),
                style: TextStyle(color: appColors.textColor),
                onChanged: (value) {
                  _updateAddressData();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // City field
        if (widget.isSwissAddress) ...[
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              // Filter cities based on selected areas
              final citiesForAreas =
                  _getCitiesForMultipleAreas(_areaController.text);

              return citiesForAreas.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            initialValue: TextEditingValue(text: _cityController.text),
            onSelected: (String selection) {
              _onCityChanged(selection);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? appColors.cardColorDark
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: appColors.primaryBlue, width: 2),
                  ),
                ),
                style: TextStyle(color: appColors.textColor),
                onChanged: (value) {
                  _cityController.text = value;
                  _updateAddressData();
                },
              );
            },
          ),
        ] else ...[
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: l10n.city,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? appColors.cardColorDark
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
              ),
            ),
            style: TextStyle(color: appColors.textColor),
            onChanged: (value) => _updateAddressData(),
          ),
        ],
        const SizedBox(height: 12),

        // Post code field
        if (widget.isSwissAddress) ...[
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              // Filter post codes based on selected area and city
              List<String> availablePostCodes = [];
              if (_areaController.text.isNotEmpty &&
                  _cityController.text.isNotEmpty) {
                availablePostCodes = _getPostCodesForMultipleAreasAndCity(
                    _areaController.text, _cityController.text);
              } else if (_areaController.text.isNotEmpty) {
                // If only area is selected, show all post codes for that area
                availablePostCodes = _swissData
                    .where((item) => item['area'] == _areaController.text)
                    .expand((item) => item['postCodes'] as List)
                    .cast<String>()
                    .toSet()
                    .toList();
              } else {
                // If no area selected, show all post codes
                availablePostCodes = _swissData
                    .expand((item) => item['postCodes'] as List)
                    .cast<String>()
                    .toSet()
                    .toList();
              }

              return availablePostCodes.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            initialValue: TextEditingValue(text: _postCodeController.text),
            onSelected: (String selection) {
              _onPostCodeChanged(selection);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: l10n.postCode,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? appColors.cardColorDark
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.black26,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: appColors.primaryBlue, width: 2),
                  ),
                ),
                style: TextStyle(color: appColors.textColor),
                onChanged: (value) {
                  _postCodeController.text = value;
                  _updateAddressData();
                },
              );
            },
          ),
        ] else ...[
          TextFormField(
            controller: _postCodeController,
            decoration: InputDecoration(
              labelText: l10n.postCode,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? appColors.cardColorDark
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
              ),
            ),
            style: TextStyle(color: appColors.textColor),
            onChanged: (value) => _updateAddressData(),
          ),
        ],
        if (widget.showStreetAndNumber) ...[
          const SizedBox(height: 12),

          // Street field
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: l10n.street,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? appColors.cardColorDark
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
              ),
            ),
            style: TextStyle(color: appColors.textColor),
            onChanged: (value) => _updateAddressData(),
          ),
          const SizedBox(height: 12),

          // Street number field
          TextFormField(
            controller: _numberController,
            decoration: InputDecoration(
              labelText: l10n.streetNumber,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? appColors.cardColorDark
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
              ),
            ),
            style: TextStyle(color: appColors.textColor),
            onChanged: (value) => _updateAddressData(),
          ),
        ],
      ],
    );

    if (!widget.showCard) {
      return fields;
    }
    return Card(
      color: appColors.backgroundDark,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: fields,
      ),
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _postCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}
