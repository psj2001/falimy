import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import 'package:falimy/core/currency/app_currency.dart';

final DateFormat paymentReminderDateFormat = DateFormat('d MMM yyyy');

class PaymentReminder extends Equatable {
  const PaymentReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.remindDaysBefore = 1,
    this.monthly = true,
    this.note,
    this.lastPaidOccurrence,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final int remindDaysBefore;
  final bool monthly;
  final String? note;
  final String? lastPaidOccurrence;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get notificationId => id.hashCode & 0x7fffffff;

  String amountLabel([String? currency]) =>
      AppCurrency.format(amount, currency: currency);

  String get inboxId {
    final due = displayDueDate();
    return 'payrem_${id}_${due.year}_${due.month}';
  }

  String inboxMessage([DateTime? now, String? currency]) {
    final due = displayDueDate(now);
    return '${amountLabel(currency)} is due ${DateFormat('d MMM').format(due)}'
        '${monthly ? ' (monthly)' : ''}.';
  }

  String occurrenceKeyFor(DateTime due) =>
      '${due.year}-${due.month.toString().padLeft(2, '0')}';

  DateTime periodDueDate([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    if (!monthly) return dateOnly(dueDate);
    return monthDay(today.year, today.month, dueDate.day);
  }

  bool wasPaidForPeriod([DateTime? now]) {
    return lastPaidOccurrence != null &&
        lastPaidOccurrence == occurrenceKeyFor(periodDueDate(now));
  }

  DateTime nextDueDate([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    if (!monthly) return dateOnly(dueDate);
    var candidate = monthDay(today.year, today.month, dueDate.day);
    if (candidate.isBefore(today) || wasPaidForPeriod(today)) {
      final next = DateTime(today.year, today.month + 1, 1);
      candidate = monthDay(next.year, next.month, dueDate.day);
    }
    return candidate;
  }

  /// Due date shown in the UI, keeping a monthly bill overdue for 2 days.
  DateTime displayDueDate([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    if (!monthly) return dateOnly(dueDate);
    final thisDue = monthDay(today.year, today.month, dueDate.day);
    if (wasPaidForPeriod(today)) {
      return nextDueDate(today);
    }
    if (today.isAfter(thisDue) && today.difference(thisDue).inDays <= 2) {
      return thisDue;
    }
    return nextDueDate(today);
  }

  DateTime nextNotifyAt([DateTime? now]) {
    final due = nextDueDate(now);
    final day = due.subtract(Duration(days: remindDaysBefore));
    return DateTime(day.year, day.month, day.day, 9);
  }

  /// When to fire the OS notification. Null if this one-time reminder is over.
  DateTime? scheduleAt([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = dateOnly(n);
    final due = nextDueDate(n);
    if (!monthly && due.isBefore(today)) return null;
    if (!monthly && wasPaidForPeriod(n)) return null;

    final notify = nextNotifyAt(n);
    if (notify.isAfter(n)) return notify;
    if (!due.isBefore(today)) return n.add(const Duration(seconds: 3));
    return null;
  }

  int daysUntilDue([DateTime? now]) {
    final today = dateOnly(now ?? DateTime.now());
    return displayDueDate(today).difference(today).inDays;
  }

  bool get isUpcoming {
    if (monthly) return true;
    if (wasPaidForPeriod()) return false;
    return daysUntilDue() >= -2;
  }

  bool get isDueSoon {
    final days = daysUntilDue();
    return days >= 0 && days <= 7;
  }

  bool get needsPaymentPrompt {
    if (wasPaidForPeriod()) return false;
    final days = daysUntilDue();
    return days <= 0 && days >= -2;
  }

  bool shouldAppearInInbox([DateTime? now]) {
    if (wasPaidForPeriod(now)) return false;
    final n = now ?? DateTime.now();
    final today = dateOnly(n);
    if (!monthly) {
      final due = dateOnly(dueDate);
      final notifyDay = due.subtract(Duration(days: remindDaysBefore));
      final notify = DateTime(
        notifyDay.year,
        notifyDay.month,
        notifyDay.day,
        9,
      );
      return !notify.isAfter(n) && today.difference(due).inDays <= 2;
    }

    final thisDue = monthDay(today.year, today.month, dueDate.day);
    final notifyDay = thisDue.subtract(Duration(days: remindDaysBefore));
    final notify = DateTime(notifyDay.year, notifyDay.month, notifyDay.day, 9);
    return !notify.isAfter(n) && today.difference(thisDue).inDays <= 2;
  }

  String dueLabel([DateTime? now]) {
    final days = daysUntilDue(now);
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days > 1) return 'Due in $days days';
    if (days == -1) return 'Was due yesterday';
    return 'Was due ${-days} days ago';
  }

  String remindLabel() {
    switch (remindDaysBefore) {
      case 0:
        return 'On due date';
      case 1:
        return '1 day before';
      case 7:
        return '1 week before';
      default:
        return '$remindDaysBefore days before';
    }
  }

  PaymentReminder copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    int? remindDaysBefore,
    bool? monthly,
    String? note,
    String? lastPaidOccurrence,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      monthly: monthly ?? this.monthly,
      note: clearNote ? null : (note ?? this.note),
      lastPaidOccurrence: lastPaidOccurrence ?? this.lastPaidOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    'remindDaysBefore': remindDaysBefore,
    'monthly': monthly,
    'note': note,
    'lastPaidOccurrence': lastPaidOccurrence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PaymentReminder.fromJson(Map<String, dynamic> json) {
    return PaymentReminder(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      remindDaysBefore: (json['remindDaysBefore'] as num?)?.toInt() ?? 1,
      monthly: json['monthly'] != false,
      note: json['note'] as String?,
      lastPaidOccurrence: json['lastPaidOccurrence'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime monthDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, last));
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    dueDate,
    remindDaysBefore,
    monthly,
    note,
    lastPaidOccurrence,
    createdAt,
    updatedAt,
  ];
}

String newPaymentReminderId() =>
    'payrem_${DateTime.now().microsecondsSinceEpoch}';
