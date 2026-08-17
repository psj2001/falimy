import 'package:intl/intl.dart';

class BudgetFormat {
  static final NumberFormat _amount = NumberFormat('#,##0.##');
  static final DateFormat _month = DateFormat('MMMM yyyy');

  static String money(num value, {String currency = 'AED'}) {
    return '$currency ${_amount.format(value)}';
  }

  static String percent(num value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String monthTitle(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final month = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (year == null || month == null) return monthKey;
    return _month.format(DateTime(year, month, 1));
  }
}
