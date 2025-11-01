import 'package:equatable/equatable.dart';
import '../models/sunday_prayers_model.dart';

abstract class SundayPrayersState extends Equatable {
  const SundayPrayersState();

  @override
  List<Object?> get props => [];
}

class SundayPrayersInitial extends SundayPrayersState {}

class SundayPrayersLoading extends SundayPrayersState {}

class SundayPrayersLoaded extends SundayPrayersState {
  final SundayPrayersModel prayers;

  const SundayPrayersLoaded({required this.prayers});

  @override
  List<Object?> get props => [prayers];
}

class SundayPrayersSaved extends SundayPrayersState {
  final SundayPrayersModel prayers;

  const SundayPrayersSaved({required this.prayers});

  @override
  List<Object?> get props => [prayers];
}

class SundayPrayersUpdated extends SundayPrayersState {
  final SundayPrayersModel prayers;

  const SundayPrayersUpdated({required this.prayers});

  @override
  List<Object?> get props => [prayers];
}

class SundayPrayersError extends SundayPrayersState {
  final String message;

  const SundayPrayersError({required this.message});

  @override
  List<Object?> get props => [message];
}
