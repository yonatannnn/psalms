import 'package:equatable/equatable.dart';

class ReadingPreferencesModel extends Equatable {
  final String userId;
  final int dailyChapterCount;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Optional per-day chapter counts (keys: 'mon'...'sat')
  final Map<String, int>? perDayChapterCounts;

  const ReadingPreferencesModel({
    required this.userId,
    required this.dailyChapterCount,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.perDayChapterCounts,
  });

  factory ReadingPreferencesModel.fromJson(Map<String, dynamic> json) {
    return ReadingPreferencesModel(
      userId: json['userId'] as String,
      dailyChapterCount: json['dailyChapterCount'] as int,
      startDate: DateTime.parse(json['startDate'] as String).toLocal(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      perDayChapterCounts: (json['perDayChapterCounts'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dailyChapterCount': dailyChapterCount,
      'startDate': startDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (perDayChapterCounts != null) 'perDayChapterCounts': perDayChapterCounts,
    };
  }

  ReadingPreferencesModel copyWith({
    String? userId,
    int? dailyChapterCount,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? perDayChapterCounts,
  }) {
    return ReadingPreferencesModel(
      userId: userId ?? this.userId,
      dailyChapterCount: dailyChapterCount ?? this.dailyChapterCount,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      perDayChapterCounts: perDayChapterCounts ?? this.perDayChapterCounts,
    );
  }

  @override
  List<Object?> get props => [userId, dailyChapterCount, startDate, createdAt, updatedAt, perDayChapterCounts];
}

