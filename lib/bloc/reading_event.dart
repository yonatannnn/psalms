import 'package:equatable/equatable.dart';

abstract class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object?> get props => [];
}

class LoadReadingPreferences extends ReadingEvent {
  final String userId;

  const LoadReadingPreferences({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class SaveReadingPreferences extends ReadingEvent {
  final String userId;
  final int dailyChapterCount;
  final DateTime startDate;
  final Map<String, int>? perDayChapterCounts;

  const SaveReadingPreferences({
    required this.userId,
    required this.dailyChapterCount,
    required this.startDate,
    this.perDayChapterCounts,
  });

  @override
  List<Object?> get props => [userId, dailyChapterCount, startDate, perDayChapterCounts];
}

class UpdateReadingPreferences extends ReadingEvent {
  final String userId;
  final int dailyChapterCount;
  final DateTime startDate;
  final Map<String, int>? perDayChapterCounts;

  const UpdateReadingPreferences({
    required this.userId,
    required this.dailyChapterCount,
    required this.startDate,
    this.perDayChapterCounts,
  });

  @override
  List<Object?> get props => [userId, dailyChapterCount, startDate, perDayChapterCounts];
}

class CheckReadingPreferences extends ReadingEvent {
  final String userId;

  const CheckReadingPreferences({required this.userId});

  @override
  List<Object?> get props => [userId];
}

