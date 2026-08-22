import 'package:intl/intl.dart';

class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  String get title => '$name ($code)';

  static const defaultCode = 'AED';

  static final NumberFormat _amount = NumberFormat('#,##0.##');

  static const List<AppCurrency> all = [
    AppCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    AppCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    AppCurrency(code: 'USD', name: 'US Dollar', symbol: r'$'),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
    AppCurrency(code: 'GBP', name: 'British Pound', symbol: '£'),
    AppCurrency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
    AppCurrency(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼'),
    AppCurrency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'د.ك'),
    AppCurrency(code: 'OMR', name: 'Omani Rial', symbol: 'ر.ع.'),
    AppCurrency(code: 'BHD', name: 'Bahraini Dinar', symbol: 'د.ب'),
    AppCurrency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨'),
    AppCurrency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
    AppCurrency(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs'),
    AppCurrency(code: 'NPR', name: 'Nepalese Rupee', symbol: 'Rs'),
    AppCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
    AppCurrency(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
    AppCurrency(code: 'SGD', name: 'Singapore Dollar', symbol: r'$'),
    AppCurrency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    AppCurrency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    AppCurrency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£'),
    AppCurrency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    AppCurrency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
    AppCurrency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    AppCurrency(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
  ];

  static AppCurrency of(String? code) {
    final normalized = normalize(code);
    for (final currency in all) {
      if (currency.code == normalized) return currency;
    }
    return AppCurrency(code: normalized, name: normalized, symbol: normalized);
  }

  static String normalize(String? code) {
    final value = (code ?? '').trim().toUpperCase();
    if (RegExp(r'^[A-Z]{3}$').hasMatch(value)) return value;
    return defaultCode;
  }

  static String format(num value, {String? currency}) {
    return '${normalize(currency)} ${_amount.format(value)}';
  }

  static String prefix(String? currency) => '${normalize(currency)}  ';
}
