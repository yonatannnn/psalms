import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/reading_plan_service.dart';
import '../services/ethiopian_calendar_service.dart';
import 'reading_preferences_page.dart';
import 'sunday_prayers_page.dart';
import 'psalms_viewer_page.dart';
import 'psalms_browser_page.dart';
import '../services/psalms_data_service.dart';
import '../services/prayer_data_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import '../services/font_size_service.dart';
import '../services/sunday_prayers_service.dart';
import 'daily_chapter_preferences_page.dart';
import 'profile_page.dart';
import 'admin_page.dart';
import 'settings_page.dart';
import '../services/push_notification_service.dart';
import '../services/psalm_audio_service.dart';
import '../widgets/psalm_audio_controls.dart';
import 'audio_range_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentLanguage = 'en';
  TodaysReadingPlan? _todaysPlan;
  bool _isLoading = true;
  final ReadingPlanService _readingPlanService = ReadingPlanService();
  String _displayUsername = '';

  @override
  void initState() {
    super.initState();
    _initializeLocalization();
    _displayUsername = widget.user.username;
    _loadUserProfile();
    // Track daily open count (local-first, syncs in background)
    AuthService().trackDailyOpen(widget.user.id);
    _loadTodaysPlan();
    // Save FCM token for current user (non-blocking, requires internet)
    PushNotificationService().saveTokenForCurrentUser().catchError((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    _loadTodaysPlan();
  }

  Future<void> _initializeLocalization() async {
    await LocalizationService.instance.initialize();
    setState(() {
      _currentLanguage = LocalizationService.instance.currentLanguage;
    });
    // Set calendar based on language preference
    LocalizationService.instance.setCalendar(_currentLanguage == 'am' ? 'ethiopian' : 'gregorian');
  }

  Future<void> _loadTodaysPlan() async {
    try {
      final plan = await _readingPlanService.getTodaysReadingPlan(widget.user.id);
      setState(() {
        _todaysPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // getCurrentUserData is now local-first, so this works offline
      final user = await AuthService().getCurrentUserData();
      if (user != null && mounted) {
        setState(() {
          _displayUsername = user.username;
        });
      }
    } catch (_) {}
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'en' ? 'am' : 'en';
    });
    LocalizationService.instance.setLanguage(_currentLanguage);
    // Automatically set calendar based on language
    LocalizationService.instance.setCalendar(_currentLanguage == 'am' ? 'ethiopian' : 'gregorian');
  }

  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey.shade900 : null,
          title: Text(
            LocalizationService.instance.translate('logout'),
            style: TextStyle(color: isDark ? Colors.white : null),
          ),
          content: Text(
            _currentLanguage == 'am' ? 'መውጣት ትፈልጋለህ/ሽ?' : 'Are you sure you want to log out?',
            style: TextStyle(color: isDark ? Colors.white70 : null),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocalizationService.instance.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(LocalizationService.instance.translate('ok')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Soft dark background instead of pure black, so cards stay readable
      // without a harsh black surround.
      backgroundColor: _isLoading
          ? (isDark ? const Color(0xFF121212) : Colors.white)
          : (isDark ? const Color(0xFF121212) : null),
      appBar: AppBar(
        title: Text(LocalizationService.instance.translate('app_title')),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(),
            icon: const Icon(Icons.logout),
            tooltip: LocalizationService.instance.translate('logout'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: SizedBox.expand(
                child: Image.asset(
                  'assets/david2.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(LocalizationService.instance.translate('browse_psalms')),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PsalmsBrowserPage(),
                  ),
                );
              },
            ),
            if (PsalmAudioService.instance.isAvailable)
              ListTile(
                leading: const Icon(Icons.headphones),
                title: Text(LocalizationService.instance.currentLanguage == 'am'
                    ? 'ድምፅ አጫውት'
                    : 'Play Audio Range'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AudioRangePage(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(LocalizationService.instance.currentLanguage == 'am' ? 'ቅንብሮች' : 'Settings'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(user: widget.user),
                  ),
                );
                if (result == true && mounted) {
                  await _loadUserProfile();
                  await _loadTodaysPlan();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(LocalizationService.instance.currentLanguage == 'am' ? 'መገለጫ' : 'Profile'),
              onTap: () async {
                Navigator.pop(context);
                final res = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                if (mounted) {
                  await _loadUserProfile();
                  await _loadTodaysPlan();
                }
              },
            ),
            if (_displayUsername.trim().toLowerCase() == 'yonatan' || _displayUsername.trim() == 'ዮናታን')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(LocalizationService.instance.currentLanguage == 'am' ? 'የአድሚን ገጽ' : 'Admin Page'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminPage()),
                  );
                },
              ),
            const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            _toggleLanguage();
                            await _loadTodaysPlan();
                          },
                          icon: Icon(_currentLanguage == 'en' ? Icons.language : Icons.translate),
                          label: Text(_currentLanguage == 'en' ? 'English' : 'አማርኛ'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await ThemeService.instance.toggleLightDark();
                          },
                          icon: const Icon(Icons.brightness_6),
                          label: Text(
                            Theme.of(context).brightness == Brightness.dark
                                ? LocalizationService.instance.translate('dark_mode')
                                : LocalizationService.instance.translate('light_mode'),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentLanguage == 'am' ? 'በዮናታን የተዘጋጀ' : 'Developed by yonatan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    'Telegram: @lijaleme',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Container(
                color: isDark ? Colors.black : Colors.white,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.deepPurple),
                  ),
                ),
              )
            : RefreshIndicator(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                onRefresh: _loadTodaysPlan,
                child: _todaysPlan == null
                    ? _buildSetupPrompt()
                    : _buildTodaysReading(),
              ),
      ),
    );
  }

  Widget _buildSetupPrompt() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: isDark ? Colors.white : Colors.deepPurple,
          ),
            const SizedBox(height: 24),
            Text(
            "${LocalizationService.instance.translate('welcome')}, ${_displayUsername}!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.deepPurple,
            ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.instance.translate('daily_bible_reading_companion'),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              color: isDark ? Colors.grey.shade900 : null,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      LocalizationService.instance.translate('next_steps'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "1. ${LocalizationService.instance.translate('set_up_reading_preferences')}\n"
                      "2. ${LocalizationService.instance.translate('start_date_question')}\n"
                      "3. ${LocalizationService.instance.translate('selected_prayers')}\n"
                      "4. ${LocalizationService.instance.translate('daily_bible_reading_companion')}!",
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Check if today is Sunday and if Sunday preferences are not set
                          final now = DateTime.now();
                          final isSunday = now.weekday == 7;
                          final hasSundayPrayers = await SundayPrayersService().hasSundayPrayers(widget.user.id);
                          
                          if (isSunday && !hasSundayPrayers) {
                            // Navigate to Sunday preferences page
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SundayPrayersPage(user: widget.user),
                              ),
                            );
                            if (result == true && mounted) {
                              await _loadTodaysPlan();
                            }
                          } else {
                            // Navigate to regular preferences page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ReadingPreferencesPage(user: widget.user),
                              ),
                            );
                          }
                        },
                        icon: Icon(DateTime.now().weekday == 7 ? Icons.church : Icons.settings),
                        label: FutureBuilder<bool>(
                          future: SundayPrayersService().hasSundayPrayers(widget.user.id),
                          builder: (context, snapshot) {
                            final isSunday = DateTime.now().weekday == 7;
                            final hasSundayPrayers = snapshot.data ?? false;
                            return Text(
                              isSunday && !hasSundayPrayers
                                  ? LocalizationService.instance.translate('set_sunday_prayers')
                                  : LocalizationService.instance.translate('set_up_reading_preferences')
                            );
                          },
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTodaysReading() {
    final plan = _todaysPlan!;
    final formattedDate = _currentLanguage == 'am' 
        ? EthiopianCalendarService.instance.formatEthiopianDateWithDay(
            plan.ethiopianDate, 
            language: _currentLanguage
          )
        : '${plan.date.day}/${plan.date.month}/${plan.date.year}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 4,
              color: isDark ? Colors.grey.shade900 : null,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      plan.isSunday ? Icons.church : Icons.menu_book,
                      size: 48,
                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${LocalizationService.instance.translate('welcome')}, ${_displayUsername}!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Today's Reading
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 4,
              color: isDark ? Colors.grey.shade900 : null,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text(
                    LocalizationService.instance.translate('todays_reading'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  if (plan.isSunday) ...[
                    // Sunday - Prayer topics
                    Text(
                      LocalizationService.instance.translate('prayer_topics'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Numbered title list
                    ...List.generate(plan.prayerTopics.length, (i) {
                      final topic = plan.prayerTopics[i];
                      final prayerIndex = PrayerDataService.getPrayerIndexFromTopic(topic);
                      final title = prayerIndex != null
                          ? (PrayerDataService.getTitle(prayerIndex, _currentLanguage) ?? topic)
                          : topic;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}. $title',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ] else ...[
                    // Monday-Saturday - Psalm chapters
                    Text(
                      LocalizationService.instance.translate('chapters_to_read'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PsalmsViewerPage(
                              chapters: plan.chapters,
                              title: _currentLanguage == 'am'
                                  ? 'መዝሙረ ዳዊት ${plan.chapters.first}-${plan.chapters.last}'
                                  : 'Psalms ${plan.chapters.first}-${plan.chapters.last}',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.deepPurple.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentLanguage == 'am'
                                  ? 'መዝሙረ ዳዊት ${plan.chapters.first}-${plan.chapters.last}'
                                  : 'Psalms ${plan.chapters.first}-${plan.chapters.last}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isDark ? Colors.white : Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${plan.chapters.length} ${LocalizationService.instance.translate('chapters_per_day')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (PsalmAudioService.instance.isAvailable &&
                        plan.chapters.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PsalmPlayButton(
                            from: plan.chapters.first,
                            to: plan.chapters.last,
                            iconSize: 34,
                            color: isDark ? Colors.white : Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentLanguage == 'am'
                                ? 'ሁሉንም አዳምጥ (${plan.chapters.first}-${plan.chapters.last})'
                                : 'Listen to all (${plan.chapters.first}-${plan.chapters.last})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      PsalmSeekBar(
                        from: plan.chapters.first,
                        to: plan.chapters.last,
                        color: isDark ? Colors.white : Colors.deepPurple,
                        textColor: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            ),
          ),
          const SizedBox(height: 18),
          // Today's Psalms summary box
          
          
          // Removed action buttons (moved to Drawer)
          // Quick access: show today's psalms snippets
          // Sunday: prayer cards (same style as psalm cards)
          if (plan.isSunday)
            ...plan.prayerTopics.map((topic) {
              final prayerIndex = PrayerDataService.getPrayerIndexFromTopic(topic);
              final hasPrayerText = prayerIndex != null && PrayerDataService.hasPrayer(prayerIndex);
              final title = prayerIndex != null
                  ? (PrayerDataService.getTitle(prayerIndex, _currentLanguage) ?? topic)
                  : topic;
              final content = hasPrayerText ? PrayerDataService.getPrayer(prayerIndex!) ?? '' : '';
              final preview = _firstVersesPreview(content, 3);
              return Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Card(
                  elevation: 1,
                  color: isDark ? Colors.grey.shade900 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.church, color: isDark ? Colors.white : Colors.deepPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (hasPrayerText)
                              TextButton(
                                onPressed: () => _openPrayerViewer(prayerIndex!, title),
                                child: Text(
                                  _currentLanguage == 'am' ? 'ክፈት' : 'Open',
                                  style: TextStyle(color: isDark ? Colors.white : Colors.deepPurple),
                                ),
                              ),
                          ],
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ValueListenableBuilder<double>(
                            valueListenable: FontSizeService.instance.fontSize,
                            builder: (context, fontSize, _) {
                              return Text(
                                preview,
                                style: GoogleFonts.notoSerifEthiopic(fontSize: fontSize, height: 1.6),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          // Weekday: psalm cards
          ...plan.chapters.map((ch) {
            final lang = _currentLanguage;
            final isAm = lang == 'am';
            final content = PsalmsDataService.getPsalmByLanguage(lang, ch) ?? '';
            final preview = _firstVersesPreview(content, 3);
            final header = isAm ? 'መዝሙር $ch' : 'Psalm $ch';
            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Card(
                elevation: 1,
                color: isDark ? Colors.grey.shade900 : null,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bookmark, color: isDark ? Colors.white : Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              header,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (PsalmAudioService.instance.isAvailable)
                            PsalmPlayButton(
                              from: ch,
                              to: ch,
                              iconSize: 26,
                              color: isDark ? Colors.white : Colors.deepPurple,
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PsalmsViewerPage(
                                    chapters: [ch, ch],
                                    title: isAm ? 'መዝሙር $ch' : 'Psalm $ch',
                                  ),
                                ),
                              );
                            },
                            child: Text(isAm ? 'ክፈት' : 'Open', style: TextStyle(color: isDark ? Colors.white : Colors.deepPurple),),
                          )
                        ],
                      ),
                      if (PsalmAudioService.instance.isAvailable)
                        PsalmSeekBar(
                          from: ch,
                          to: ch,
                          color: isDark ? Colors.white : Colors.deepPurple,
                          textColor: isDark ? Colors.white60 : Colors.black54,
                        ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<double>(
                        valueListenable: FontSizeService.instance.fontSize,
                        builder: (context, fontSize, _) {
                          return Text(
                            preview,
                            style: (_currentLanguage == 'am')
                                ? GoogleFonts.notoSerifEthiopic(fontSize: fontSize, height: 1.6)
                                : GoogleFonts.notoSerif(fontSize: fontSize, height: 1.6),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openPrayerViewer(int prayerIndex, String title) {
    final text = PrayerDataService.getPrayer(prayerIndex);
    if (text == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PrayerViewerPage(title: title, text: text),
      ),
    );
  }

  // Take the first N verse lines from the psalm content and form a short preview
  String _firstVersesPreview(String content, int count) {
    final lines = content.split('\n');
    final reg = RegExp(r'^(\d+)\s+(.*)');
    final List<String> verses = [];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = reg.firstMatch(line);
      if (m != null) {
        verses.add('${m.group(1)}. ${m.group(2)}');
      } else {
        if (verses.isEmpty) {
          verses.add(line);
        } else {
          verses[verses.length - 1] = (verses.last + ' ' + line).trim();
        }
      }
      // Show all verses: do not limit by count
    }
    return verses.join('\n');
  }
}

/// Prayer viewer page matching the psalm viewer style
class _PrayerViewerPage extends StatefulWidget {
  final String title;
  final String text;

  const _PrayerViewerPage({required this.title, required this.text});

  @override
  State<_PrayerViewerPage> createState() => _PrayerViewerPageState();
}

class _PrayerViewerPageState extends State<_PrayerViewerPage> {
  final Set<int> _visibleVerseNumbers = <int>{};

  List<MapEntry<int, String>> _parseVerses(String content) {
    final List<MapEntry<int, String>> verses = [];
    final lines = content.split('\n');
    final reg = RegExp(r'^(\d+)\s+(.*)');
    for (final line in lines) {
      final m = reg.firstMatch(line.trim());
      if (m != null) {
        final num = int.tryParse(m.group(1)!);
        final txt = m.group(2)!.trim();
        if (num != null) {
          verses.add(MapEntry(num, txt));
        }
      } else {
        if (verses.isNotEmpty) {
          final last = verses.removeLast();
          verses.add(MapEntry(last.key, '${last.value} ${line.trim()}'.trim()));
        } else if (line.trim().isNotEmpty) {
          verses.add(MapEntry(0, line.trim()));
        }
      }
    }
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verses = _parseVerses(widget.text);

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : Colors.deepPurple.shade200,
                      ),
                    ),
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Verses
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: verses.map((e) {
                        final verseNum = e.key;
                        final showNum = verseNum != 0 && _visibleVerseNumbers.contains(verseNum);
                        return ValueListenableBuilder<double>(
                          valueListenable: FontSizeService.instance.fontSize,
                          builder: (context, fontSize, _) {
                            final bodyStyle = GoogleFonts.notoSerifEthiopic(
                              fontSize: fontSize,
                              height: 1.6,
                              color: isDark ? Colors.white : Colors.black87,
                            );
                            final numStyle = GoogleFonts.notoSerifEthiopic(
                              fontSize: fontSize * 0.875,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  if (verseNum == 0) return;
                                  setState(() {
                                    if (_visibleVerseNumbers.contains(verseNum)) {
                                      _visibleVerseNumbers.remove(verseNum);
                                    } else {
                                      _visibleVerseNumbers.add(verseNum);
                                    }
                                  });
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: showNum ? 28 : 0,
                                      child: showNum
                                          ? Text(
                                              verseNum.toString(),
                                              textAlign: TextAlign.right,
                                              style: numStyle,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    SizedBox(width: showNum ? 8 : 0),
                                    Expanded(
                                      child: Text(e.value, style: bodyStyle),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
