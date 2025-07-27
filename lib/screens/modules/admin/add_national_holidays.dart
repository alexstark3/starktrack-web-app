import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/holiday_api_service.dart';

// Swiss Holiday Calculator for National Holidays
class SwissNationalHolidayCalculator {
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

  // Get all Swiss National Holidays for a given year
  static List<Map<String, dynamic>> getSwissNationalHolidays(int year) {
    final easter = calculateEaster(year);
    final goodFriday = easter.subtract(Duration(days: 2));
    final easterMonday = easter.add(Duration(days: 1));
    final ascension = easter.add(Duration(days: 39));
    final whitMonday = easter.add(Duration(days: 50));

    final holidays = [
      {
        'name': 'New Year\'s Day (National)',
        'date': DateTime(year, 1, 1),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'Berchtold\'s Day (National)',
        'date': DateTime(year, 1, 2),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'Good Friday (National)',
        'date': goodFriday,
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': false, // Variable date (Easter-based)
      },
      {
        'name': 'Easter Monday (National)',
        'date': easterMonday,
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': false, // Variable date (Easter-based)
      },
      {
        'name': 'Labour Day (National)',
        'date': DateTime(year, 5, 1),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'Ascension Day (National)',
        'date': ascension,
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': false, // Variable date (Easter-based)
      },
      {
        'name': 'Whit Monday (National)',
        'date': whitMonday,
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': false, // Variable date (Easter-based)
      },
      {
        'name': 'Swiss National Day (National)',
        'date': DateTime(year, 8, 1),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'Assumption Day (National)',
        'date': DateTime(year, 8, 15),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'All Saints\' Day (National)',
        'date': DateTime(year, 11, 1),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'Christmas Day (National)',
        'date': DateTime(year, 12, 25),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
      {
        'name': 'St. Stephen\'s Day (National)',
        'date': DateTime(year, 12, 26),
        'color': 0xFF4CAF50, // Green color
        'repeatAnnually': true, // Fixed date
      },
    ];

    holidays.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return holidays;
  }

  // Get national holidays from API for any country
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

      // Convert to the format expected by the holiday policy system
      return nationalHolidays
          .map((holiday) => {
                'name': '${holiday.name} (National)',
                'date': holiday.date,
                'color': color,
                'repeatAnnually':
                    holiday.isNational, // National holidays typically repeat
              })
          .toList();
    } catch (e) {
      print('Error fetching national holidays from API: $e');
      return [];
    }
  }

  // Add national holidays to Firestore
  static Future<int> addNationalHolidaysToFirestore({
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

      int addedCount = 0;
      for (final holiday in holidays) {
        try {
          final policyData = {
            'name': holiday['name'],
            'color': holiday['color'],
            'assignTo': 'all',
            'region': {
              'country': countryCode == 'CH' ? 'Switzerland' : countryCode,
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
      print('Error adding national holidays: $e');
      return 0;
    }
  }
}

void main() async {
  // Configuration - CHANGE THESE VALUES
  const String companyId =
      'YOUR_COMPANY_ID'; // Replace with your actual company ID
  const int year = 2025; // Change year as needed

  // Get Swiss National Holidays for the specified year
  final holidays =
      SwissNationalHolidayCalculator.getSwissNationalHolidays(year);

  // Summary of holidays to be added
  final fixedDateHolidays =
      holidays.where((h) => h['repeatAnnually'] == true).length;
  final variableDateHolidays =
      holidays.where((h) => h['repeatAnnually'] == false).length;

  // Add holidays to Firestore
  try {
    int addedCount = 0;

    for (final holiday in holidays) {
      try {
        final policyData = {
          'name': holiday['name'],
          'color': holiday['color'],
          'assignTo': 'all',
          'region': {
            'country': 'Switzerland',
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
            .doc(companyId)
            .collection('holiday_policies')
            .add(policyData);

        addedCount++;
      } catch (e) {
        // Log error but continue with other holidays
        print('Error adding ${holiday['name']}: $e');
      }
    }

    // Success message
    print(
        '✅ Successfully added $addedCount Swiss National Holidays for $year!');
    print(
        '📊 Summary: $fixedDateHolidays fixed-date holidays, $variableDateHolidays variable-date holidays');
  } catch (e) {
    print('❌ Error: $e');
  }
}
