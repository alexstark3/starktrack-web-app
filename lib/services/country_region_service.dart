import 'dart:convert';
import 'package:flutter/services.dart';

class CountryRegionService {
  static List<CountryData>? _countries;
  static Map<String, List<String>>? _regions;

  // Load countries from world_countries.json
  static Future<List<CountryData>> getCountries() async {
    if (_countries != null) return _countries!;

    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/world_countries.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _countries = jsonList.map((json) => CountryData.fromJson(json)).toList();
      return _countries!;
    } catch (e) {
      throw Exception('Failed to load countries: $e');
    }
  }

  // Load Swiss regions from swiss_cities.json
  static Future<List<String>> getSwissRegions() async {
    if (_regions != null && _regions!['CH'] != null) {
      return _regions!['CH']!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/swiss_cities.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      // Extract unique areas (cantons) from Swiss cities
      final Set<String> areas = {};
      for (final city in jsonList) {
        if (city['area'] != null) {
          areas.add(city['area']);
        }
      }

      final regions = areas.toList()..sort();

      // Cache the regions
      _regions ??= {};
      _regions!['CH'] = regions;

      return regions;
    } catch (e) {
      throw Exception('Failed to load Swiss regions: $e');
    }
  }

  // Get regions for a specific country
  static Future<List<String>> getRegionsForCountry(String countryCode) async {
    // For now, we only have Swiss regions in our database
    // In the future, we can add more countries' regions
    if (countryCode == 'CH') {
      return await getSwissRegions();
    }

    // For other countries, return empty list for now
    // This can be extended when we have more regional data
    return [];
  }

  // Get country name by code
  static Future<String> getCountryName(String countryCode) async {
    final countries = await getCountries();
    final country = countries.firstWhere(
      (c) => c.code == countryCode,
      orElse: () => CountryData(name: countryCode, code: countryCode),
    );
    return country.name;
  }

  // Get country code by name
  static Future<String> getCountryCode(String countryName) async {
    final countries = await getCountries();
    final country = countries.firstWhere(
      (c) => c.name == countryName,
      orElse: () => CountryData(name: countryName, code: countryName),
    );
    return country.code;
  }

  // Get Swiss cities for a specific area (canton)
  static Future<List<SwissCity>> getSwissCitiesForArea(String area) async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/swiss_cities.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final cities = jsonList
          .where((city) => city['area'] == area)
          .map((city) => SwissCity.fromJson(city))
          .toList();

      return cities;
    } catch (e) {
      throw Exception('Failed to load Swiss cities for area $area: $e');
    }
  }

  // Get all Swiss cities
  static Future<List<SwissCity>> getAllSwissCities() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/data/swiss_cities.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final cities = jsonList.map((city) => SwissCity.fromJson(city)).toList();
      return cities;
    } catch (e) {
      throw Exception('Failed to load Swiss cities: $e');
    }
  }
}

class CountryData {
  final String name;
  final String code;

  CountryData({
    required this.name,
    required this.code,
  });

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}

class SwissCity {
  final String area;
  final String city;
  final List<String> postCodes;

  SwissCity({
    required this.area,
    required this.city,
    required this.postCodes,
  });

  factory SwissCity.fromJson(Map<String, dynamic> json) {
    return SwissCity(
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      postCodes: List<String>.from(json['postCodes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'city': city,
      'postCodes': postCodes,
    };
  }
}
