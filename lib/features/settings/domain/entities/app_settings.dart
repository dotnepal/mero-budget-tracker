import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String currencyCode;

  const AppSettings({this.currencyCode = 'USD'});

  AppSettings copyWith({String? currencyCode}) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  @override
  List<Object> get props => [currencyCode];
}
