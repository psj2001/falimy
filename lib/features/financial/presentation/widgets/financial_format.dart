import 'package:intl/intl.dart';

class FinancialFormat {
  static final NumberFormat _amount = NumberFormat('#,##0.##');
  static final DateFormat _updated = DateFormat('MMM d yyyy');
  static final DateFormat _entryDate = DateFormat('d MMMM yyyy');
  static final DateFormat _entryTime = DateFormat('h:mm a');
  static final DateFormat _pickerDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _pickerTime = DateFormat('h:mm a');

  static String amount(num value) => _amount.format(value);

  static String bookMeta({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final same = createdAt.year == updatedAt.year &&
        createdAt.month == updatedAt.month &&
        createdAt.day == updatedAt.day &&
        createdAt.hour == updatedAt.hour &&
        createdAt.minute == updatedAt.minute;
    if (same) {
      return 'Created on ${_updated.format(createdAt)}';
    }
    return 'Updated on ${_updated.format(updatedAt)}';
  }

  static String entryDay(DateTime dt) => _entryDate.format(dt);

  static String entryTime(DateTime dt) => _entryTime.format(dt).toLowerCase();

  static String pickerDate(DateTime dt) => _pickerDate.format(dt);

  static String pickerTime(DateTime dt) => _pickerTime.format(dt).toLowerCase();

  static String dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
