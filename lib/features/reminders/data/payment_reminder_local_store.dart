import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/reminders/domain/payment_reminder.dart';

class PaymentReminderLocalStore {
  PaymentReminderLocalStore({this.userId});

  static const _legacyKey = 'falimy_pay_reminders_v1';
  static const _legacyReadKey = 'falimy_pay_reminders_read_v1';

  final String? userId;

  String get _key {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return _legacyKey;
    return '${_legacyKey}_$id';
  }

  String get _readKey {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return _legacyReadKey;
    return '${_legacyReadKey}_$id';
  }

  Future<List<PaymentReminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_key);
    if ((raw == null || raw.isEmpty) && _key != _legacyKey) {
      raw = prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        await prefs.setString(_key, raw);
      }
    }
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
    var values = prefs.getStringList(_readKey);
    if ((values == null || values.isEmpty) && _readKey != _legacyReadKey) {
      values = prefs.getStringList(_legacyReadKey);
      if (values != null && values.isNotEmpty) {
        await prefs.setStringList(_readKey, values);
      }
    }
    return values?.toSet() ?? {};
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
