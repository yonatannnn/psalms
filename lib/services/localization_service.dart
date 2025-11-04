import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _calendarKey = 'selected_calendar';
  
  // Language options
  static const String english = 'en';
  static const String amharic = 'am';
  
  // Calendar options
  static const String gregorian = 'gregorian';
  static const String ethiopian = 'ethiopian';
  
  static LocalizationService? _instance;
  static LocalizationService get instance => _instance ??= LocalizationService._();
  
  LocalizationService._();
  
  String _currentLanguage = amharic;
  String _currentCalendar = ethiopian; // Default to Ethiopian calendar
  
  String get currentLanguage => _currentLanguage;
  String get currentCalendar => _currentCalendar;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? amharic;
    _currentCalendar = prefs.getString(_calendarKey) ?? ethiopian;
  }
  
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    // Also save language preference to Firestore for push notifications
    await _saveLanguageToFirestore(language);
  }
  
  Future<void> _saveLanguageToFirestore(String language) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'language': language,
        });
      }
    } catch (e) {
      print('Error saving language to Firestore: $e');
    }
  }
  
  Future<void> setCalendar(String calendar) async {
    _currentCalendar = calendar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarKey, calendar);
  }
  
  // Amharic translations
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Psalms Reader',
      'welcome': 'Welcome',
      'daily_bible_reading_companion': 'Your Daily Bible Reading Companion',
      'next_steps': 'Next Steps',
      'set_up_reading_preferences': 'Set Up Reading Preferences',
      'reading_preferences': 'Reading Preferences',
      'set_your_reading_preferences': 'Set Your Reading Preferences',
      'configure_psalms_reading': 'Configure how you want to read the Psalms daily',
      'daily_chapter_count': 'Daily Chapter Count',
      'chapters_per_day_question': 'How many Psalm chapters do you want to read each day?',
      'chapters_per_day': 'Chapters per day',
      'full_daily_chapters': 'Full Daily Chapters',
      'full_daily_chapters_description': 'Automatically set optimized chapter counts for each weekday monday = 30,\ntuesday = 30,\nwednesday = 20, \nthursday = 30, \nfriday = 20, \nsaturday = 20',
      'start_date': 'Start Date',
      'start_date_question': 'When do you want to start your reading journey?',
      'save_preferences': 'Save Preferences',
      'reading_schedule': 'Reading Schedule',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'selected_prayers': 'Selected prayers',
      'psalms': 'Psalms',
      'preferences_saved': 'Reading preferences saved successfully!',
      'error': 'Error',
      'please_enter_number': 'Please enter a number',
      'please_enter_valid_number': 'Please enter a valid number',
      'must_be_at_least_1': 'Must be at least 1 chapter',
      'maximum_30_chapters': 'Maximum 30 chapters per day',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'ok': 'OK',
      'ethiopian_calendar': 'Ethiopian Calendar',
      'gregorian_calendar': 'Gregorian Calendar',
      'sunday_prayers_setup': 'Sunday Prayers Setup',
      'sunday_prayers_description': 'Organize your Sunday prayer topics by week',
      'sunday_prayers_saved': 'Sunday prayers saved successfully!',
      'select_week': 'Select Week',
      'week': 'Week',
      'prayer_topics': 'Prayer Topics',
      'enter_prayer_topic': 'Enter prayer topic',
      'add_prayer_topic': 'Add Topic',
      'remove': 'Remove',
      'save_prayers': 'Save Prayers',
      'todays_reading': 'Today\'s Reading',
      'chapters_to_read': 'Chapters to Read',
      'edit_preferences': 'Edit Preferences',
      'set_sunday_prayers': 'Set Sunday Prayers',
      'how_many_weeks': 'How many weeks do you want to complete?',
      'weeks': 'weeks',
      'change_weeks': 'Change Weeks',
      'select_at_least_one_prayer': 'Please select at least one prayer for any week',
      'browse_psalms': 'Browse Psalms',
      'select_chapter': 'Select Chapter',
      'enter_chapter_number': 'Enter chapter number',
      'open': 'Open',
      'all_chapters': 'All Chapters',
      'psalm_word': 'Psalm',
      // Login/Signup
      'login_welcome_back': 'Welcome Back',
      'login_create_account': 'Create Account',
      'login_subtitle_signin': 'Sign in to continue your journey',
      'login_subtitle_signup': 'Join Mezmure Dawit today',
      'username': 'Username',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'toggle_to_signup': "Don't have an account? Sign Up",
      'toggle_to_signin': 'Already have an account? Sign In',
      'username_required': 'Please enter a username',
      'username_min3': 'Username must be at least 3 characters',
      'username_no_spaces': 'Do not use spaces',
      'password_required': 'Please enter a password',
      'password_min6': 'Password must be at least 6 characters',
      'confirm_password_required': 'Please confirm your password',
      'passwords_do_not_match': 'Passwords do not match',
      'share': 'Share',
      'share_chapter': 'Share Chapter',
      'share_verse': 'Share Verse',
      'share_chapter_message': 'Share this chapter',
      'share_verse_message': 'Share this verse',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
    },
    'am': {
      'app_title': 'መዝሙረ ዳዊት',
      'welcome': 'እንኳን ደህና መጡ',
      'daily_bible_reading_companion': 'የዕለታዊ መጽሐፍ ቅዱስ ንባብ አጋር',
      'next_steps': 'ቀጣይ ደረጃዎች',
      'set_up_reading_preferences': 'የንባብ ምርጫዎችን ያዋቅሩ',
      'reading_preferences': 'የንባብ ምርጫዎች',
      'set_your_reading_preferences': 'የንባብ ምርጫዎችዎን ያዋቅሩ',
      'configure_psalms_reading': 'የመዝሙረ ዳዊት ንባብ አዘጋጅ',
      'daily_chapter_count': 'የዕለታዊ ምዕራፍ ቁጥር',
      'chapters_per_day_question': 'በዕለት ስንት የመዝሙረ ዳዊት ምዕራፎች ማንበብ ይፈልጋሉ?',
      'chapters_per_day': 'በዕለት የሚነበቡ ምዕራፎች',
      'full_daily_chapters': 'ሙሉ የዕለታዊ ምዕራፎች',
      'full_daily_chapters_description': 'ለእያንዳንዱ የሳምንት ቀን የተመቻቸ የምዕራፍ ብዛት \nሰኞ = 30, \nማክሰኞ = 30, \nረቡዕ = 20, \nሐሙስ = 30, \nአርብ = 20, \nቅዳሜ = 20',
      'start_date': 'የመጀመሪያ ቀን',
      'start_date_question': 'የንባብ ጉዞዎን መቼ መጀመር ይፈልጋሉ?',
      'save_preferences': 'ምርጫዎችን አስቀምጥ',
      'reading_schedule': 'የንባብ ዕቅድ',
      'monday': 'ሰኞ',
      'tuesday': 'ማክሰኞ',
      'wednesday': 'ረቡዕ',
      'thursday': 'ሐሙስ',
      'friday': 'አርብ',
      'saturday': 'ቅዳሜ',
      'sunday': 'እሁድ',
      'selected_prayers': 'የተመረጡ ጸሎቶች',
      'psalms': 'መዝሙረ ዳዊት',
      'preferences_saved': 'የንባብ ምርጫዎች በተሳካ ሁኔታ ተቀመጧል!',
      'error': 'ስህተት',
      'please_enter_number': 'እባክዎ ቁጥር ያስገቡ',
      'please_enter_valid_number': 'እባክዎ ትክክለኛ ቁጥር ያስገቡ',
      'must_be_at_least_1': 'ቢያንስ 1 ምዕራፍ መሆን አለበት',
      'maximum_30_chapters': 'ከፍተኛው 30 ምዕራፍ በዕለት',
      'logout': 'ውጣ',
      'cancel': 'ሰርዝ',
      'ok': 'እሺ',
      'ethiopian_calendar': 'የኢትዮጵያ የቀን መቁጠሪያ',
      'gregorian_calendar': 'የግሪጎሪያን የቀን መቁጠሪያ',
      'sunday_prayers_setup': 'የእሁድ ጸሎቶች ማዋቀር',
      'sunday_prayers_description': 'የእሁድ ጸሎቶችን በሳምንት ያዋቅሩ',
      'sunday_prayers_saved': 'የእሁድ ጸሎቶች በተሳካ ሁኔታ ተቀመጧል!',
      'select_week': 'ሳምንት ይምረጡ',
      'week': 'ሳምንት',
      'prayer_topics': 'የጸሎት ርዕሶች',
      'enter_prayer_topic': 'የጸሎት ርዕስ ያስገቡ',
      'add_prayer_topic': 'ርዕስ ያክሉ',
      'remove': 'አስወግድ',
      'save_prayers': 'ጸሎቶችን አስቀምጥ',
      'todays_reading': 'የዛሬ ንባብ',
      'chapters_to_read': 'የሚነባቡ ምዕራፎች',
      'edit_preferences': 'ምርጫዎችን አስተካክሉ',
      'set_sunday_prayers': 'የእሁድ ጸሎቶች ያዋቅሩ',
      'how_many_weeks': 'ስንት ሳምንት ማጠናቀቅ ይፈልጋሉ?',
      'weeks': 'ሳምንታት',
      'change_weeks': 'ሳምንታት ቀይር',
      'select_at_least_one_prayer': 'እባክዎ ቢያንስ አንድ ሳምንት ጸሎት ይምረጡ',
      'browse_psalms': 'ሁሉንም ምዕራፎች ይመልከቱ',
      'select_chapter': 'ምዕራፍ ይምረጡ',
      'enter_chapter_number': 'የምዕራፍ ቁጥር ያስገቡ',
      'open': 'ክፈት',
      'all_chapters': 'ሁሉም ምዕራፎች',
      'psalm_word': 'መዝሙር',
      // Login/Signup
      'login_welcome_back': 'እንኳን ደህና መጡ',
      'login_create_account': 'መለያ ይፍጠሩ',
      'login_subtitle_signin': 'ጉዞዎን ለማቀጠል ይግቡ',
      'login_subtitle_signup': 'መዝሙረ ዳዊትን ዛሬ ይቀላቀሉ',
      'username': 'የተጠቃሚ ስም',
      'password': 'የሚስጥር ቁጥር',
      'confirm_password': 'የሚስጥር ቁጥር አረጋግጥ',
      'sign_in': 'ግባ',
      'sign_up': 'መዝግብ',
      'toggle_to_signup': 'መለያ የለዎትም? መዝግብ',
      'toggle_to_signin': 'መለያ አለዎት? ግባ',
      'username_required': 'እባክዎ የተጠቃሚ ስም ያስገቡ',
      'username_min3': 'የተጠቃሚ ስም ቢያንስ 3 ፊደል ይሁን',
      'username_no_spaces': 'ክፍተት አይጠቀሙ',
      'password_required': 'እባክዎ የሚስጥር ቁጥር ያስገቡ',
      'password_min6': 'የሚስጥር ቁጥር ቢያንስ 6 ፊደል ይሁን',
      'confirm_password_required': 'እባክዎ የሚስጥር ቁጥር ያረጋግጡ',
      'passwords_do_not_match': 'የሚስጥር ቁጥሮች አይመሳሰሉም',
      'share': 'አጋራ',
      'share_chapter': 'ምዕራፍ አጋራ',
      'share_verse': 'አንቀፅ አጋራ',
      'share_chapter_message': 'ይህንን ምዕራፍ አጋራ',
      'share_verse_message': 'ይህንን አንቀፅ አጋራ',
      'dark_mode': 'የጨለማ ሁነታ',
      'light_mode': 'የብርሃን ሁነታ',
    },
  };
  
  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? _translations[english]![key]!;
  }
  
  // Ethiopian month names
  static const List<String> ethiopianMonths = [
    'መስከረም', 'ጥቅምት', 'ሕዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
  ];
  
  // Ethiopian day names
  static const List<String> ethiopianDays = [
    'እሁድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ'
  ];
  
  String getEthiopianMonthName(int month) {
    if (month >= 1 && month <= 13) {
      return ethiopianMonths[month - 1];
    }
    return '';
  }
  
  String getEthiopianDayName(int dayOfWeek) {
    if (dayOfWeek >= 0 && dayOfWeek <= 6) {
      return ethiopianDays[dayOfWeek];
    }
    return '';
  }
}
