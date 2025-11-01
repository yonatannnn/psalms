import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reading_bloc.dart';
import '../bloc/reading_event.dart';
import '../bloc/reading_state.dart';
import '../services/reading_service.dart';
import '../services/localization_service.dart';
import '../models/user_model.dart';
import '../models/reading_preferences_model.dart';

class DailyChapterPreferencesPage extends StatefulWidget {
  final UserModel user;
  const DailyChapterPreferencesPage({super.key, required this.user});

  @override
  State<DailyChapterPreferencesPage> createState() => _DailyChapterPreferencesPageState();
}

class _DailyChapterPreferencesPageState extends State<DailyChapterPreferencesPage> {
  final Map<String, TextEditingController> _perDayControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
  };
  bool _isSaving = false;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _currentLanguage = LocalizationService.instance.currentLanguage;
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final prefs = await ReadingService().getReadingPreferences(widget.user.id);
      if (prefs?.perDayChapterCounts != null) {
        for (final e in prefs!.perDayChapterCounts!.entries) {
          if (_perDayControllers[e.key] != null) {
            _perDayControllers[e.key]!.text = e.value.toString();
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _perDayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() async {
    setState(() => _isSaving = true);
    // Fetch existing to preserve dailyChapterCount/startDate
    final readingService = ReadingService();
    final existing = await readingService.getReadingPreferences(widget.user.id);
    final Map<String, int> perDay = {};
    _perDayControllers.forEach((k, c) {
      final v = int.tryParse(c.text.trim());
      if (v != null && v > 0) perDay[k] = v;
    });

    final dailyCount = existing?.dailyChapterCount ?? 5;
    final startDate = existing?.startDate ?? DateTime.now();

    // Use BLoC to update
    context.read<ReadingBloc>().add(UpdateReadingPreferences(
      userId: widget.user.id,
      dailyChapterCount: dailyCount,
      startDate: startDate,
      perDayChapterCounts: perDay.isNotEmpty ? perDay : {},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAm = _currentLanguage == 'am';
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(isAm ? 'በቀን የሚነበቡ ምዕራፎች' : 'Per-day Chapters'),
      ),
      body: SafeArea(
        child: BlocListener<ReadingBloc, ReadingState>(
            listener: (context, state) {
              if (state is ReadingPreferencesUpdated || state is ReadingPreferencesSaved) {
                if (mounted) {
                  setState(() => _isSaving = false);
                Navigator.pop(context, true);
                }
              } else if (state is ReadingError) {
                if (mounted) setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? 'ለእያንዳንዱ ቀን ምዕራፍ ብዛት (አማራጭ)' : 'Set chapters per day (Optional)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildField(isAm ? 'ሰኞ (አማራጭ)' : 'Mon (Optional)', 'mon', isDark),
                  const SizedBox(height: 12),
                  _buildField(isAm ? 'ማክሰኞ (አማራጭ)' : 'Tue (Optional)', 'tue', isDark),
                  const SizedBox(height: 12),
                  _buildField(isAm ? 'ረቡዕ (አማራጭ)' : 'Wed (Optional)', 'wed', isDark),
                  const SizedBox(height: 12),
                  _buildField(isAm ? 'ሐሙስ (አማራጭ)' : 'Thu (Optional)', 'thu', isDark),
                  const SizedBox(height: 12),
                  _buildField(isAm ? 'ዓርብ (አማራጭ)' : 'Fri (Optional)', 'fri', isDark),
                  const SizedBox(height: 12),
                  _buildField(isAm ? 'ቅዳሜ (አማራጭ)' : 'Sat (Optional)', 'sat', isDark),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : Text(isAm ? 'አስቀምጥ' : 'Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildField(String label, String key, bool isDark) {
    return TextFormField(
      controller: _perDayControllers[key],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: isDark ? '5' : 'e.g., 5',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
        floatingLabelStyle: TextStyle(color: isDark ? Colors.white : Colors.deepPurple),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : null),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white70 : Colors.deepPurple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
