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
}
