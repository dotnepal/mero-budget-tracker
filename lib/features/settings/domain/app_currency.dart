enum AppCurrency {
  usd('USD', r'$'),
  gbp('GBP', '£'),
  thb('THB', '฿'),
  npr('NPR', 'रू');

  const AppCurrency(this.code, this.symbol);

  final String code;
  final String symbol;

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.usd,
    );
  }
}