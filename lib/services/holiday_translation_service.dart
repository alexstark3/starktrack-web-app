import 'package:starktrack/l10n/app_localizations.dart';

class HolidayTranslationService {
  // Translation mapping for common holiday names
  static final Map<String, Map<String, String>> _holidayTranslations = {
    'en': {
      'New Year\'s Day': 'New Year\'s Day',
      'Christmas Day': 'Christmas Day',
      'Labour Day': 'Labour Day',
      'Independence Day': 'Independence Day',
      'Easter Sunday': 'Easter Sunday',
      'Good Friday': 'Good Friday',
      'Easter Monday': 'Easter Monday',
      'Ascension Day': 'Ascension Day',
      'Whit Monday': 'Whit Monday',
      'Corpus Christi': 'Corpus Christi',
      'Assumption Day': 'Assumption Day',
      'All Saints\' Day': 'All Saints\' Day',
      'Immaculate Conception': 'Immaculate Conception',
      'Boxing Day': 'Boxing Day',
      'St. Stephen\'s Day': 'St. Stephen\'s Day',
      'Epiphany': 'Epiphany',
      'Carnival Monday': 'Carnival Monday',
      'Carnival Tuesday': 'Carnival Tuesday',
      'Ash Wednesday': 'Ash Wednesday',
      'Palm Sunday': 'Palm Sunday',
      'Maundy Thursday': 'Maundy Thursday',
      'Holy Saturday': 'Holy Saturday',
      'Pentecost': 'Pentecost',
      'Trinity Sunday': 'Trinity Sunday',
      'Feast of the Sacred Heart': 'Feast of the Sacred Heart',
      'St. Peter and St. Paul': 'St. Peter and St. Paul',
      'National Day': 'National Day',
      'Victory Day': 'Victory Day',
      'Armistice Day': 'Armistice Day',
      'Remembrance Day': 'Remembrance Day',
      'Veterans Day': 'Veterans Day',
      'Memorial Day': 'Memorial Day',
      'Thanksgiving Day': 'Thanksgiving Day',
      'Martin Luther King Jr. Day': 'Martin Luther King Jr. Day',
      'Presidents\' Day': 'Presidents\' Day',
      'Columbus Day': 'Columbus Day',
      // Swiss holidays
      'Swiss National Day': 'Swiss National Day',
      'Berchtoldstag': 'Berchtoldstag',
      'Näfelser Fahrt': 'Näfelser Fahrt',
      'Sechseläuten': 'Sechseläuten',
      'Geneva Fast': 'Geneva Fast',
      'Jura Independence Day': 'Jura Independence Day',
      'Neuchâtel Independence Day': 'Neuchâtel Independence Day',
      'Valais Independence Day': 'Valais Independence Day',
    },
    'de': {
      'New Year\'s Day': 'Neujahr',
      'Christmas Day': 'Weihnachten',
      'Labour Day': 'Tag der Arbeit',
      'Independence Day': 'Unabhängigkeitstag',
      'Easter Sunday': 'Ostersonntag',
      'Good Friday': 'Karfreitag',
      'Easter Monday': 'Ostermontag',
      'Ascension Day': 'Christi Himmelfahrt',
      'Whit Monday': 'Pfingstmontag',
      'Corpus Christi': 'Fronleichnam',
      'Assumption Day': 'Mariä Himmelfahrt',
      'All Saints\' Day': 'Allerheiligen',
      'Immaculate Conception': 'Mariä Empfängnis',
      'Boxing Day': 'Stephanstag',
      'St. Stephen\'s Day': 'Stephanstag',
      'Epiphany': 'Heilige Drei Könige',
      'Carnival Monday': 'Rosenmontag',
      'Carnival Tuesday': 'Faschingsdienstag',
      'Ash Wednesday': 'Aschermittwoch',
      'Palm Sunday': 'Palmsonntag',
      'Maundy Thursday': 'Gründonnerstag',
      'Holy Saturday': 'Karsamstag',
      'Pentecost': 'Pfingsten',
      'Trinity Sunday': 'Trinitatis',
      'Feast of the Sacred Heart': 'Herz-Jesu-Fest',
      'St. Peter and St. Paul': 'Peter und Paul',
      'National Day': 'Nationalfeiertag',
      'Victory Day': 'Tag des Sieges',
      'Armistice Day': 'Waffenstillstandstag',
      'Remembrance Day': 'Gedenktag',
      'Veterans Day': 'Veteranentag',
      'Memorial Day': 'Gedenktag',
      'Thanksgiving Day': 'Erntedankfest',
      'Martin Luther King Jr. Day': 'Martin Luther King Jr. Tag',
      'Presidents\' Day': 'Präsidententag',
      'Columbus Day': 'Kolumbustag',
      // Swiss holidays in German
      'Swiss National Day': 'Schweizer Bundesfeiertag',
      'Berchtoldstag': 'Berchtoldstag',
      'Näfelser Fahrt': 'Näfelser Fahrt',
      'Sechseläuten': 'Sechseläuten',
      'Geneva Fast': 'Genfer Bettag',
      'Jura Independence Day': 'Unabhängigkeitstag vom Jura',
      'Neuchâtel Independence Day': 'Neuenburger Unabhängigkeitstag',
      'Valais Independence Day': 'Walliser Unabhängigkeitstag',
    },
  };

  // Get translated holiday name
  static String getTranslatedHolidayName(
      String englishName, String languageCode) {
    final translations = _holidayTranslations[languageCode];
    if (translations != null && translations.containsKey(englishName)) {
      return translations[englishName]!;
    }
    // Return original name if no translation found
    return englishName;
  }

  // Get holiday name with translation based on locale
  static String getLocalizedHolidayName(
      String englishName, AppLocalizations l10n) {
    // Determine language code from l10n
    final languageCode = _getLanguageCodeFromL10n(l10n);
    return getTranslatedHolidayName(englishName, languageCode);
  }

  // Helper method to determine language code from l10n
  static String _getLanguageCodeFromL10n(AppLocalizations l10n) {
    // Check if it's German by testing a German-specific translation
    if (l10n.area == 'Kanton') {
      return 'de';
    }
    return 'en';
  }

  // Add a new holiday translation
  static void addHolidayTranslation(
      String englishName, Map<String, String> translations) {
    for (final entry in translations.entries) {
      final languageCode = entry.key;
      final translatedName = entry.value;

      if (!_holidayTranslations.containsKey(languageCode)) {
        _holidayTranslations[languageCode] = {};
      }
      _holidayTranslations[languageCode]![englishName] = translatedName;
    }
  }
}
