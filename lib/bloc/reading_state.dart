import 'package:equatable/equatable.dart';
import '../models/reading_preferences_model.dart';

abstract class ReadingState extends Equatable {
  const ReadingState();

  @override
  List<Object?> get props => [];
}

class ReadingInitial extends ReadingState {}

class ReadingLoading extends ReadingState {}

class ReadingPreferencesLoaded extends ReadingState {
  final ReadingPreferencesModel preferences;

  const ReadingPreferencesLoaded({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

class ReadingPreferencesSaved extends ReadingState {
  final ReadingPreferencesModel preferences;

  const ReadingPreferencesSaved({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

class ReadingPreferencesUpdated extends ReadingState {
  final ReadingPreferencesModel preferences;

  const ReadingPreferencesUpdated({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

class ReadingPreferencesNotFound extends ReadingState {}

class ReadingError extends ReadingState {
  final String message;

  const ReadingError({required this.message});

  @override
  List<Object?> get props => [message];
}

