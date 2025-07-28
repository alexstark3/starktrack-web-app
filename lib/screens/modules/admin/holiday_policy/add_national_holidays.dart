import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:starktrack/services/holiday_api_service.dart';
import 'package:starktrack/services/holiday_translation_service.dart';

// Service to add national holidays using API
class NationalHolidayService {
  // Add national holidays from API for any country
  static Future<List<Map<String, dynamic>>> getNationalHolidaysFromApi({
    required String countryCode,
    required int year,
    required int color,
  }) async {
    try {
      final holidays = await HolidayApiService.getHolidaysFromNagerApi(
        countryCode: countryCode,
        year: year,
      );

      // Filter for national holidays only
      final nationalHolidays =
          holidays.where((holiday) => holiday.isNational).toList();

      return nationalHolidays.map((holiday) {
        // Get translated name for English and German
        final translatedNameEn =
            HolidayTranslationService.getTranslatedHolidayName(
                holiday.name, 'en');
        final translatedNameDe =
            HolidayTranslationService.getTranslatedHolidayName(
                holiday.name, 'de');

        return {
          'name': '${holiday.name} (National)',
          'nameEn': translatedNameEn,
          'nameDe': translatedNameDe,
          'date': holiday.date,
          'color': color,
          'repeatAnnually': holiday.toHolidayConfig().repeatAnnually,
          'isNational': true,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching national holidays: $e');
    }
  }

  // Add national holidays to Firestore
  static Future<void> addNationalHolidaysToFirestore({
    required String companyId,
    required String countryCode,
    required int year,
    required int color,
  }) async {
    try {
      final holidays = await getNationalHolidaysFromApi(
        countryCode: countryCode,
        year: year,
        color: color,
      );

      for (final holiday in holidays) {
        final policyData = {
          'name': holiday['name'],
          'nameEn': holiday['nameEn'],
          'nameDe': holiday['nameDe'],
          'color': holiday['color'],
          'assignTo': 'all',
          'region': {
            'country': countryCode,
            'area': [],
            'city': '',
            'postCode': '',
          },
          'period': {
            'start': Timestamp.fromDate(holiday['date']),
            'end': Timestamp.fromDate(holiday['date']),
          },
          'repeatAnnually': holiday['repeatAnnually'],
          'paid': true,
          'isNational': true,
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
      throw Exception('Error adding national holidays: $e');
    }
  }
}
