import 'package:flutter_bloc/flutter_bloc.dart';
import 'reading_event.dart';
import 'reading_state.dart';
import '../services/reading_service.dart';
import '../models/reading_preferences_model.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  final ReadingService _readingService;

  ReadingBloc({required ReadingService readingService})
      : _readingService = readingService,
        super(ReadingInitial()) {
    on<LoadReadingPreferences>(_onLoadReadingPreferences);
    on<SaveReadingPreferences>(_onSaveReadingPreferences);
    on<UpdateReadingPreferences>(_onUpdateReadingPreferences);
    on<CheckReadingPreferences>(_onCheckReadingPreferences);
  }

  Future<void> _onLoadReadingPreferences(
    LoadReadingPreferences event,
    Emitter<ReadingState> emit,
  ) async {
    try {
      emit(ReadingLoading());
      
      final preferences = await _readingService.getReadingPreferences(event.userId);
      
      if (preferences != null) {
        emit(ReadingPreferencesLoaded(preferences: preferences));
      } else {
        emit(ReadingPreferencesNotFound());
      }
    } catch (e) {
      emit(ReadingError(message: e.toString()));
    }
  }

  Future<void> _onSaveReadingPreferences(
    SaveReadingPreferences event,
    Emitter<ReadingState> emit,
  ) async {
    try {
      print('BLoC: Starting to save reading preferences');
      emit(ReadingLoading());
      
      final preferences = ReadingPreferencesModel(
        userId: event.userId,
        dailyChapterCount: event.dailyChapterCount,
        startDate: event.startDate,
        perDayChapterCounts: event.perDayChapterCounts,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('BLoC: Calling reading service to save preferences');
      await _readingService.saveReadingPreferences(preferences);
      print('BLoC: Preferences saved successfully, emitting ReadingPreferencesSaved state');
      print('BLoC: About to emit ReadingPreferencesSaved with preferences: $preferences');
      emit(ReadingPreferencesSaved(preferences: preferences));
      print('BLoC: ReadingPreferencesSaved state emitted successfully');
    } catch (e) {
      print('BLoC: Error saving preferences: $e');
      emit(ReadingError(message: e.toString()));
    }
  }

  Future<void> _onUpdateReadingPreferences(
    UpdateReadingPreferences event,
    Emitter<ReadingState> emit,
  ) async {
    try {
      emit(ReadingLoading());
      
      // First get existing preferences
      final existingPreferences = await _readingService.getReadingPreferences(event.userId);
      
      if (existingPreferences != null) {
        final updatedPreferences = existingPreferences.copyWith(
          dailyChapterCount: event.dailyChapterCount,
          startDate: event.startDate,
          perDayChapterCounts: event.perDayChapterCounts ?? existingPreferences.perDayChapterCounts,
          updatedAt: DateTime.now(),
        );
        
        await _readingService.updateReadingPreferences(updatedPreferences);
        emit(ReadingPreferencesUpdated(preferences: updatedPreferences));
      } else {
        // If no existing preferences, create new ones
        final preferences = ReadingPreferencesModel(
          userId: event.userId,
          dailyChapterCount: event.dailyChapterCount,
          startDate: event.startDate,
          perDayChapterCounts: event.perDayChapterCounts,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _readingService.saveReadingPreferences(preferences);
        emit(ReadingPreferencesSaved(preferences: preferences));
      }
    } catch (e) {
      emit(ReadingError(message: e.toString()));
    }
  }

  Future<void> _onCheckReadingPreferences(
    CheckReadingPreferences event,
    Emitter<ReadingState> emit,
  ) async {
    try {
      emit(ReadingLoading());
      
      final hasPreferences = await _readingService.hasReadingPreferences(event.userId);
      
      if (hasPreferences) {
        final preferences = await _readingService.getReadingPreferences(event.userId);
        if (preferences != null) {
          emit(ReadingPreferencesLoaded(preferences: preferences));
        } else {
          emit(ReadingPreferencesNotFound());
        }
      } else {
        emit(ReadingPreferencesNotFound());
      }
    } catch (e) {
      emit(ReadingError(message: e.toString()));
    }
  }
}

