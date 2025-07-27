// Holiday Database for Multiple Countries
class HolidayDatabase {
  // Country configuration
  static const Map<String, CountryConfig> countries = {
    'CH': CountryConfig(
      name: 'Switzerland',
      code: 'CH',
      regions: [
        'ZH',
        'BE',
        'LU',
        'UR',
        'SZ',
        'OW',
        'NW',
        'GL',
        'ZG',
        'FR',
        'SO',
        'BS',
        'BL',
        'SH',
        'AR',
        'AI',
        'SG',
        'GR',
        'AG',
        'TG',
        'TI',
        'VD',
        'VS',
        'NE',
        'GE',
        'JU'
      ],
    ),
    'DE': CountryConfig(
      name: 'Germany',
      code: 'DE',
      regions: [
        'BW',
        'BY',
        'BE',
        'BB',
        'HB',
        'HH',
        'HE',
        'MV',
        'NI',
        'NW',
        'RP',
        'SL',
        'SN',
        'ST',
        'SH',
        'TH'
      ],
    ),
    'AT': CountryConfig(
      name: 'Austria',
      code: 'AT',
      regions: ['B', 'K', 'NÖ', 'OÖ', 'S', 'ST', 'T', 'V', 'W'],
    ),
    'FR': CountryConfig(
      name: 'France',
      code: 'FR',
      regions: [
        'ARA',
        'BFC',
        'BRE',
        'CVL',
        'COR',
        'GES',
        'HDF',
        'IDF',
        'NOR',
        'NAQ',
        'OCC',
        'PDL',
        'PAC'
      ],
    ),
    'IT': CountryConfig(
      name: 'Italy',
      code: 'IT',
      regions: [
        'ABR',
        'BAS',
        'CAL',
        'CAM',
        'EMR',
        'FVG',
        'LAZ',
        'LIG',
        'LOM',
        'MAR',
        'MOL',
        'PAB',
        'PIE',
        'PUG',
        'SAR',
        'SIC',
        'TOS',
        'TAA',
        'UMB',
        'VDA',
        'VEN'
      ],
    ),
  };

  // Get national holidays for any country
  static List<HolidayConfig> getNationalHolidays(String countryCode, int year) {
    switch (countryCode.toUpperCase()) {
      case 'CH':
        return _getSwissNationalHolidays(year);
      case 'DE':
        return _getGermanNationalHolidays(year);
      case 'AT':
        return _getAustrianNationalHolidays(year);
      case 'FR':
        return _getFrenchNationalHolidays(year);
      case 'IT':
        return _getItalianNationalHolidays(year);
      default:
        return [];
    }
  }

  // Get area holidays for any country
  static List<HolidayConfig> getAreaHolidays(String countryCode, int year) {
    switch (countryCode.toUpperCase()) {
      case 'CH':
        return _getSwissAreaHolidays(year);
      case 'DE':
        return _getGermanAreaHolidays(year);
      case 'AT':
        return _getAustrianAreaHolidays(year);
      case 'FR':
        return _getFrenchAreaHolidays(year);
      case 'IT':
        return _getItalianAreaHolidays(year);
      default:
        return [];
    }
  }

  // Swiss National Holidays (existing logic)
  static List<HolidayConfig> _getSwissNationalHolidays(int year) {
    final easter = DateCalculator.calculateEaster(year);
    final goodFriday = easter.subtract(Duration(days: 2));
    final easterMonday = easter.add(Duration(days: 1));
    final ascension = easter.add(Duration(days: 39));
    final whitMonday = easter.add(Duration(days: 50));

    return [
      HolidayConfig(
        name: 'New Year\'s Day',
        date: DateTime(year, 1, 1),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Berchtold\'s Day',
        date: DateTime(year, 1, 2),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Good Friday',
        date: goodFriday,
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Easter Monday',
        date: easterMonday,
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Labour Day',
        date: DateTime(year, 5, 1),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Ascension Day',
        date: ascension,
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Whit Monday',
        date: whitMonday,
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Swiss National Day',
        date: DateTime(year, 8, 1),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Assumption Day',
        date: DateTime(year, 8, 15),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'All Saints\' Day',
        date: DateTime(year, 11, 1),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Christmas Day',
        date: DateTime(year, 12, 25),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'St. Stephen\'s Day',
        date: DateTime(year, 12, 26),
        country: 'CH',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
    ];
  }

  // Swiss Area Holidays (existing logic)
  static List<HolidayConfig> _getSwissAreaHolidays(int year) {
    return [
      HolidayConfig(
        name: 'Sechseläuten',
        date: DateCalculator.thirdMondayOfMonth(year, 4),
        country: 'CH',
        region: 'ZH',
        city: 'Zürich',
        type: HolidayType.area,
        repeatAnnually: true,
        color: 0xFF2196F3,
      ),
      HolidayConfig(
        name: 'Jeûne Genevois',
        date: DateCalculator.thursdayAfterFirstSundayOfSeptember(year),
        country: 'CH',
        region: 'GE',
        city: 'Genève',
        type: HolidayType.area,
        repeatAnnually: true,
        color: 0xFF2196F3,
      ),
      HolidayConfig(
        name: 'Basler Fasnacht',
        date: DateCalculator.mondayAfterAshWednesday(year),
        country: 'CH',
        region: 'BS',
        city: 'Basel',
        type: HolidayType.area,
        repeatAnnually: true,
        color: 0xFF2196F3,
      ),
    ];
  }

  // German National Holidays
  static List<HolidayConfig> _getGermanNationalHolidays(int year) {
    final easter = DateCalculator.calculateEaster(year);
    final goodFriday = easter.subtract(Duration(days: 2));
    final easterMonday = easter.add(Duration(days: 1));
    final ascension = easter.add(Duration(days: 39));
    final whitMonday = easter.add(Duration(days: 50));

    return [
      HolidayConfig(
        name: 'New Year\'s Day',
        date: DateTime(year, 1, 1),
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Good Friday',
        date: goodFriday,
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Easter Monday',
        date: easterMonday,
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Labour Day',
        date: DateTime(year, 5, 1),
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Ascension Day',
        date: ascension,
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Whit Monday',
        date: whitMonday,
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: false,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'German Unity Day',
        date: DateTime(year, 10, 3),
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Christmas Day',
        date: DateTime(year, 12, 25),
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
      HolidayConfig(
        name: 'Boxing Day',
        date: DateTime(year, 12, 26),
        country: 'DE',
        type: HolidayType.national,
        repeatAnnually: true,
        color: 0xFF4CAF50,
      ),
    ];
  }

  // German Area Holidays
  static List<HolidayConfig> _getGermanAreaHolidays(int year) {
    return [
      HolidayConfig(
        name: 'Epiphany',
        date: DateTime(year, 1, 6),
        country: 'DE',
        regions: ['BW', 'BY', 'ST'],
        type: HolidayType.area,
        repeatAnnually: true,
        color: 0xFF2196F3,
      ),
      HolidayConfig(
        name: 'Corpus Christi',
        date: DateCalculator.corpusChristi(year),
        country: 'DE',
        regions: ['BW', 'BY', 'HE', 'NW', 'RP', 'SL'],
        type: HolidayType.area,
        repeatAnnually: false,
        color: 0xFF2196F3,
      ),
    ];
  }

  // Placeholder methods for other countries
  static List<HolidayConfig> _getAustrianNationalHolidays(int year) => [];
  static List<HolidayConfig> _getAustrianAreaHolidays(int year) => [];
  static List<HolidayConfig> _getFrenchNationalHolidays(int year) => [];
  static List<HolidayConfig> _getFrenchAreaHolidays(int year) => [];
  static List<HolidayConfig> _getItalianNationalHolidays(int year) => [];
  static List<HolidayConfig> _getItalianAreaHolidays(int year) => [];
}

// Data Models
class CountryConfig {
  final String name;
  final String code;
  final List<String> regions;

  const CountryConfig({
    required this.name,
    required this.code,
    required this.regions,
  });
}

class HolidayConfig {
  final String name;
  final DateTime date;
  final String country;
  final String? region;
  final List<String>? regions;
  final String? city;
  final HolidayType type;
  final bool repeatAnnually;
  final int color;

  HolidayConfig({
    required this.name,
    required this.date,
    required this.country,
    this.region,
    this.regions,
    this.city,
    required this.type,
    required this.repeatAnnually,
    required this.color,
  });
}

enum HolidayType {
  national,
  area,
}

// Date calculation utilities
class DateCalculator {
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

  static DateTime corpusChristi(int year) {
    final easter = calculateEaster(year);
    return easter
        .add(Duration(days: 60)); // Corpus Christi (60 days after Easter)
  }
}
