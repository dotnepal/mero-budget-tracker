import 'package:equatable/equatable.dart';

import '../../domain/app_currency.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({this.currency = AppCurrency.usd});

  final AppCurrency currency;

  SettingsLoaded copyWith({AppCurrency? currency}) {
    return SettingsLoaded(currency: currency ?? this.currency);
  }

  @override
  List<Object?> get props => [currency];
}