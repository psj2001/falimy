import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/reminders/domain/payment_reminder.dart';

class PaymentReminderLocalStore {
  static const _key = 'falimy_pay_reminders_v1';
  static const _readKey = 'falimy_pay_reminders_read_v1';

  Future<List<PaymentReminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    final json = jsonDecode(raw);
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => PaymentReminder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> save(List<PaymentReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(reminders.map((e) => e.toJson()).toList()),
    );
  }

  Future<Set<String>> loadReadInboxIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_readKey) ?? const [];
    return values.toSet();
  }

  Future<void> markInboxRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final next = {...?prefs.getStringList(_readKey)?.toSet(), id}.toList();
    await prefs.setStringList(_readKey, next);
  }

  Future<void> markInboxReadAll(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final next = {...?prefs.getStringList(_readKey)?.toSet(), ...ids}.toList();
    await prefs.setStringList(_readKey, next);
  }
}
