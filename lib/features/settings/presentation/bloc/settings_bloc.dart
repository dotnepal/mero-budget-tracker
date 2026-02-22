import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateCurrencyCode>(_onUpdateCurrencyCode);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateCurrencyCode(
    UpdateCurrencyCode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.saveCurrencyCode(event.code);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
