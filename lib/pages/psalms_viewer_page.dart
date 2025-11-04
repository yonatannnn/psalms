import 'package:flutter/material.dart';
import '../services/psalms_data_service.dart';
import '../services/localization_service.dart';
import '../services/font_size_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart' deferred as share_plus;

class PsalmData {
  final int chapter;
  final String content;

  PsalmData({
    required this.chapter,
    required this.content,
  });
}

class PsalmsViewerPage extends StatefulWidget {
  final List<int> chapters;
  final String title;

  const PsalmsViewerPage({
    super.key,
    required this.chapters,
    required this.title,
  });

  @override
  State<PsalmsViewerPage> createState() => _PsalmsViewerPageState();
}

class _PsalmsViewerPageState extends State<PsalmsViewerPage> {
  List<PsalmData> _psalmsContent = [];
  bool _isLoading = true;
  // Track which verses have their number visible. Key format: "chapter:verse"
  final Set<String> _visibleVerseNumbers = <String>{};

  @override
  void initState() {
    super.initState();
    _loadPsalms();
  }

  // Parse a psalm block into (verseNumber, text) pairs.
  // We expect verses to start with a number then a space: e.g. "1 text..." on each line.
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
        // If the line doesn't start with a number, append to the previous verse if any
        if (verses.isNotEmpty) {
          final last = verses.removeLast();
          verses.add(MapEntry(last.key, (last.value + ' ' + line.trim()).trim()));
        } else if (line.trim().isNotEmpty) {
          verses.add(const MapEntry(0, ''));
          final last = verses.removeLast();
          verses.add(MapEntry(last.key, line.trim()));
        }
      }
    }
    return verses;
  }

  void _loadPsalms() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      List<PsalmData> psalms = [];
      final lang = LocalizationService.instance.currentLanguage;
      for (int chapter = widget.chapters.first; chapter <= widget.chapters.last; chapter++) {
        final content = PsalmsDataService.getPsalmByLanguage(lang, chapter);
        if (content != null) {
          psalms.add(PsalmData(
            chapter: chapter,
            content: content,
          ));
        }
      }
      
      setState(() {
        _psalmsContent = psalms;
        _isLoading = false;
      });
    });
  }

  bool _sharePackageLoaded = false;
  
  Future<void> _loadSharePackage() async {
    if (!_sharePackageLoaded) {
      await share_plus.loadLibrary();
      _sharePackageLoaded = true;
    }
  }
  
  Future<void> _shareChapter(PsalmData psalm) async {
    await _loadSharePackage();
    
    final isAmharic = LocalizationService.instance.currentLanguage == LocalizationService.amharic;
    final verses = _parseVerses(psalm.content);
    
    final StringBuffer shareText = StringBuffer();
    shareText.writeln(isAmharic ? 'መዝሙር ${psalm.chapter}' : 'Psalm ${psalm.chapter}');
    shareText.writeln('');
    
    for (final verse in verses) {
      if (verse.key != 0) {
        shareText.writeln('${verse.key}. ${verse.value}');
      } else {
        shareText.writeln(verse.value);
      }
    }
    
    share_plus.Share.share(shareText.toString(), subject: isAmharic ? 'መዝሙር ${psalm.chapter}' : 'Psalm ${psalm.chapter}');
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmharic = LocalizationService.instance.currentLanguage == LocalizationService.amharic;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: isDark ? Colors.black87 : null,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Container(
        color: isDark ? Colors.black : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Psalms...',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    final lang = LocalizationService.instance.currentLanguage;
    final isAmharic = lang == LocalizationService.amharic;

    if (_psalmsContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Psalms available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'The selected Psalms are not available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Psalms Content
          ..._psalmsContent.map((psalm) => _buildPsalmCard(psalm)),
        ],
      ),
    );
  }

  Widget _buildPsalmCard(PsalmData psalm) {
    final isAmharic = LocalizationService.instance.currentLanguage == LocalizationService.amharic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Psalm Header with Share button
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : Colors.deepPurple.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isAmharic ? 'መዝሙር ${psalm.chapter}' : 'Psalm ${psalm.chapter}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.share, color: isDark ? Colors.white70 : Colors.deepPurple),
                  onPressed: () => _shareChapter(psalm),
                  tooltip: LocalizationService.instance.translate('share_chapter'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Psalm Content (render verse number and text in separate columns)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _parseVerses(psalm.content).map((e) {
                  final verseNum = e.key;
                  final verseKey = '${psalm.chapter}:$verseNum';
                  final showNum = verseNum != 0 && _visibleVerseNumbers.contains(verseKey);
                  final lang = LocalizationService.instance.currentLanguage;
                  return ValueListenableBuilder<double>(
                    valueListenable: FontSizeService.instance.fontSize,
                    builder: (context, fontSize, _) {
                      final bodyStyle = (lang == LocalizationService.amharic)
                          ? GoogleFonts.notoSerifEthiopic(
                              fontSize: fontSize,
                              height: 1.6,
                              color: isDark ? Colors.white : Colors.black87,
                            )
                          : GoogleFonts.notoSerif(
                              fontSize: fontSize,
                              height: 1.6,
                              color: isDark ? Colors.white : Colors.black87,
                            );
                      final numStyle = (lang == LocalizationService.amharic)
                          ? GoogleFonts.notoSerifEthiopic(
                              fontSize: fontSize * 0.875, // Verse number slightly smaller
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            )
                          : GoogleFonts.notoSerif(
                              fontSize: fontSize * 0.875,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            if (verseNum == 0) return; // skip header/footer lines
                            setState(() {
                              if (_visibleVerseNumbers.contains(verseKey)) {
                                _visibleVerseNumbers.remove(verseKey);
                              } else {
                                _visibleVerseNumbers.add(verseKey);
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
                                child: Text(
                                  e.value,
                                  style: bodyStyle,
                                ),
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
    );
  }
}
