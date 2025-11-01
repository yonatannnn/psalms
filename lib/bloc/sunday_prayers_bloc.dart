import 'package:flutter_bloc/flutter_bloc.dart';
import 'sunday_prayers_event.dart';
import 'sunday_prayers_state.dart';
import '../services/sunday_prayers_service.dart';
import '../models/sunday_prayers_model.dart';

class SundayPrayersBloc extends Bloc<SundayPrayersEvent, SundayPrayersState> {
  final SundayPrayersService _sundayPrayersService;

  SundayPrayersBloc({required SundayPrayersService sundayPrayersService})
      : _sundayPrayersService = sundayPrayersService,
        super(SundayPrayersInitial()) {
    on<SaveSundayPrayers>(_onSaveSundayPrayers);
    on<LoadSundayPrayers>(_onLoadSundayPrayers);
    on<UpdateSundayPrayers>(_onUpdateSundayPrayers);
  }

  Future<void> _onSaveSundayPrayers(
    SaveSundayPrayers event,
    Emitter<SundayPrayersState> emit,
  ) async {
    try {
      emit(SundayPrayersLoading());
      
      final prayers = SundayPrayersModel(
        userId: event.userId,
        weeklyPrayers: event.weeklyPrayers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _sundayPrayersService.saveSundayPrayers(prayers);
      emit(SundayPrayersSaved(prayers: prayers));
    } catch (e) {
      emit(SundayPrayersError(message: e.toString()));
    }
  }

  Future<void> _onLoadSundayPrayers(
    LoadSundayPrayers event,
    Emitter<SundayPrayersState> emit,
  ) async {
    try {
      emit(SundayPrayersLoading());
      
      final prayers = await _sundayPrayersService.getSundayPrayers(event.userId);
      
      if (prayers != null) {
        emit(SundayPrayersLoaded(prayers: prayers));
      } else {
        emit(SundayPrayersError(message: 'No Sunday prayers found'));
      }
    } catch (e) {
      emit(SundayPrayersError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSundayPrayers(
    UpdateSundayPrayers event,
    Emitter<SundayPrayersState> emit,
  ) async {
    try {
      emit(SundayPrayersLoading());
      
      // First get existing prayers
      final existingPrayers = await _sundayPrayersService.getSundayPrayers(event.userId);
      
      if (existingPrayers != null) {
        final updatedPrayers = existingPrayers.copyWith(
          weeklyPrayers: event.weeklyPrayers,
          updatedAt: DateTime.now(),
        );
        
        await _sundayPrayersService.updateSundayPrayers(updatedPrayers);
        emit(SundayPrayersUpdated(prayers: updatedPrayers));
      } else {
        // If no existing prayers, create new ones
        final prayers = SundayPrayersModel(
          userId: event.userId,
          weeklyPrayers: event.weeklyPrayers,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _sundayPrayersService.saveSundayPrayers(prayers);
        emit(SundayPrayersSaved(prayers: prayers));
      }
    } catch (e) {
      emit(SundayPrayersError(message: e.toString()));
    }
  }
}
