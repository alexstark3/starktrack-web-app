import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/holiday_api_service.dart';

// Area Holiday Configuration
class AreaHolidayConfig {
  final String name;
  final DateTime date;
  final String country;
  final String? area;
  final String? city;
  final String? postCode;
  final bool repeatAnnually;

  AreaHolidayConfig({
    required this.name,
    required this.date,
    required this.country,
    this.area,
    this.city,
    this.postCode,
    this.repeatAnnually = true,
  });
}

// Date calculation utilities
class DateCalculator {
  // Calculate Easter Sunday using Meeus/Jones/Butcher algorithm
  static DateTime calculateEaster(int year) {
    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  static DateTime thirdMondayOfMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final firstMonday =
        firstDay.add(Duration(days: (8 - firstDay.weekday) % 7));
    return firstMonday.add(Duration(days: 14)); // Third Monday
  }

  static DateTime fourthMondayOfMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final firstMonday =
        firstDay.add(Duration(days: (8 - firstDay.weekday) % 7));
    return firstMonday.add(Duration(days: 21)); // Fourth Monday
  }

  static DateTime thursdayAfterFirstSundayOfSeptember(int year) {
    final firstDay = DateTime(year, 9, 1);
    final firstSunday =
        firstDay.add(Duration(days: (7 - firstDay.weekday) % 7));
    return firstSunday.add(Duration(days: 4)); // Thursday after first Sunday
  }

  static DateTime mondayAfterAshWednesday(int year) {
    final easter = calculateEaster(year);
    final ashWednesday = easter.subtract(Duration(days: 46));
    return ashWednesday.add(Duration(days: 5)); // Monday after Ash Wednesday
  }
}

// Get area holidays from API for any country
class AreaHolidayService {
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

      // Filter by selected areas if specified
      List<ApiHoliday> filteredHolidays;
      if (selectedAreas.isNotEmpty && selectedAreas.first != 'all') {
        filteredHolidays = areaHolidays.where((holiday) {
          // Check if holiday applies to any of the selected areas
          return holiday.regions
                  ?.any((region) => selectedAreas.contains(region)) ??
              false;
        }).toList();
      } else {
        filteredHolidays = areaHolidays;
      }

      // Convert to the format expected by the holiday policy system
      return filteredHolidays
          .map((holiday) => {
                'name': '${holiday.name} (Area)',
                'date': holiday.date,
                'color': color,
                'repeatAnnually': true, // Area holidays typically repeat
                'regions': holiday.regions,
              })
          .toList();
    } catch (e) {
      print('Error fetching area holidays from API: $e');
      return [];
    }
  }

  // Add area holidays to Firestore
  static Future<int> addAreaHolidaysToFirestore({
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

      int addedCount = 0;
      for (final holiday in holidays) {
        try {
          final policyData = {
            'name': holiday['name'],
            'color': holiday['color'],
            'assignTo': 'region',
            'region': {
              'country': countryCode == 'CH' ? 'Switzerland' : countryCode,
              'area': holiday['regions'] ?? selectedAreas,
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
              .doc(companyId)
              .collection('holiday_policies')
              .add(policyData);

          addedCount++;
        } catch (e) {
          print('Error adding ${holiday['name']}: $e');
        }
      }

      return addedCount;
    } catch (e) {
      print('Error adding area holidays: $e');
      return 0;
    }
  }
}

// Example Area Holidays - MODIFY THESE AS NEEDED
List<AreaHolidayConfig> getExampleAreaHolidays(int year) {
  return [
    // Example: Zurich area holidays
    AreaHolidayConfig(
      name: 'Sechseläuten',
      date: DateCalculator.thirdMondayOfMonth(year, 4), // Third Monday of April
      country: 'Switzerland',
      area: 'ZH',
      city: 'Zürich',
      repeatAnnually: true,
    ),

    // Example: Geneva area holidays
    AreaHolidayConfig(
      name: 'Jeûne Genevois',
      date: DateCalculator.thursdayAfterFirstSundayOfSeptember(
          year), // Thursday after first Sunday of September
      country: 'Switzerland',
      area: 'GE',
      city: 'Genève',
      repeatAnnually: true,
    ),

    // Example: Basel area holidays
    AreaHolidayConfig(
      name: 'Basler Fasnacht',
      date: DateCalculator.mondayAfterAshWednesday(
          year), // Monday after Ash Wednesday
      country: 'Switzerland',
      area: 'BS',
      city: 'Basel',
      repeatAnnually: true,
    ),

    // Example: Lucerne area holidays
    AreaHolidayConfig(
      name: 'Luzerner Fest',
      date: DateTime(year, 6, 15), // Fixed date - June 15
      country: 'Switzerland',
      area: 'LU',
      city: 'Luzern',
      repeatAnnually: true,
    ),

    // Example: Bern area holidays
    AreaHolidayConfig(
      name: 'Berner Zibelemärit',
      date: DateCalculator.fourthMondayOfMonth(
          year, 11), // Fourth Monday of November
      country: 'Switzerland',
      area: 'BE',
      city: 'Bern',
      repeatAnnually: true,
    ),
  ];
}

void main() async {
  // Configuration - CHANGE THESE VALUES
  const String companyId =
      'YOUR_COMPANY_ID'; // Replace with your actual company ID
  const int year = 2025; // Change year as needed

  // Get area holidays for the specified year
  final areaHolidays = getExampleAreaHolidays(year);

  // Summary of holidays to be added
  final fixedDateHolidays = areaHolidays.where((h) => h.repeatAnnually).length;
  final variableDateHolidays =
      areaHolidays.where((h) => !h.repeatAnnually).length;

  // Add holidays to Firestore
  try {
    int addedCount = 0;

    for (final holiday in areaHolidays) {
      try {
        final policyData = {
          'name': '${holiday.name} (Area)',
          'color': 0xFF2196F3, // Blue color for area holidays
          'assignTo': 'region',
          'region': {
            'country': holiday.country,
            'area': holiday.area != null ? [holiday.area!] : [],
            'city': holiday.city ?? '',
            'postCode': holiday.postCode ?? '',
          },
          'period': {
            'start': Timestamp.fromDate(holiday.date),
            'end': Timestamp.fromDate(holiday.date),
          },
          'repeatAnnually': holiday.repeatAnnually,
          'paid': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('holiday_policies')
            .add(policyData);

        addedCount++;
      } catch (e) {
        // Log error but continue with other holidays
        print('Error adding ${holiday.name}: $e');
      }
    }

    // Success message
    print('✅ Successfully added $addedCount Swiss Area Holidays for $year!');
    print(
        '📊 Summary: $fixedDateHolidays fixed-date holidays, $variableDateHolidays variable-date holidays');
  } catch (e) {
    print('❌ Error: $e');
  }
}
