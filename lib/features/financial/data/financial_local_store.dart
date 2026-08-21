import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/domain/entities/payment_mode.dart';
import 'package:falimy/features/financial/domain/repositories/financial_repository.dart';

class FinancialLocalStore {
  FinancialLocalStore({this.userId});

  static const _legacyKey = 'falimy_financial_v1';

  final String? userId;

  String get _key {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return _legacyKey;
    return '${_legacyKey}_$id';
  }

  Future<FinancialSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_key);
    if ((raw == null || raw.isEmpty) && _key != _legacyKey) {
      raw = prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        await prefs.setString(_key, raw);
      }
    }
    if (raw == null || raw.isEmpty) {
      return const FinancialSnapshot(
        books: [],
        entries: [],
        categories: [],
        paymentModes: [],
      );
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FinancialSnapshot(
      books: _decodeList(json['books'], CashBook.fromJson),
      entries: _decodeList(json['entries'], CashEntry.fromJson),
      categories: _decodeList(json['categories'], EntryCategory.fromJson),
      paymentModes: _decodeList(json['paymentModes'], PaymentMode.fromJson),
    );
  }

  Future<void> save(FinancialSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'books': snapshot.books.map((e) => e.toJson()).toList(),
      'entries': snapshot.entries.map((e) => e.toJson()).toList(),
      'categories': snapshot.categories.map((e) => e.toJson()).toList(),
      'paymentModes': snapshot.paymentModes.map((e) => e.toJson()).toList(),
    });
    await prefs.setString(_key, payload);
  }

  List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
