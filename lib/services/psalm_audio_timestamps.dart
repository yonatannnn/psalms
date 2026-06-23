/// Start times of each Amharic psalm chapter inside the single continuous
/// recording hosted at [remoteUrl].
///
/// HOW TO USE:
///   1. Compress the recording (mono, ~48 kbps) and upload it to Firebase
///      Storage, then paste its download URL into [remoteUrl] below.
///   2. Replace each '0:00' with that chapter's START time in the recording.
///      Accepted formats: "m:ss", "mm:ss", or "h:mm:ss" (e.g. "1:23", "1:02:05").
///
/// The file is downloaded to the device once on first play, then cached for
/// offline use. The END of a chapter is automatically the START of the next
/// chapter; chapter 150 plays to the end of the file.
class PsalmAudioTimestamps {
  /// Firebase Storage (or any HTTPS) download URL for the full recording.
  /// Leave empty to hide the audio controls until configured.
  static const String remoteUrl =
      'https://pub-d3ef3793c5754c1bb80b42ca8b9f795e.r2.dev/mezmure-dawit-1-30_0Y7uayhV_compressed.m4a';

  // chapter -> start time string. Fill these in.
  static const Map<int, String> _startStrings = {
    1: '0:33',
    2: '1:23',
    3: '2:52',
    4: '3:46',
    5: '4:57',
    6: '6:39',
    7: '7:55',
    8: '10:06',
    9: '11:17',
    10: '16:19',
    11: '17:44',
    12: '18:54',
    13: '19:46',
    14: '21:21',
    15: '22:07',
    16: '23:37',
    17: '25:55',
    18: '31:52',
    19: '33:45',
    20: '34:49',
    21: '36:35',
    22: '40:20',
    23: '41:06',
    24: '42:25',
    25: '44:41',
    26: '45:55',
    27: '47:59',
    28: '49:16',
    29: '50:30',
    30: '51:51',
    31: '55:17',
    32: '56:55',
    33: '59:13',
    34: '1:01:30',
    35: '1:05:02',
    36: '1:06:24',
    37: '1:10:43',
    38: '1:13:05',
    39: '1:14:58',
    40: '1:17:34',
    41: '1:19:23',
    42: '1:21:07',
    43: '1:21:58',
    44: '1:24:47',
    45: '1:27:09',
    46: '1:28:32',
    47: '1:29:35',
    48: '1:31:04',
    49: '1:33:21',
    50: '1:35:54',
    51: '1:38:10',
    52: '1:39:21',
    53: '1:40:23',
    54: '1:41:08',
    55: '1:43:45',
    56: '1:45:12',
    57: '1:46:38',
    58: '1:47:54',
    59: '1:50:04',
    60: '1:51:24',
    61: '1:52:32',
    62: '1:54:08',
    63: '1:55:24',
    64: '1:56:31',
    65: '1:58:18',
    66: '2:00:28',
    67: '2:01:13',
    68: '2:05:43',
    69: '2:09:39',
    70: '2:10:17',
    71: '2:13:19',
    72: '2:15:39',
    73: '2:18:27',
    74: '2:21:06',
    75: '2:22:18',
    76: '2:23:52',
    77: '2:26:06',
    78: '2:33:18',
    79: '2:34:55',
    80: '2:36:55',
    81: '2:38:56',
    82: '2:39:51',
    83: '2:41:33',
    84: '2:43:07',
    85: '2:44:23',
    86: '2:46:22',
    87: '2:47:11',
    88: '2:49:13',
    89: '2:54:16',
    90: '2:56:16',
    91: '2:58:21',
    92: '2:59:54',
    93: '3:00:36',
    94: '3:02:54',
    95: '3:04:13',
    96: '3:05:44',
    97: '3:07:05',
    98: '3:08:11',
    99: '3:09:23',
    100: '3:09:55',
    101: '3:11:02',
    102: '3:13:52',
    103: '3:16:08',
    104: '3:19:51',
    105: '3:23:52',
    106: '3:28:22',
    107: '3:32:22',
    108: '3:33:46',
    109: '3:36:39',
    110: '3:37:30',
    111: '3:38:54',
    112: '3:40:00',
    113: '3:40:52',
    114: '3:43:28',
    115: '3:44:23',
    116: '3:45:19',
    117: '3:45:39',
    118: '3:48:40',
    119: '4:04:15',
    120: '4:04:54',
    121: '4:05:53',
    122: '4:06:45',
    123: '4:07:20',
    124: '4:08:06',
    125: '4:08:48',
    126: '4:09:34',
    127: '4:10:24',
    128: '4:11:06',
    129: '4:12:03',
    130: '4:12:48',
    131: '4:13:33',
    132: '4:15:26',
    133: '4:15:54',
    134: '4:16:18',
    135: '4:18:35',
    136: '4:20:55',
    137: '4:21:58',
    138: '4:23:12',
    139: '4:25:54',
    140: '4:27:26',
    141: '4:29:01',
    142: '4:30:05',
    143: '4:31:41',
    144: '4:33:38',
    145: '4:35:56',
    146: '4:37:14',
    147: '4:38:28',
    148: '4:39:30',
    149: '4:41:09',
    150: '4:42:13',
  };

  /// True once a URL is set and at least one real (non-zero) timestamp exists.
  static bool get isConfigured =>
      remoteUrl.isNotEmpty &&
      _startStrings.values.any((v) => _parse(v) > Duration.zero);

  /// Start offset of [chapter] within the full recording.
  static Duration startOf(int chapter) => _parse(_startStrings[chapter] ?? '0:00');

  /// End offset of [chapter] = start of the next chapter.
  /// Returns null for the last chapter (play to end of file).
  static Duration? endOf(int chapter) {
    final next = _startStrings[chapter + 1];
    return next == null ? null : _parse(next);
  }

  static Duration _parse(String s) {
    final parts =
        s.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    return Duration(seconds: parts.isNotEmpty ? parts[0] : 0);
  }
}
