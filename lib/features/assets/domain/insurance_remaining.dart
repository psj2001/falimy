import 'package:intl/intl.dart';

final DateFormat assetDateFormat = DateFormat('d MMM yyyy');

DateTime? parseAssetDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return DateTime(iso.year, iso.month, iso.day);
  try {
    final parsed = assetDateFormat.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  } catch (_) {
    return null;
  }
}

class InsuranceRemaining {
  const InsuranceRemaining({
    required this.daysLeft,
    required this.label,
    required this.expired,
    required this.urgent,
  });

  final int daysLeft;
  final String label;
  final bool expired;
  final bool urgent;

  factory InsuranceRemaining.fromEnd(DateTime end, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final expiry = DateTime(end.year, end.month, end.day);
    final daysLeft = expiry.difference(start).inDays;
    return InsuranceRemaining(
      daysLeft: daysLeft,
      label: _labelFor(daysLeft),
      expired: daysLeft < 0,
      urgent: daysLeft >= 0 && daysLeft <= 30,
    );
  }

  static String _labelFor(int daysLeft) {
    if (daysLeft == 0) return 'Expires today';
    final expired = daysLeft < 0;
    final days = daysLeft.abs();
    final span = _span(days);
    if (expired) return 'Expired $span ago';
    return '$span remaining';
  }

  static String _span(int days) {
    if (days < 30) {
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
    if (days < 365) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final yearPart = '$years ${years == 1 ? 'year' : 'years'}';
    if (months == 0) return yearPart;
    return '$yearPart $months ${months == 1 ? 'month' : 'months'}';
  }
}
