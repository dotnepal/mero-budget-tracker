import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/app_currency.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateCurrency>(_onUpdateCurrency);
  }

  static const _currencyKey = 'currency';

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final code = await DatabaseHelper.instance.getPreference(_currencyKey);
    final currency = code != null ? AppCurrency.fromCode(code) : AppCurrency.usd;
    emit(SettingsLoaded(currency: currency));
  }

  Future<void> _onUpdateCurrency(
    UpdateCurrency event,
    Emitter<SettingsState> emit,
  ) async {
    await DatabaseHelper.instance.setPreference(_currencyKey, event.currency.code);
    final current = state is SettingsLoaded
        ? (state as SettingsLoaded)
        : const SettingsLoaded();
    emit(current.copyWith(currency: event.currency));
  }
}
