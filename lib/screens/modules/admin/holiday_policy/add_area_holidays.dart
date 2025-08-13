import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starktrack/services/holiday_api_service.dart';
import 'package:starktrack/services/holiday_translation_service.dart';

// Service to add area holidays using API
class AreaHolidayService {
  // Get area holidays from API for any country
  static Future<List<Map<String, dynamic>>> getAreaHolidaysFromApi({
    required String countryCode,
    required int year,
    required List<String> selectedAreas,
    required int color,
  }) async {
    try {
      final holidays = await HolidayApiService.getHolidaysFromNagerApi(
        countryCode: countryCode,
        year: year,
      );

      // Filter for area holidays only (non-national)
      final areaHolidays =
          holidays.where((holiday) => !holiday.isNational).toList();

      // debug logs removed

      // Filter by selected areas if specified
      List<ApiHoliday> filteredHolidays;
      if (selectedAreas.isNotEmpty && selectedAreas.first != 'all') {
        filteredHolidays = areaHolidays.where((holiday) {
          // Check if holiday applies to any of the selected areas
          // Simple direct match since all regions are now in the same format
          return holiday.regions
                  ?.any((region) => selectedAreas.contains(region)) ??
              false;
        }).toList();
      } else {
        // If no specific areas selected, show all area holidays
        filteredHolidays = areaHolidays;
      }

      // Debug logging
      // debug logs removed

      // Show which holidays match the selected areas
      if (selectedAreas.isNotEmpty && selectedAreas.first != 'all') {
        // debug logs removed
      }

      return filteredHolidays.map((holiday) {
        // Get translated name for English and German
        final translatedNameEn =
            HolidayTranslationService.getTranslatedHolidayName(
                holiday.name, 'en');
        final translatedNameDe =
            HolidayTranslationService.getTranslatedHolidayName(
                holiday.name, 'de');

        return {
          'name': '${holiday.name} (Area)',
          'nameEn': translatedNameEn,
          'nameDe': translatedNameDe,
          'date': holiday.date,
          'color': color,
          'regions': holiday.regions ?? [],
          'repeatAnnually': holiday.toHolidayConfig().repeatAnnually,
          'isNational': false,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching area holidays: $e');
    }
  }

  // Add area holidays to Firestore
  static Future<void> addAreaHolidaysToFirestore({
    required String companyId,
    required String countryCode,
    required int year,
    required List<String> selectedAreas,
    required int color,
  }) async {
    try {
      final holidays = await getAreaHolidaysFromApi(
        countryCode: countryCode,
        year: year,
        selectedAreas: selectedAreas,
        color: color,
      );

      for (final holiday in holidays) {
        final policyData = {
          'name': holiday['name'],
          'nameEn': holiday['nameEn'],
          'nameDe': holiday['nameDe'],
          'color': holiday['color'],
          'assignTo': 'region',
          'region': {
            'country': countryCode,
            'area': holiday['regions'], // Already cleaned without CH- prefix
            'city': '',
            'postCode': '',
          },
          'period': {
            'start': Timestamp.fromDate(holiday['date']),
            'end': Timestamp.fromDate(holiday['date']),
          },
          'repeatAnnually': holiday['repeatAnnually'],
          'paid': true,
          'isNational': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('holiday_policies')
            .add(policyData);
      }
    } catch (e) {
      throw Exception('Error adding area holidays: $e');
    }
  }
}
