import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateCurrencyCode extends SettingsEvent {
  final String code;

  const UpdateCurrencyCode(this.code);

  @override
  List<Object> get props => [code];
}
