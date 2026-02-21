import 'package:intl/intl.dart';

class CurrencyFormatter {
  static NumberFormat getFormatter(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
        return NumberFormat.currency(locale: 'hi_IN', symbol: '₹');
      case 'USD':
      default:
        return NumberFormat.currency(locale: 'en_US', symbol: '\$');
    }
  }

  static String format(double amount, String currencyCode) =>
      getFormatter(currencyCode).format(amount);

  static String getSymbol(String currencyCode) =>
      currencyCode == 'INR' ? '₹' : '\$';
}
