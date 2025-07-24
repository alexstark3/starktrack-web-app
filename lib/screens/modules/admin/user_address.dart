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

  const UserAddress({
    super.key,
    required this.addressData,
    required this.onAddressChanged,
    required this.title,
    this.isSwissAddress = true,
    this.showCard = true,
  });

  @override
  State<UserAddress> createState() => _UserAddressState();
}

class _UserAddressState extends State<UserAddress> {
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _swissData = [];
  List<String> _areas = [];
  
  // Controllers for form fields
  late TextEditingController _countryController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _postCodeController;
  late TextEditingController _streetController;
  late TextEditingController _streetNumberController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _countryController = TextEditingController(text: widget.addressData['country'] ?? (widget.isSwissAddress ? 'Switzerland' : ''));
    _areaController = TextEditingController(text: widget.addressData['area'] ?? '');
    _cityController = TextEditingController(text: widget.addressData['city'] ?? '');
    _postCodeController = TextEditingController(text: widget.addressData['postCode'] ?? '');
    _streetController = TextEditingController(text: widget.addressData['street'] ?? '');
    _streetNumberController = TextEditingController(text: widget.addressData['streetNumber'] ?? '');
  }

  Future<void> _loadData() async {
    await _loadCountries();
    if (widget.isSwissAddress) {
      await _loadSwissData();
    }
  }

  Future<void> _loadCountries() async {
    try {
      final jsonString = await rootBundle.loadString('lib/data/world_countries.json');
      final data = json.decode(jsonString);
      _countries = List<Map<String, dynamic>>.from(data);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  Future<void> _loadSwissData() async {
    try {
      final jsonString = await rootBundle.loadString('lib/data/swiss_cities.json');
      final data = json.decode(jsonString);
      _swissData = List<Map<String, dynamic>>.from(data);
      
      // Extract unique areas
      final areas = _swissData.map((item) => item['area'] as String).toSet().toList();
      
      setState(() {
        _areas = areas..sort();
      });
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

  List<String> _getPostCodesForCity(String area, String city) {
    final cityData = _swissData.firstWhere(
      (item) => item['area'] == area && item['city'] == city,
      orElse: () => {'postCodes': []},
    );
    return List<String>.from(cityData['postCodes'] ?? [])..sort();
  }

  String? _getCityForPostCode(String postCode) {
    final cityData = _swissData.firstWhere(
      (item) => (item['postCodes'] as List).contains(postCode),
      orElse: () => {'city': '', 'area': ''},
    );
    return cityData['city'] as String?;
  }

  String? _getAreaForPostCode(String postCode) {
    final cityData = _swissData.firstWhere(
      (item) => (item['postCodes'] as List).contains(postCode),
      orElse: () => {'city': '', 'area': ''},
    );
    return cityData['area'] as String?;
  }

  void _updateAddressData() {
    final newAddressData = {
      'country': _countryController.text,
      'area': _areaController.text,
      'city': _cityController.text,
      'postCode': _postCodeController.text,
      'street': _streetController.text,
      'streetNumber': _streetNumberController.text,
    };
    
    widget.onAddressChanged(newAddressData);
  }

  void _onAreaChanged(String? value) {
    if (value != null) {
      setState(() {
        _areaController.text = value;
        _cityController.clear();
        _postCodeController.clear();
      });
      _updateAddressData();
    }
  }

  void _onCityChanged(String? value) {
    if (value != null) {
      setState(() {
        _cityController.text = value;
        final postCodes = _getPostCodesForCity(_areaController.text, value);
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
        final city = _getCityForPostCode(value);
        final area = _getAreaForPostCode(value);
        if (city != null && area != null) {
          _areaController.text = area;
          _cityController.text = city;
        }
      });
      _updateAddressData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

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
                  return _countries.map((c) => c['name'] as String).where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                initialValue: TextEditingValue(text: _countryController.text),
                onSelected: (String selection) {
                  setState(() {
                    _countryController.text = selection;
                  });
                  _updateAddressData();
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: l10n.country,
                      filled: true,
                      fillColor: appColors.lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appColors.darkGray, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appColors.darkGray, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
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
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _areas.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  initialValue: TextEditingValue(text: _areaController.text),
                  onSelected: (String selection) {
                    _onAreaChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: l10n.area,
                        filled: true,
                        fillColor: appColors.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
                        ),
                      ),
                      style: TextStyle(color: appColors.textColor),
                      onChanged: (value) {
                        _areaController.text = value;
                        _updateAddressData();
                      },
                    );
                  },
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
                    // Filter cities based on selected area
                    final citiesForArea = _areaController.text.isNotEmpty 
                        ? _getCitiesForArea(_areaController.text)
                        : _swissData.map((item) => item['city'] as String).toSet().toList();
                    
                    return citiesForArea.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  initialValue: TextEditingValue(text: _cityController.text),
                  onSelected: (String selection) {
                    _onCityChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: l10n.city,
                        filled: true,
                        fillColor: appColors.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
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
                    fillColor: appColors.lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.darkGray, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.darkGray, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    if (_areaController.text.isNotEmpty && _cityController.text.isNotEmpty) {
                      availablePostCodes = _getPostCodesForCity(_areaController.text, _cityController.text);
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
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  initialValue: TextEditingValue(text: _postCodeController.text),
                  onSelected: (String selection) {
                    _onPostCodeChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: l10n.postCode,
                        filled: true,
                        fillColor: appColors.lightGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.darkGray, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
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
                    fillColor: appColors.lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.darkGray, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.darkGray, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
                    ),
                  ),
                  style: TextStyle(color: appColors.textColor),
                  onChanged: (value) => _updateAddressData(),
                ),
              ],
              const SizedBox(height: 12),

              // Street field
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: l10n.street,
                  filled: true,
                  fillColor: appColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.darkGray, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.darkGray, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
                  ),
                ),
                style: TextStyle(color: appColors.textColor),
                onChanged: (value) => _updateAddressData(),
              ),
              const SizedBox(height: 12),

              // Street number field
              TextFormField(
                controller: _streetNumberController,
                decoration: InputDecoration(
                  labelText: l10n.streetNumber,
                  filled: true,
                  fillColor: appColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.darkGray, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.darkGray, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appColors.primaryBlue, width: 2),
                  ),
                ),
                style: TextStyle(color: appColors.textColor),
                onChanged: (value) => _updateAddressData(),
              ),
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
    _streetNumberController.dispose();
    super.dispose();
  }
}
