import '../services/ethiopian_calendar_service.dart';
import '../services/reading_service.dart';
import '../services/sunday_prayers_service.dart';
import '../models/reading_preferences_model.dart';

class ReadingPlanService {
  final ReadingService _readingService = ReadingService();
  final SundayPrayersService _sundayPrayersService = SundayPrayersService();

  // Get today's reading plan
  Future<TodaysReadingPlan?> getTodaysReadingPlan(String userId) async {
    try {
      // Get user's reading preferences
      final preferences = await _readingService.getReadingPreferences(userId);
      if (preferences == null) return null;

      // Get current date
      final now = DateTime.now();
      final currentEthiopian = EthiopianCalendarService.instance.getCurrentEthiopianDate();
      
      // Calculate which day of the week it is
      final dayOfWeek = now.weekday; // 1=Monday, 2=Tuesday, ..., 7=Sunday
      
      if (dayOfWeek == 7) {
        // Sunday - get prayer topics
        final sundayPrayers = await _sundayPrayersService.getSundayPrayers(userId);
        if (sundayPrayers == null) return null;
        
        // Calculate which week of the month (1-4)
        final weekOfMonth = ((now.day - 1) ~/ 7) + 1;
        final currentWeek = weekOfMonth > 4 ? 4 : weekOfMonth;
        
        return TodaysReadingPlan(
          date: now,
          ethiopianDate: currentEthiopian,
          isSunday: true,
          prayerTopics: sundayPrayers.weeklyPrayers[currentWeek] ?? [],
          chapters: [],
        );
      } else {
        // Monday to Saturday - dynamic based on weeks since start
        final perDay = preferences.perDayChapterCounts;
        final int n = perDay != null
            ? _countForDay(perDay, dayOfWeek, preferences.dailyChapterCount)
            : preferences.dailyChapterCount;

        final DateTime a = DateTime(now.year, now.month, now.day);
        final DateTime b = DateTime(
          preferences.startDate.year,
          preferences.startDate.month,
          preferences.startDate.day,
        );
        final int cDays = a.difference(b).inDays;
        final int g = cDays >= 0 ? (cDays ~/ 7) : 0; // integer division

        final int hBase = _baseStartForDay(dayOfWeek);
        final int nextDow = dayOfWeek == 6 ? 1 : dayOfWeek + 1;
        final int hNextBase = _baseStartForDay(nextDow);


        final range =   dayOfWeek == 6 ? 20 : hNextBase - hBase;
        final List<int> chapters = <int>[];

        final int gModRange = (n * g) % range;
        for (int i = 0; i < n; i++) {
          final int h = hBase + ((gModRange + i) % range);
          chapters.add(h);
        }


        return TodaysReadingPlan(
          date: now,
          ethiopianDate: currentEthiopian,
          isSunday: false,
          prayerTopics: [],
          chapters: chapters,
        );
      }
    } catch (e) {
      throw Exception('Failed to get today\'s reading plan: $e');
    }
  }

  int _baseStartForDay(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 1;   // Monday
      case 2:
        return 31;  // Tuesday
      case 3:
        return 61;  // Wednesday
      case 4:
        return 81;  // Thursday
      case 5:
        return 111; // Friday
      case 6:
        return 131; // Saturday
      default:
        return 1;
    }
  }

  int _countForDay(Map<String, int> map, int dayOfWeek, int fallback) {
    // 1=Mon..6=Sat mapping to keys 'mon','tue','wed','thu','fri','sat'
    const keys = {1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu', 5: 'fri', 6: 'sat'};
    final key = keys[dayOfWeek];
    if (key == null) return fallback;
    final v = map[key];
    if (v == null || v <= 0) return fallback;
    return v;
  }

  // Check if user has completed setup
  Future<bool> isSetupComplete(String userId) async {
    try {
      final hasPreferences = await _readingService.hasReadingPreferences(userId);
      final hasSundayPrayers = await _sundayPrayersService.hasSundayPrayers(userId);
      return hasPreferences && hasSundayPrayers;
    } catch (e) {
      return false;
    }
  }
}

class TodaysReadingPlan {
  final DateTime date;
  final EthiopianDate ethiopianDate;
  final bool isSunday;
  final List<String> prayerTopics;
  final List<int> chapters;

  const TodaysReadingPlan({
    required this.date,
    required this.ethiopianDate,
    required this.isSunday,
    required this.prayerTopics,
    required this.chapters,
  });
}
