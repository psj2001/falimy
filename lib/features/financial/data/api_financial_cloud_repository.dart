import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/domain/entities/payment_mode.dart';

/// Cloud sync for cash books (server-backed). Local data stays on device.
class ApiFinancialCloudRepository {
  ApiFinancialCloudRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<void> upsertBook({
    required CashBook book,
    required List<CashEntry> entries,
    required List<EntryCategory> categories,
    required List<PaymentMode> paymentModes,
  }) async {
    await _api.putJson('/api/financial/books/${book.id}', {
      'book': book.toCloudJson(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'paymentModes': paymentModes.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> removeBook(String bookId) async {
    await _api.delete('/api/financial/books/$bookId');
  }

  Future<Set<String>> listCloudBookIds() async {
    final json = await _api.getJson('/api/financial/books');
    final books = json['books'];
    if (books is! List) return {};
    return books
        .whereType<Map>()
        .map((e) => (e['id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<List<CloudBookPackage>> fetchSnapshot() async {
    final json = await _api.getJson('/api/financial/snapshot');
    final raw = json['books'];
    if (raw is! List) return const [];

    final packages = <CloudBookPackage>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final bookRaw = map['book'];
      if (bookRaw is! Map) continue;
      final book = CashBook.fromJson(
        Map<String, dynamic>.from(bookRaw),
      ).copyWith(syncedToCloud: true);
      packages.add(
        CloudBookPackage(
          book: book,
          entries: _decodeList(map['entries'], CashEntry.fromJson),
          categories: _decodeList(map['categories'], EntryCategory.fromJson),
          paymentModes: _decodeList(map['paymentModes'], PaymentMode.fromJson),
        ),
      );
    }
    return packages;
  }

  List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class CloudBookPackage {
  const CloudBookPackage({
    required this.book,
    required this.entries,
    required this.categories,
    required this.paymentModes,
  });

  final CashBook book;
  final List<CashEntry> entries;
  final List<EntryCategory> categories;
  final List<PaymentMode> paymentModes;
}
