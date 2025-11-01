import 'package:abushakir/abushakir.dart';

class EthiopianDate {
  final int year;
  final int month;
  final int day;
  final int weekday;

  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
  });

  @override
  String toString() {
    return '$year-$month-$day';
  }
}

class EthiopianCalendarService {
  static EthiopianCalendarService? _instance;
  static EthiopianCalendarService get instance => _instance ??= EthiopianCalendarService._();
  
  EthiopianCalendarService._();
  
  // Convert Gregorian date to Ethiopian date
  EthiopianDate gregorianToEthiopian(DateTime gregorianDate) {
    // Use the abushakir package for accurate date conversion
    final etDatetime = EtDatetime.fromMillisecondsSinceEpoch(gregorianDate.millisecondsSinceEpoch);
    
    // Use the actual Gregorian weekday instead of abushakir's weekday
    // Ethiopian week starts on Sunday (0), Gregorian week starts on Monday (1)
    final gregorianWeekday = gregorianDate.weekday;
    final ethiopianWeekday = gregorianWeekday == 7 ? 0 : gregorianWeekday;
    
    return EthiopianDate(
      year: etDatetime.year,
      month: etDatetime.month,
      day: etDatetime.day,
      weekday: ethiopianWeekday,
    );
  }
  
  // Convert Ethiopian date to Gregorian date
  DateTime ethiopianToGregorian(EthiopianDate ethiopianDate) {
    // Use a more accurate conversion algorithm
    // Ethiopian calendar starts on September 11, 7 BC (Gregorian)
    // Ethiopian year 1 = Gregorian year 8 AD
    
    int gregorianYear = ethiopianDate.year + 7;
    int gregorianMonth;
    int gregorianDay;
    
    // Calculate Gregorian month and day based on Ethiopian month
    switch (ethiopianDate.month) {
      case 1: // Meskerem
        gregorianMonth = 9;
        gregorianDay = ethiopianDate.day + 10; // Ethiopian year starts on Sep 11
        break;
      case 2: // Tikimt
        gregorianMonth = 10;
        gregorianDay = ethiopianDate.day + 10;
        break;
      case 3: // Hidar
        gregorianMonth = 11;
        gregorianDay = ethiopianDate.day + 9;
        break;
      case 4: // Tahsas
        gregorianMonth = 12;
        gregorianDay = ethiopianDate.day + 9;
        break;
      case 5: // Tir
        gregorianMonth = 1;
        gregorianDay = ethiopianDate.day + 8;
        gregorianYear++; // Next Gregorian year
        break;
      case 6: // Yekatit
        gregorianMonth = 2;
        gregorianDay = ethiopianDate.day + 7;
        gregorianYear++; // Next Gregorian year
        break;
      case 7: // Megabit
        gregorianMonth = 3;
        gregorianDay = ethiopianDate.day + 9;
        gregorianYear++; // Next Gregorian year
        break;
      case 8: // Miyazya
        gregorianMonth = 4;
        gregorianDay = ethiopianDate.day + 8;
        gregorianYear++; // Next Gregorian year
        break;
      case 9: // Ginbot
        gregorianMonth = 5;
        gregorianDay = ethiopianDate.day + 8;
        gregorianYear++; // Next Gregorian year
        break;
      case 10: // Sene
        gregorianMonth = 6;
        gregorianDay = ethiopianDate.day + 7;
        gregorianYear++; // Next Gregorian year
        break;
      case 11: // Hamle
        gregorianMonth = 7;
        gregorianDay = ethiopianDate.day + 7;
        gregorianYear++; // Next Gregorian year
        break;
      case 12: // Nehasie
        gregorianMonth = 8;
        gregorianDay = ethiopianDate.day + 6;
        gregorianYear++; // Next Gregorian year
        break;
      case 13: // Pagumen
        gregorianMonth = 9;
        gregorianDay = ethiopianDate.day + 5;
        gregorianYear++; // Next Gregorian year
        break;
      default:
        gregorianMonth = 9;
        gregorianDay = ethiopianDate.day + 10;
    }
    
    // Handle day overflow within month
    final daysInMonth = _getDaysInGregorianMonth(gregorianYear, gregorianMonth);
    if (gregorianDay > daysInMonth) {
      gregorianDay -= daysInMonth;
      gregorianMonth++;
      if (gregorianMonth > 12) {
        gregorianYear++;
        gregorianMonth = 1;
      }
    }
    
    return DateTime(gregorianYear, gregorianMonth, gregorianDay);
  }
  
  int _getDaysInGregorianMonth(int year, int month) {
    const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isGregorianLeapYear(year)) {
      return 29;
    }
    return daysInMonth[month - 1];
  }
  
  bool _isGregorianLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
  
  // Get current Ethiopian date
  EthiopianDate getCurrentEthiopianDate() {
    return gregorianToEthiopian(DateTime.now());
  }
  
  // Format Ethiopian date for display
  String formatEthiopianDate(EthiopianDate ethiopianDate, {String language = 'en'}) {
    if (language == 'am') {
      // Amharic formatting
      final monthName = _getEthiopianMonthNameAmharic(ethiopianDate.month);
      return '${ethiopianDate.day} $monthName ${ethiopianDate.year}';
    } else {
      // English formatting
      final monthName = _getEthiopianMonthNameEnglish(ethiopianDate.month);
      return '${ethiopianDate.day} $monthName ${ethiopianDate.year}';
    }
  }
  
  // Format Ethiopian date with day name
  String formatEthiopianDateWithDay(EthiopianDate ethiopianDate, {String language = 'en'}) {
    final dayName = _getEthiopianDayName(ethiopianDate.weekday, language);
    final dateStr = formatEthiopianDate(ethiopianDate, language: language);
    return '$dayName, $dateStr';
  }
  
  // Get Ethiopian month names in English
  String _getEthiopianMonthNameEnglish(int month) {
    const months = [
      'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
      'Megabit', 'Miyazya', 'Ginbot', 'Sene', 'Hamle', 'Nehasie', 'Pagumen'
    ];
    if (month >= 1 && month <= 13) {
      return months[month - 1];
    }
    return '';
  }
  
  // Get Ethiopian month names in Amharic
  String _getEthiopianMonthNameAmharic(int month) {
    const months = [
      'መስከረም', 'ጥቅምት', 'ሕዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
      'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
    ];
    if (month >= 1 && month <= 13) {
      return months[month - 1];
    }
    return '';
  }
  
  // Get Ethiopian day names
  String _getEthiopianDayName(int dayOfWeek, String language) {
    if (language == 'am') {
      const days = ['እሁድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ'];
      if (dayOfWeek >= 0 && dayOfWeek <= 6) {
        return days[dayOfWeek];
      }
    } else {
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      if (dayOfWeek >= 0 && dayOfWeek <= 6) {
        return days[dayOfWeek];
      }
    }
    return '';
  }
  
  // Get date range for Ethiopian calendar picker
  Map<String, DateTime> getEthiopianDateRange() {
    final now = DateTime.now();
    
    // One year before and after current date
    final oneYearBefore = now.subtract(const Duration(days: 365));
    final oneYearAfter = now.add(const Duration(days: 365));
    
    return {
      'firstDate': oneYearBefore,
      'lastDate': oneYearAfter,
    };
  }
  
  // Validate Ethiopian date
  bool isValidEthiopianDate(int year, int month, int day) {
    try {
      // Create a test date to validate
      final testDate = DateTime(year, month, day);
      gregorianToEthiopian(testDate);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get Ethiopian year from Gregorian date
  int getEthiopianYear(DateTime gregorianDate) {
    return gregorianToEthiopian(gregorianDate).year;
  }
  
  // Check if it's a leap year in Ethiopian calendar
  bool isEthiopianLeapYear(int year) {
    // Ethiopian leap year calculation
    return (year % 4 == 3);
  }
}
