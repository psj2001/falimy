import '../entities/cash_book.dart';
import '../entities/cash_entry.dart';
import '../entities/entry_category.dart';
import '../entities/payment_mode.dart';

abstract class FinancialRepository {
  Future<FinancialSnapshot> load();

  Future<CashBook> createBook({
    required String name,
    required BookAccess access,
  });

  Future<CashBook> renameBook({
    required String bookId,
    required String name,
  });

  Future<CashBook> duplicateBook(String bookId);

  Future<void> deleteBook(String bookId);

  Future<CashEntry> addEntry(CashEntry entry);

  Future<void> deleteEntry(String entryId);

  Future<EntryCategory> addCategory({
    required String bookId,
    required String name,
  });

  Future<PaymentMode> addPaymentMode({
    required String bookId,
    required String name,
  });
}

class FinancialSnapshot {
  const FinancialSnapshot({
    required this.books,
    required this.entries,
    required this.categories,
    required this.paymentModes,
  });

  final List<CashBook> books;
  final List<CashEntry> entries;
  final List<EntryCategory> categories;
  final List<PaymentMode> paymentModes;
}
