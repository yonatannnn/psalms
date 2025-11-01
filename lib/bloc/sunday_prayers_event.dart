import 'package:equatable/equatable.dart';

abstract class SundayPrayersEvent extends Equatable {
  const SundayPrayersEvent();

  @override
  List<Object?> get props => [];
}

class SaveSundayPrayers extends SundayPrayersEvent {
  final String userId;
  final Map<int, List<String>> weeklyPrayers;

  const SaveSundayPrayers({
    required this.userId,
    required this.weeklyPrayers,
  });

  @override
  List<Object?> get props => [userId, weeklyPrayers];
}

class LoadSundayPrayers extends SundayPrayersEvent {
  final String userId;

  const LoadSundayPrayers({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateSundayPrayers extends SundayPrayersEvent {
  final String userId;
  final Map<int, List<String>> weeklyPrayers;

  const UpdateSundayPrayers({
    required this.userId,
    required this.weeklyPrayers,
  });

  @override
  List<Object?> get props => [userId, weeklyPrayers];
}
