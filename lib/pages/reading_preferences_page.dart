import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../services/ethiopian_calendar_service.dart';
import '../bloc/reading_bloc.dart';
import '../bloc/reading_event.dart';
import '../bloc/reading_state.dart';
import '../services/reading_service.dart';
import '../services/localization_service.dart';
import '../models/user_model.dart';
import '../widgets/ethiopian_calendar_picker.dart';
import 'sunday_prayers_page.dart';
import 'home_page.dart';

class ReadingPreferencesPage extends StatefulWidget {
  final UserModel user;

  const ReadingPreferencesPage({super.key, required this.user});

  @override
  State<ReadingPreferencesPage> createState() => _ReadingPreferencesPageState();
}

class _ReadingPreferencesPageState extends State<ReadingPreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  final _chapterCountController = TextEditingController();
  final Map<String, TextEditingController> _perDayControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
  };
  DateTime _selectedDate = DateTime.now();
  EthiopianDate _selectedEthiopianDate = EthiopianCalendarService.instance.getCurrentEthiopianDate();
  String _currentLanguage = 'en';
  String _currentCalendar = 'ethiopian';
  bool _isSaving = false;
  bool _useFullDailyChapters = false;

  @override
  void initState() {
    super.initState();
    _chapterCountController.text = '5'; // Default value
    _initializeLocalization();
    _loadCurrentPreferences();
  }

  Widget _buildDayField(String label, String key) {
    final isAm = _currentLanguage == 'am';
    final optionalText = isAm ? ' (አማራጭ)' : ' (Optional)';
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: _perDayControllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label + optionalText,
          hintText: isAm ? 'ለ.ም፣ 5' : 'e.g., 5',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : null,
          ),
          floatingLabelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : null,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.deepPurple,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null; // optional
          final v = int.tryParse(value);
          if (v == null || v < 1 || v > 30) {
            return isAm ? '1-30 መካከል' : '1-30';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _initializeLocalization() async {
    await LocalizationService.instance.initialize();
    setState(() {
      _currentLanguage = LocalizationService.instance.currentLanguage;
      // Set calendar based on language preference
      _currentCalendar = _currentLanguage == 'am' ? 'ethiopian' : 'gregorian';
    });
  }

  Future<void> _loadCurrentPreferences() async {
    try {
      final readingService = ReadingService();
      final preferences = await readingService.getReadingPreferences(widget.user.id);
      
      if (preferences != null) {
        setState(() {
          _chapterCountController.text = preferences.dailyChapterCount.toString();
          // Normalize to local noon to avoid TZ boundary off-by-one
          _selectedDate = DateTime(
            preferences.startDate.year,
            preferences.startDate.month,
            preferences.startDate.day,
            12,
          );
          _selectedEthiopianDate = EthiopianCalendarService.instance.gregorianToEthiopian(_selectedDate);
          final per = preferences.perDayChapterCounts;
          if (per != null) {
            per.forEach((k, v) {
              if (_perDayControllers[k] != null) {
                _perDayControllers[k]!.text = v.toString();
              }
            });
            // Check if the per-day values match the full daily chapters pattern
            if (per['mon'] == 30 && per['tue'] == 30 && per['wed'] == 20 &&
                per['thu'] == 30 && per['fri'] == 20 && per['sat'] == 20) {
              _useFullDailyChapters = true;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading current preferences: $e');
      // Keep default values if loading fails
    }
  }

  @override
  void dispose() {
    _chapterCountController.dispose();
    for (final c in _perDayControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (_currentCalendar == 'ethiopian') {
      await _selectEthiopianDate();
    } else {
      await _selectGregorianDate();
    }
  }

  Future<void> _selectGregorianDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scheme = isDark
            ? const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                surface: Colors.black,
                onSurface: Colors.white,
              )
            : const ColorScheme.light(
                primary: Colors.deepPurple,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              );
        final theme = Theme.of(context).copyWith(
          colorScheme: scheme,
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1),
            ),
          ),
        );
        return Theme(data: theme, child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        final pickedAtNoon = DateTime(picked.year, picked.month, picked.day, 12);
        _selectedDate = pickedAtNoon;
        _selectedEthiopianDate = EthiopianCalendarService.instance.gregorianToEthiopian(pickedAtNoon);
      });
    }
  }

  Future<void> _selectEthiopianDate() async {
    final dateRange = EthiopianCalendarService.instance.getEthiopianDateRange();
    
    await showDialog(
      context: context,
      builder: (context) => EthiopianCalendarPicker(
        initialDate: _selectedEthiopianDate,
        firstDate: dateRange['firstDate']!,
        lastDate: dateRange['lastDate']!,
        language: _currentLanguage,
        onDateSelected: (EthiopianDate selectedDate) {
          setState(() {
            _selectedEthiopianDate = selectedDate;
            _selectedDate = EthiopianCalendarService.instance.ethiopianToGregorian(selectedDate);
          });
        },
      ),
    );
  }

  void _savePreferences() async {
    print('=== SAVE PREFERENCES CALLED ===');
    print('Form key: $_formKey');
    print('Form key current state: ${_formKey.currentState}');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dailyChapterCount = int.parse(_chapterCountController.text);
    // Build per-day map if provided; empty fields are ignored
    final Map<String, int> perDay = {};
    
    if (_useFullDailyChapters) {
      // Use full daily chapters values
      perDay['mon'] = 30;
      perDay['tue'] = 30;
      perDay['wed'] = 20;
      perDay['thu'] = 30;
      perDay['fri'] = 20;
      perDay['sat'] = 20;
    } else {
      // Build from controllers
      _perDayControllers.forEach((k, c) {
        final v = int.tryParse(c.text.trim());
        if (v != null && v > 0) perDay[k] = v;
      });
    }
    print('✅ Form validation passed');
    print('📝 Saving preferences: userId=${widget.user.id}, chapters=$dailyChapterCount, date=$_selectedDate');
    
    print('📤 Dispatching SaveReadingPreferences event...');
    context.read<ReadingBloc>().add(
      SaveReadingPreferences(
        userId: widget.user.id,
        dailyChapterCount: dailyChapterCount,
        startDate: _selectedDate,
        perDayChapterCounts: perDay.isNotEmpty ? perDay : null,
      ),
    );
    print('✅ SaveReadingPreferences event dispatched');
    // Navigation handled by Bloc listener
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'en' ? 'am' : 'en';
      // Automatically switch calendar type based on language
      _currentCalendar = _currentLanguage == 'am' ? 'ethiopian' : 'gregorian';
    });
    LocalizationService.instance.setLanguage(_currentLanguage);
    LocalizationService.instance.setCalendar(_currentCalendar);
  }

  String _getFormattedDate() {
    if (_currentCalendar == 'ethiopian') {
      return EthiopianCalendarService.instance.formatEthiopianDateWithDay(
        _selectedEthiopianDate,
        language: _currentLanguage,
      );
    } else {
      if (_currentLanguage == 'am') {
        // For Amharic, we'll show Ethiopian date even when Gregorian is selected
        return EthiopianCalendarService.instance.formatEthiopianDateWithDay(
          _selectedEthiopianDate,
          language: _currentLanguage,
        );
      } else {
        return DateFormat('MMMM dd, yyyy').format(_selectedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(LocalizationService.instance.translate('reading_preferences')),
        
        actions: [
          // Language toggle (automatically switches calendar)
          IconButton(
            onPressed: _toggleLanguage,
            icon: Icon(_currentLanguage == 'en' ? Icons.language : Icons.translate),
            tooltip: _currentLanguage == 'en' ? 'Switch to Amharic (Ethiopian Calendar)' : 'Switch to English (Gregorian Calendar)',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ReadingBloc, ReadingState>(
          listener: (context, state) {
            print('=== BLOC LISTENER TRIGGERED ===');
            print('State type: ${state.runtimeType}');
            print('State details: $state');
            
            if (state is ReadingPreferencesSaved) {
              print('✅ ReadingPreferencesSaved state received!');
              print('✅ About to show snackbar and navigate...');
              
              setState(() {
                _isSaving = false;
              });
              
              // Defer navigation to next frame to avoid navigator lock
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePage(user: widget.user)),
                  (route) => false,
                );
              });
              
            } else if (state is ReadingError) {
              print('❌ ReadingError state received: ${state.message}');
              setState(() {
                _isSaving = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${LocalizationService.instance.translate('error')}: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              print('ℹ️ Other state received: ${state.runtimeType}');
            }
          },
          builder: (context, state) {
            print('=== BLOC BUILDER CALLED ===');
            print('Builder state type: ${state.runtimeType}');
            
            // No builder navigation to prevent duplicate pushes
            
            if (state is ReadingLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 48,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LocalizationService.instance.translate('set_your_reading_preferences'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService.instance.translate('configure_psalms_reading'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Per-day (Mon–Sat) moved to dedicated page

                      // Daily Chapter Count
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.instance.translate('daily_chapter_count'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService.instance.translate('chapters_per_day_question'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Full Daily Chapters Option
                              Card(
                                elevation: 1,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade800 
                                    : Colors.grey.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        value: _useFullDailyChapters,
                                        onChanged: (value) {
                                          setState(() {
                                            _useFullDailyChapters = value ?? false;
                                            if (_useFullDailyChapters) {
                                              // Set the full daily chapters values
                                              _perDayControllers['mon']!.text = '30';
                                              _perDayControllers['tue']!.text = '30';
                                              _perDayControllers['wed']!.text = '20';
                                              _perDayControllers['thu']!.text = '30';
                                              _perDayControllers['fri']!.text = '20';
                                              _perDayControllers['sat']!.text = '20';
                                            } else {
                                              // Clear per-day values when unchecked
                                              for (final controller in _perDayControllers.values) {
                                                controller.clear();
                                              }
                                            }
                                          });
                                        },
                                        title: Text(
                                          LocalizationService.instance.translate('full_daily_chapters'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          LocalizationService.instance.translate('full_daily_chapters_description'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white70 
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        activeColor: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.deepPurple,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _chapterCountController,
                                enabled: !_useFullDailyChapters,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: LocalizationService.instance.translate('chapters_per_day'),
                                  hintText: 'e.g., 5',
                                  prefixIcon: Icon(
                                    Icons.menu_book,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : null,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : null,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : Colors.deepPurple),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return LocalizationService.instance.translate('please_enter_number');
                                  }
                                  final count = int.tryParse(value);
                                  if (count == null) {
                                    return LocalizationService.instance.translate('please_enter_valid_number');
                                  }
                                  if (count < 1) {
                                    return LocalizationService.instance.translate('must_be_at_least_1');
                                  }
                                  if (count > 30) {
                                    return LocalizationService.instance.translate('maximum_30_chapters');
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start Date
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.instance.translate('start_date'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService.instance.translate('start_date_question'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentCalendar == 'ethiopian' 
                                    ? '🇪🇹 ${LocalizationService.instance.translate('ethiopian_calendar')}'
                                    : '🌍 ${LocalizationService.instance.translate('gregorian_calendar')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _currentCalendar == 'ethiopian' ? Colors.deepPurple : Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.deepPurple,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _getFormattedDate(),
                                        style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  LocalizationService.instance.translate('save_preferences'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocalizationService.instance.translate('reading_schedule'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• ${LocalizationService.instance.translate('monday')}: ${LocalizationService.instance.translate('psalms')} 1-30\n'
                                '• ${LocalizationService.instance.translate('tuesday')}: ${LocalizationService.instance.translate('psalms')} 31-60\n'
                                '• ${LocalizationService.instance.translate('wednesday')}: ${LocalizationService.instance.translate('psalms')} 61-80\n'
                                '• ${LocalizationService.instance.translate('thursday')}: ${LocalizationService.instance.translate('psalms')} 81-110\n'
                                '• ${LocalizationService.instance.translate('friday')}: ${LocalizationService.instance.translate('psalms')} 111-130\n'
                                '• ${LocalizationService.instance.translate('saturday')}: ${LocalizationService.instance.translate('psalms')} 131-150\n'
                                '• ${LocalizationService.instance.translate('sunday')}: ${LocalizationService.instance.translate('selected_prayers')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
          },
          ),
        ),
      );
  }
}

