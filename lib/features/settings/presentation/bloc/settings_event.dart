import 'package:equatable/equatable.dart';

import '../../domain/app_currency.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateCurrency extends SettingsEvent {
  const UpdateCurrency(this.currency);

  final AppCurrency currency;

  @override
  List<Object?> get props => [currency];
}