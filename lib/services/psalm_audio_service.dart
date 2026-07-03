import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'psalm_audio_timestamps.dart';
import 'localization_service.dart';

/// Plays a single Amharic psalm chapter, or a continuous range of chapters,
/// by clipping the one continuous recording to [start(from), end(to)).
///
/// The recording is downloaded from [PsalmAudioTimestamps.remoteUrl] to the
/// device once (on first play) and reused offline afterwards.
class PsalmAudioService {
  PsalmAudioService._();
  static final PsalmAudioService instance = PsalmAudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// The selection currently loaded in the player as (from, to) chapters,
  /// or null when nothing is loaded. A single chapter is (c, c).
  final ValueNotifier<(int, int)?> current = ValueNotifier<(int, int)?>(null);

  /// True while the one-time full-file download is in progress.
  final ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);

  /// Download progress 0.0..1.0 (only meaningful while [isDownloading]).
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0);

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Whether audio is usable (URL + real timestamps configured).
  bool get isAvailable => PsalmAudioTimestamps.isConfigured;

  /// True when the given selection is the one currently loaded.
  bool isCurrent(int from, int to) => current.value == (from, to);

  /// Play/pause toggle for a chapter or a chapter range [from..to].
  /// Loads the selection first if it isn't the current one.
  Future<void> toggle(int from, [int? to]) async {
    final sel = (from, to ?? from);
    if (current.value == sel) {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
      return;
    }
    await _load(sel.$1, sel.$2);
    await _player.play();
  }

  /// Human-readable title for a selection, used in the player & notification.
  String label(int from, int to) {
    final isAm =
        LocalizationService.instance.currentLanguage == LocalizationService.amharic;
    if (isAm) return from == to ? 'መዝሙር $from' : 'መዝሙር $from - $to';
    return from == to ? 'Psalm $from' : 'Psalms $from - $to';
  }

  Future<void> _load(int from, int to) async {
    current.value = (from, to);
    final file = await _ensureDownloaded();
    final start = PsalmAudioTimestamps.startOf(from);
    final end = PsalmAudioTimestamps.endOf(to); // end of the last chapter
    final isAm =
        LocalizationService.instance.currentLanguage == LocalizationService.amharic;
    final source = ClippingAudioSource(
      child: AudioSource.uri(Uri.file(file.path)),
      start: start,
      end: end,
      tag: MediaItem(
        id: '$from-$to',
        album: isAm ? 'መዝሙረ ዳዊት' : 'Mezmure Dawit',
        title: label(from, to),
        artist: isAm ? 'መዝሙረ ዳዊት' : 'Psalms of David',
      ),
    );
    try {
      await _player.setAudioSource(source);
    } catch (e) {
      // The cached file may be corrupt — drop it so the next attempt re-downloads.
      _verifiedThisSession = false;
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<File> _localFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/psalms_full_am.m4a');
  }

  // Once we've confirmed the cached file is the right size this session,
  // we don't re-check it on every play.
  bool _verifiedThisSession = false;

  /// Ensures the FULL recording is present on disk and complete, downloading
  /// it once. Guards against truncated/partial files (interrupted downloads)
  /// that would otherwise be treated as a finished download forever.
  Future<File> _ensureDownloaded() async {
    final file = await _localFile();
    final part = File('${file.path}.part');

    // Reuse an existing file only if it matches the remote size.
    if (await file.exists()) {
      if (_verifiedThisSession) return file;
      final expected = await _remoteSize();
      final local = await file.length();
      if (expected == null || local == expected) {
        // expected == null => offline; trust the existing file rather than
        // forcing a re-download that would also fail offline.
        _verifiedThisSession = true;
        return file;
      }
      await file.delete(); // wrong size => partial/corrupt, re-download
    }

    isDownloading.value = true;
    downloadProgress.value = 0;
    final client = http.Client();
    try {
      final request =
          http.Request('GET', Uri.parse(PsalmAudioTimestamps.remoteUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      // Download to a .part file; only promote to the real name when complete.
      if (await part.exists()) await part.delete();
      final sink = part.openWrite();
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) downloadProgress.value = received / total;
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      // Verify completeness before promoting.
      if (total > 0 && received != total) {
        await part.delete();
        throw HttpException('Incomplete download ($received/$total bytes)');
      }
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      _verifiedThisSession = true;
      return file;
    } catch (e) {
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close();
      isDownloading.value = false;
    }
  }

  /// HEAD the remote file to learn its size; null if unreachable/offline.
  Future<int?> _remoteSize() async {
    try {
      final resp = await http
          .head(Uri.parse(PsalmAudioTimestamps.remoteUrl))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final len = resp.headers['content-length'];
      return len == null ? null : int.tryParse(len);
    } catch (_) {
      return null;
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Jump forward (or backward, with a negative delta) relative to the current
  /// position, clamped to the clip bounds.
  Future<void> seekRelative(Duration delta) async {
    final dur = _player.duration ?? Duration.zero;
    var target = _player.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    await _player.seek(target);
  }

  Future<void> stop() async {
    await _player.stop();
    current.value = null;
  }

  void dispose() {
    _player.dispose();
  }
}
