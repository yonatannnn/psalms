import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/psalm_audio_service.dart';

/// A play/pause button for a chapter (from==to) or a chapter range [from..to].
/// Reflects the shared player's state: one-time download progress, buffering,
/// and play/pause, but only when this exact selection is the active one.
class PsalmPlayButton extends StatelessWidget {
  final int from;
  final int to;
  final double iconSize;
  final Color color;

  const PsalmPlayButton({
    super.key,
    required this.from,
    required this.to,
    required this.color,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final audio = PsalmAudioService.instance;
    return ValueListenableBuilder<(int, int)?>(
      valueListenable: audio.current,
      builder: (context, current, _) {
        final isThis = current == (from, to);
        return ValueListenableBuilder<bool>(
          valueListenable: audio.isDownloading,
          builder: (context, downloading, __) {
            if (isThis && downloading) {
              return ValueListenableBuilder<double>(
                valueListenable: audio.downloadProgress,
                builder: (context, progress, ___) => Padding(
                  padding: EdgeInsets.all(iconSize * 0.18),
                  child: SizedBox(
                    width: iconSize * 0.72,
                    height: iconSize * 0.72,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                      value: progress > 0 ? progress : null,
                    ),
                  ),
                ),
              );
            }
            return StreamBuilder<PlayerState>(
              stream: audio.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final isLoading = isThis &&
                    (state?.processingState == ProcessingState.loading ||
                        state?.processingState == ProcessingState.buffering);
                final isPlaying = isThis &&
                    (state?.playing ?? false) &&
                    state?.processingState != ProcessingState.completed;
                if (isLoading) {
                  return Padding(
                    padding: EdgeInsets.all(iconSize * 0.18),
                    child: SizedBox(
                      width: iconSize * 0.72,
                      height: iconSize * 0.72,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    ),
                  );
                }
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: iconSize + 12,
                    minHeight: iconSize + 12,
                  ),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: color,
                    size: iconSize,
                  ),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await audio.toggle(from, to);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Audio unavailable: $e')),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// A seek bar with elapsed/total time, visible only while [from..to] is the
/// active selection in the shared player.
class PsalmSeekBar extends StatelessWidget {
  final int from;
  final int to;
  final Color color;
  final Color textColor;

  const PsalmSeekBar({
    super.key,
    required this.from,
    required this.to,
    required this.color,
    required this.textColor,
  });

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audio = PsalmAudioService.instance;
    return ValueListenableBuilder<(int, int)?>(
      valueListenable: audio.current,
      builder: (context, current, _) {
        if (current != (from, to)) return const SizedBox.shrink();
        return StreamBuilder<Duration?>(
          stream: audio.durationStream,
          builder: (context, durSnap) {
            final total = durSnap.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: audio.positionStream,
              builder: (context, posSnap) {
                var pos = posSnap.data ?? Duration.zero;
                if (pos > total) pos = total;
                final maxMs = total.inMilliseconds.toDouble();
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: color,
                        thumbColor: color,
                      ),
                      child: Slider(
                        value: maxMs == 0
                            ? 0
                            : pos.inMilliseconds
                                .clamp(0, total.inMilliseconds)
                                .toDouble(),
                        max: maxMs == 0 ? 1 : maxMs,
                        onChanged: maxMs == 0
                            ? null
                            : (v) =>
                                audio.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(pos),
                              style: TextStyle(fontSize: 12, color: textColor)),
                          Text(_fmt(total),
                              style: TextStyle(fontSize: 12, color: textColor)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
