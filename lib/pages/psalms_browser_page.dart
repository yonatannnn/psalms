import 'package:flutter/material.dart';
import '../services/psalms_data_service.dart';
import '../services/localization_service.dart';
import 'psalms_viewer_page.dart';

class PsalmsBrowserPage extends StatefulWidget {
  const PsalmsBrowserPage({super.key});

  @override
  State<PsalmsBrowserPage> createState() => _PsalmsBrowserPageState();
}

class _PsalmsBrowserPageState extends State<PsalmsBrowserPage> {
  // Drawer-triggered browser shows only chapters list (no text field)

  void _openChapter(int chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PsalmsViewerPage(
          chapters: [chapter, chapter],
          title: _titleForRange(chapter, chapter),
        ),
      ),
    );
  }

  String _titleForRange(int start, int end) {
    final lang = LocalizationService.instance.currentLanguage;
    final isAm = lang == LocalizationService.amharic;
    final psalmsWord = isAm ? 'መዝሙረ ዳዊት' : 'Psalms';
    return '${LocalizationService.instance.translate('todays_reading')} - $psalmsWord $start-$end';
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguage;
    final isAm = lang == LocalizationService.amharic;
    final available = PsalmsDataService.getAvailableChapters();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(isAm ? 'መዝሙረ ዳዊት' : 'Psalms'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final ch = available[index];
                  final labelTop = isAm
                      ? LocalizationService.instance.translate('psalm_word')
                      : 'Psalm';
                  final cardColor = Theme.of(context).brightness == Brightness.dark
                      ? Colors.black87
                      : Colors.deepPurple.shade50;
                  final borderColor = Theme.of(context).brightness == Brightness.dark
                      ? Colors.black87
                      : Colors.deepPurple.shade200;
                  final textColor = Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.deepPurple;
                  return InkWell(
                    onTap: () => _openChapter(ch),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labelTop,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$ch',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


