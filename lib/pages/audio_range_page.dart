import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/psalm_audio_service.dart';
import '../widgets/psalm_audio_controls.dart';

/// Lets the user manually choose a start and end chapter and play that whole
/// span of the Amharic recording as one continuous audio.
class AudioRangePage extends StatefulWidget {
  const AudioRangePage({super.key});

  @override
  State<AudioRangePage> createState() => _AudioRangePageState();
}

class _AudioRangePageState extends State<AudioRangePage> {
  int _from = 1;
  int _to = 1;

  bool get _isAm =>
      LocalizationService.instance.currentLanguage == LocalizationService.amharic;

  String _psalmLabel(int from, int to) {
    if (_isAm) {
      return from == to ? 'መዝሙር $from' : 'መዝሙር $from - $to';
    }
    return from == to ? 'Psalm $from' : 'Psalms $from - $to';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? Colors.white : Colors.deepPurple;
    final available = PsalmAudioService.instance.isAvailable;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(_isAm ? 'ድምፅ አጫውት' : 'Play Audio Range'),
      ),
      body: SafeArea(
        child: !available
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _isAm
                        ? 'ድምፅ በአሁኑ ጊዜ አይገኝም።'
                        : 'Audio is not available right now.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isAm
                          ? 'የሚነበቡትን መዝሙራት ምረጥ'
                          : 'Choose the chapters to play',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _chapterPicker(
                            label: _isAm ? 'ከ' : 'From',
                            value: _from,
                            isDark: isDark,
                            onChanged: (v) {
                              setState(() {
                                _from = v;
                                if (_to < _from) _to = _from;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _chapterPicker(
                            label: _isAm ? 'እስከ' : 'To',
                            value: _to,
                            min: _from,
                            isDark: isDark,
                            onChanged: (v) => setState(() => _to = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.deepPurple.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _psalmLabel(_from, _to),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Keyed so the buttons rebuild for each new selection.
                          PsalmPlayButton(
                            key: ValueKey('play_${_from}_$_to'),
                            from: _from,
                            to: _to,
                            iconSize: 56,
                            color: accent,
                          ),
                          PsalmSeekBar(
                            key: ValueKey('bar_${_from}_$_to'),
                            from: _from,
                            to: _to,
                            color: accent,
                            textColor:
                                isDark ? Colors.white60 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAm
                          ? 'ከ$_from እስከ $_to ድረስ ያሉትን መዝሙራት በተከታታይ ያጫውታል።'
                          : 'Plays Psalms $_from through $_to back to back.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _chapterPicker({
    required String label,
    required int value,
    required bool isDark,
    required ValueChanged<int> onChanged,
    int min = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.deepPurple,
              ),
              items: [
                for (int c = min; c <= 150; c++)
                  DropdownMenuItem(value: c, child: Text('$c')),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
