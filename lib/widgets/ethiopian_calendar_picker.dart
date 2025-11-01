import 'package:flutter/material.dart';
import '../services/ethiopian_calendar_service.dart';
import '../services/localization_service.dart';

class EthiopianCalendarPicker extends StatefulWidget {
  final EthiopianDate initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String language;
  final Function(EthiopianDate) onDateSelected;

  const EthiopianCalendarPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.language,
    required this.onDateSelected,
  });

  @override
  State<EthiopianCalendarPicker> createState() => _EthiopianCalendarPickerState();
}

class _EthiopianCalendarPickerState extends State<EthiopianCalendarPicker> {
  late EthiopianDate _selectedDate;
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentYear = widget.initialDate.year;
    _currentMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? Colors.black : null,
      child: Container(
        width: 350,
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header with month/year navigation
            _buildHeader(isDark),
            const SizedBox(height: 16),
            // Calendar grid
            Expanded(child: _buildCalendarGrid(isDark)),
            const SizedBox(height: 16),
            // Action buttons
            _buildActionButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final monthName = widget.language == 'am' 
        ? _getEthiopianMonthNameAmharic(_currentMonth)
        : _getEthiopianMonthNameEnglish(_currentMonth);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : null),
        ),
        Text(
          '$monthName $_currentYear',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : null,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: Icon(Icons.chevron_right, color: isDark ? Colors.white : null),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    // Get the first day of the month and number of days
    final firstDayOfMonth = _getFirstDayOfMonth(_currentYear, _currentMonth);
    final daysInMonth = _getDaysInMonth(_currentYear, _currentMonth);
    
    // Day headers
    final dayHeaders = _getDayHeaders();
    
    return Column(
      children: [
        // Day headers
        Row(
          children: dayHeaders.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white70 : null,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayOfMonth + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isSelected = isCurrentMonth && 
                  dayNumber == _selectedDate.day && 
                  _currentMonth == _selectedDate.month && 
                  _currentYear == _selectedDate.year;
              
              return GestureDetector(
                onTap: isCurrentMonth ? () => _selectDate(dayNumber) : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.deepPurple)
                        : isCurrentMonth
                            ? Colors.transparent
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: isDark ? Colors.white : Colors.deepPurple, width: 2)
                        : Border.all(color: isDark ? Colors.white24 : Colors.transparent, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      isCurrentMonth ? '$dayNumber' : '',
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : isCurrentMonth
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white38 : Colors.grey),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocalizationService.instance.translate('cancel'), style: TextStyle(color: isDark ? Colors.white70 : null)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDateSelected(_selectedDate);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.deepPurple,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
          child: Text(LocalizationService.instance.translate('ok')),
        ),
      ],
    );
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth > 1) {
        _currentMonth--;
      } else {
        _currentMonth = 13; // Pagumen
        _currentYear--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth < 13) {
        _currentMonth++;
      } else {
        _currentMonth = 1; // Meskerem
        _currentYear++;
      }
    });
  }

  void _selectDate(int day) {
    setState(() {
      _selectedDate = EthiopianDate(
        year: _currentYear,
        month: _currentMonth,
        day: day,
        weekday: _getWeekday(_currentYear, _currentMonth, day),
      );
    });
  }

  List<String> _getDayHeaders() {
    if (widget.language == 'am') {
      return ['እሁድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ'];
    } else {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
  }

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

  int _getFirstDayOfMonth(int year, int month) {
    // Get the first day of the Ethiopian month and convert to Gregorian to get the weekday
    final gregorianDate = EthiopianCalendarService.instance.ethiopianToGregorian(
      EthiopianDate(year: year, month: month, day: 1, weekday: 1)
    );
    // Ethiopian week starts on Sunday (0), Gregorian week starts on Monday (1)
    // So we need to adjust: Ethiopian Sunday = 0, Gregorian Sunday = 7
    final gregorianWeekday = gregorianDate.weekday;
    return gregorianWeekday == 7 ? 0 : gregorianWeekday;
  }

  int _getDaysInMonth(int year, int month) {
    // Ethiopian months have 30 days each, except Pagumen which has 5 or 6 days
    if (month == 13) { // Pagumen
      return _isEthiopianLeapYear(year) ? 6 : 5;
    }
    return 30;
  }

  bool _isEthiopianLeapYear(int year) {
    // Ethiopian leap year calculation
    return (year % 4 == 3);
  }

  int _getWeekday(int year, int month, int day) {
    // Get the weekday by converting to Gregorian and using its weekday
    final gregorianDate = EthiopianCalendarService.instance.ethiopianToGregorian(
      EthiopianDate(year: year, month: month, day: day, weekday: 1)
    );
    // Ethiopian week starts on Sunday (0), Gregorian week starts on Monday (1)
    // So we need to adjust: Ethiopian Sunday = 0, Gregorian Sunday = 7
    final gregorianWeekday = gregorianDate.weekday;
    return gregorianWeekday == 7 ? 0 : gregorianWeekday;
  }
}
