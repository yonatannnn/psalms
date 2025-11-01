import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sunday_prayers_bloc.dart';
import '../bloc/sunday_prayers_event.dart';
import '../bloc/sunday_prayers_state.dart';
import '../services/sunday_prayers_service.dart';
import '../services/localization_service.dart';
import '../models/user_model.dart';
import 'home_page.dart';

class SundayPrayersPage extends StatefulWidget {
  final UserModel user;

  const SundayPrayersPage({super.key, required this.user});

  @override
  State<SundayPrayersPage> createState() => _SundayPrayersPageState();
}

class _SundayPrayersPageState extends State<SundayPrayersPage> {
  final Map<int, List<String>> _weeklyPrayers = {};
  int _currentWeek = 1;
  int _totalWeeks = 4;
  bool _hasSelectedWeekCount = false;
  List<String> _availablePrayers = [];
  late final SundayPrayersBloc _sundayPrayersBloc;

  @override
  void initState() {
    super.initState();
    _sundayPrayersBloc = SundayPrayersBloc(sundayPrayersService: SundayPrayersService());
    _initializeLocalization();
    _initializePrayers();
  }

  Future<void> _initializeLocalization() async {
    await LocalizationService.instance.initialize();
  }

  void _initializePrayers() {
    // Initialize with empty prayers - will be filled after week count selection
    for (int week = 1; week <= _totalWeeks; week++) {
      _weeklyPrayers[week] = [];
    }
  }

  void _loadPrayerTopics() {
    final currentLanguage = LocalizationService.instance.currentLanguage;
    if (currentLanguage == 'am') {
      _availablePrayers = SundayPrayersService.getEthiopianPrayerTopics();
    } else {
      _availablePrayers = SundayPrayersService.getEnglishPrayerTopics();
    }
  }

  void _selectWeekCount(int weekCount) {
    setState(() {
      _totalWeeks = weekCount;
      _hasSelectedWeekCount = true;
      _loadPrayerTopics();
      _initializePrayers();
    });
  }

  @override
  void dispose() {
    _sundayPrayersBloc.close();
    super.dispose();
  }

  void _savePrayers() {
    // Check if at least one week has prayers selected
    bool hasAnyPrayers = false;
    for (int week = 1; week <= _totalWeeks; week++) {
      if (_weeklyPrayers[week]!.isNotEmpty) {
        hasAnyPrayers = true;
        break;
      }
    }

    if (!hasAnyPrayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.instance.translate('select_at_least_one_prayer')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _sundayPrayersBloc.add(
      SaveSundayPrayers(
        userId: widget.user.id,
        weeklyPrayers: _weeklyPrayers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(LocalizationService.instance.translate('sunday_prayers_setup')),
      ),
      body: BlocConsumer<SundayPrayersBloc, SundayPrayersState>(
        bloc: _sundayPrayersBloc,
        listener: (context, state) {
          if (state is SundayPrayersSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService.instance.translate('sunday_prayers_saved')),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(user: widget.user),
              ),
            );
          } else if (state is SundayPrayersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${LocalizationService.instance.translate('error')}: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SundayPrayersLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
                  border: Border(
                    bottom: BorderSide(color: isDark ? Colors.white10 : Colors.deepPurple.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.church,
                      size: 48,
                      color: isDark ? Colors.white70 : Colors.deepPurple.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationService.instance.translate('sunday_prayers_setup'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.deepPurple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocalizationService.instance.translate('sunday_prayers_description'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.deepPurple.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Week Count Selection (if not selected yet)
              if (!_hasSelectedWeekCount) ...[
                Container(
                  backgroundColor: isDark ? Colors.grey.shade900 : null,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        LocalizationService.instance.translate('how_many_weeks'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(8, (index) {
                          final weekCount = index + 1;
                          return ChoiceChip(
                            label: Text('$weekCount ${LocalizationService.instance.translate('weeks')}'),
                            selected: false,
                            backgroundColor: isDark ? Colors.grey.shade800 : null,
                            onSelected: (selected) {
                              _selectWeekCount(weekCount);
                            },
                            selectedColor: isDark ? Colors.white24 : Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white : Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Week selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        LocalizationService.instance.translate('select_week'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_totalWeeks, (index) {
                              final week = index + 1;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${LocalizationService.instance.translate('week')} $week'),
                                  selected: _currentWeek == week,
                                  backgroundColor: isDark ? Colors.grey.shade800 : null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _currentWeek = week;
                                    });
                                  },
                                  selectedColor: isDark ? Colors.white24 : Colors.deepPurple,
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? (_currentWeek == week ? Colors.white : Colors.white70)
                                        : (_currentWeek == week ? Colors.white : Colors.deepPurple),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Prayer topics for selected week
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${LocalizationService.instance.translate('week')} $_currentWeek - ${LocalizationService.instance.translate('prayer_topics')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _availablePrayers.length,
                            itemBuilder: (context, index) {
                              final prayer = _availablePrayers[index];
                              final isSelected = _weeklyPrayers[_currentWeek]!.contains(prayer);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isDark ? Colors.grey.shade900 : null,
                                child: CheckboxListTile(
                                  title: Text(
                                    prayer,
                                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : null),
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _weeklyPrayers[_currentWeek]!.add(prayer);
                                      } else {
                                        _weeklyPrayers[_currentWeek]!.remove(prayer);
                                      }
                                    });
                                  },
                                  activeColor: isDark ? Colors.white70 : Colors.deepPurple,
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasSelectedWeekCount = false;
                            });
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: Text(LocalizationService.instance.translate('change_weeks')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.deepPurple,
                            side: BorderSide(color: isDark ? Colors.white70 : Colors.deepPurple),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _savePrayers,
                          icon: const Icon(Icons.save),
                          label: Text(LocalizationService.instance.translate('save_prayers')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white70 : Colors.deepPurple,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
