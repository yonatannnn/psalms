import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/localization_service.dart';
import '../services/font_size_service.dart';
import 'daily_chapter_preferences_page.dart';
import 'reading_preferences_page.dart';
import 'sunday_prayers_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  final UserModel user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmharic = LocalizationService.instance.currentLanguage == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'ቅንብሮች' : 'Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            // Font Size Controls
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAmharic ? 'የፊደል መጠን' : 'Font Size',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: FontSizeService.instance.fontSize,
                          builder: (context, fontSize, _) {
                            return Text(
                              fontSize.toInt().toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await FontSizeService.instance.decreaseFontSize();
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: isDark ? Colors.white70 : Colors.deepPurple,
                          tooltip: isAmharic ? 'አነስ' : 'Decrease',
                        ),
                        ValueListenableBuilder<double>(
                          valueListenable: FontSizeService.instance.fontSize,
                          builder: (context, fontSize, _) {
                            final minSize = FontSizeService.instance.minFontSize;
                            final maxSize = FontSizeService.instance.maxFontSize;
                            return Expanded(
                              child: Slider(
                                value: fontSize,
                                min: minSize,
                                max: maxSize,
                                divisions: ((maxSize - minSize) / FontSizeService.instance.stepSize).round(),
                                label: fontSize.toInt().toString(),
                                onChanged: (value) async {
                                  await FontSizeService.instance.setFontSize(value);
                                },
                                activeColor: isDark ? Colors.white70 : Colors.deepPurple,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () async {
                            await FontSizeService.instance.increaseFontSize();
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: isDark ? Colors.white70 : Colors.deepPurple,
                          tooltip: isAmharic ? 'ጨምር' : 'Increase',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(isAmharic ? 'በቀን የሚነበቡ ምዕራፎች' : 'Per-specific-day Chapters'),
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DailyChapterPreferencesPage(user: user),
                  ),
                );
                if (result == true) {
                  Navigator.of(context).pop(result);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(LocalizationService.instance.translate('edit_preferences')),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReadingPreferencesPage(user: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.church),
              title: Text(LocalizationService.instance.translate('set_sunday_prayers')),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SundayPrayersPage(user: user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

