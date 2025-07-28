import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/holiday_database.dart';

class HolidayApiService {
  // Free holiday API endpoints
  static const String _nagerApiBase = 'https://date.nager.at/api/v3';
  static const String _holidayApiBase = 'https://holidayapi.com/v1/holidays';

  // Get holidays from Nager API (free, reliable)
  static Future<List<ApiHoliday>> getHolidaysFromNagerApi({
    required String countryCode,
    required int year,
  }) async {
    try {
      final url = '$_nagerApiBase/PublicHolidays/$year/$countryCode';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ApiHoliday.fromNagerJson(json)).toList();
      } else {
        throw Exception('Failed to load holidays: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching holidays: $e');
    }
  }

  // Get holidays from HolidayAPI (requires API key)
  static Future<List<ApiHoliday>> getHolidaysFromHolidayApi({
    required String countryCode,
    required int year,
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(_holidayApiBase).replace(queryParameters: {
        'country': countryCode,
        'year': year.toString(),
        'key': apiKey,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> holidays = data['holidays'] ?? [];
        return holidays
            .map((json) => ApiHoliday.fromHolidayApiJson(json))
            .toList();
      } else {
        throw Exception('Failed to load holidays: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching holidays: $e');
    }
  }

  // Get available countries from Nager API
  static Future<List<CountryInfo>> getAvailableCountries() async {
    try {
      final url = '$_nagerApiBase/AvailableCountries';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CountryInfo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }
}

// Data models for API responses
class ApiHoliday {
  final String name;
  final DateTime date;
  final String countryCode;
  final List<String>? regions;
  final bool isNational;
  final String? type;

  ApiHoliday({
    required this.name,
    required this.date,
    required this.countryCode,
    this.regions,
    required this.isNational,
    this.type,
  });

  factory ApiHoliday.fromNagerJson(Map<String, dynamic> json) {
    return ApiHoliday(
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      countryCode: json['countryCode'] ?? '',
      regions:
          json['counties'] != null ? List<String>.from(json['counties']) : null,
      isNational: json['global'] == true,
      type: json['types']?.first,
    );
  }

  factory ApiHoliday.fromHolidayApiJson(Map<String, dynamic> json) {
    return ApiHoliday(
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      countryCode: json['country'] ?? '',
      regions:
          json['states'] != null ? List<String>.from(json['states']) : null,
      isNational: json['states'] == null || (json['states'] as List).isEmpty,
      type: json['type'],
    );
  }

  // Convert to our internal HolidayConfig format
  HolidayConfig toHolidayConfig() {
    return HolidayConfig(
      name: name,
      date: date,
      country: countryCode,
      regions: regions,
      type: isNational ? HolidayType.national : HolidayType.area,
      repeatAnnually: _isFixedDate(),
      color: isNational
          ? 0xFF4CAF50
          : 0xFF2196F3, // Green for national, blue for area
    );
  }

  bool _isFixedDate() {
    // Check if it's a fixed date holiday (like Christmas, New Year)
    final fixedHolidays = [
      'New Year\'s Day',
      'Christmas Day',
      'Labour Day',
      'Independence Day',
    ];
    return fixedHolidays.any((holiday) => name.contains(holiday));
  }
}

class CountryInfo {
  final String name;
  final String code;
  final List<String> regions;

  CountryInfo({
    required this.name,
    required this.code,
    required this.regions,
  });

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      name: json['name'] ?? '',
      code: json['countryCode'] ?? '',
      regions:
          json['regions'] != null ? List<String>.from(json['regions']) : [],
    );
  }
}

// HolidayConfig and HolidayType are now imported from holiday_database.dart
