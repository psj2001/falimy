import 'package:falimy/features/financial/data/financial_local_store.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/domain/entities/payment_mode.dart';
import 'package:falimy/features/financial/domain/repositories/financial_repository.dart';

class LocalFinancialRepository implements FinancialRepository {
  LocalFinancialRepository({FinancialLocalStore? store})
      : _store = store ?? FinancialLocalStore();

  final FinancialLocalStore _store;

  FinancialSnapshot _cache = const FinancialSnapshot(
    books: [],
    entries: [],
    categories: [],
    paymentModes: [],
  );

  static const defaultCategoryNames = [
    'Travel',
    'Salary',
    'Food',
    'Bills',
    'Petrol',
    'Sale',
    'Deposit',
    'Grocery',
    'Maintenance',
    'Rent',
    'Transport',
  ];

  static const defaultPaymentModeNames = ['Cash', 'Online'];

  @override
  Future<FinancialSnapshot> load() async {
    _cache = await _store.load();
    return _cache;
  }

  @override
  Future<CashBook> createBook({
    required String name,
    required BookAccess access,
  }) async {
    final now = DateTime.now();
    final book = CashBook(
      id: _newId('book'),
      name: name.trim(),
      access: access,
      createdAt: now,
      updatedAt: now,
    );

    final categories = [
      ..._cache.categories,
      ...defaultCategoryNames.map(
        (n) => EntryCategory(
          id: _newId('cat'),
          bookId: book.id,
          name: n,
        ),
      ),
    ];
    final paymentModes = [
      ..._cache.paymentModes,
      ...defaultPaymentModeNames.map(
        (n) => PaymentMode(
          id: _newId('pm'),
          bookId: book.id,
          name: n,
        ),
      ),
    ];

    _cache = FinancialSnapshot(
      books: [..._cache.books, book],
      entries: _cache.entries,
      categories: categories,
      paymentModes: paymentModes,
    );
    await _store.save(_cache);
    return book;
  }

  @override
  Future<CashBook> renameBook({
    required String bookId,
    required String name,
  }) async {
    final index = _cache.books.indexWhere((b) => b.id == bookId);
    if (index < 0) throw StateError('Book not found');

    final updated = _cache.books[index].copyWith(
      name: name.trim(),
      updatedAt: DateTime.now(),
    );
    final books = [..._cache.books];
    books[index] = updated;
    _cache = FinancialSnapshot(
      books: books,
      entries: _cache.entries,
      categories: _cache.categories,
      paymentModes: _cache.paymentModes,
    );
    await _store.save(_cache);
    return updated;
  }

  @override
  Future<CashBook> duplicateBook(String bookId) async {
    final source = _cache.books.firstWhere((b) => b.id == bookId);
    final now = DateTime.now();
    final copy = CashBook(
      id: _newId('book'),
      name: '${source.name} (copy)',
      access: source.access,
      createdAt: now,
      updatedAt: now,
    );

    final categoryMap = <String, String>{};
    final newCategories = <EntryCategory>[];
    for (final cat in _cache.categories.where((c) => c.bookId == bookId)) {
      final newId = _newId('cat');
      categoryMap[cat.id] = newId;
      newCategories.add(
        EntryCategory(id: newId, bookId: copy.id, name: cat.name),
      );
    }

    final newPaymentModes = _cache.paymentModes
        .where((p) => p.bookId == bookId)
        .map(
          (p) => PaymentMode(
            id: _newId('pm'),
            bookId: copy.id,
            name: p.name,
          ),
        )
        .toList();

    final newEntries = _cache.entries
        .where((e) => e.bookId == bookId)
        .map(
          (e) => e.copyWith(
            id: _newId('entry'),
            bookId: copy.id,
            categoryId: e.categoryId == null
                ? null
                : categoryMap[e.categoryId],
          ),
        )
        .toList();

    _cache = FinancialSnapshot(
      books: [..._cache.books, copy],
      entries: [..._cache.entries, ...newEntries],
      categories: [..._cache.categories, ...newCategories],
      paymentModes: [..._cache.paymentModes, ...newPaymentModes],
    );
    await _store.save(_cache);
    return copy;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _cache = FinancialSnapshot(
      books: _cache.books.where((b) => b.id != bookId).toList(),
      entries: _cache.entries.where((e) => e.bookId != bookId).toList(),
      categories: _cache.categories.where((c) => c.bookId != bookId).toList(),
      paymentModes:
          _cache.paymentModes.where((p) => p.bookId != bookId).toList(),
    );
    await _store.save(_cache);
  }

  @override
  Future<CashEntry> addEntry(CashEntry entry) async {
    final saved = entry.id.isEmpty
        ? entry.copyWith(id: _newId('entry'))
        : entry;

    final bookIndex = _cache.books.indexWhere((b) => b.id == saved.bookId);
    final books = [..._cache.books];
    if (bookIndex >= 0) {
      books[bookIndex] = books[bookIndex].copyWith(updatedAt: DateTime.now());
    }

    _cache = FinancialSnapshot(
      books: books,
      entries: [..._cache.entries, saved],
      categories: _cache.categories,
      paymentModes: _cache.paymentModes,
    );
    await _store.save(_cache);
    return saved;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    _cache = FinancialSnapshot(
      books: _cache.books,
      entries: _cache.entries.where((e) => e.id != entryId).toList(),
      categories: _cache.categories,
      paymentModes: _cache.paymentModes,
    );
    await _store.save(_cache);
  }

  @override
  Future<EntryCategory> addCategory({
    required String bookId,
    required String name,
  }) async {
    final category = EntryCategory(
      id: _newId('cat'),
      bookId: bookId,
      name: name.trim(),
    );
    _cache = FinancialSnapshot(
      books: _cache.books,
      entries: _cache.entries,
      categories: [..._cache.categories, category],
      paymentModes: _cache.paymentModes,
    );
    await _store.save(_cache);
    return category;
  }

  @override
  Future<PaymentMode> addPaymentMode({
    required String bookId,
    required String name,
  }) async {
    final mode = PaymentMode(
      id: _newId('pm'),
      bookId: bookId,
      name: name.trim(),
    );
    _cache = FinancialSnapshot(
      books: _cache.books,
      entries: _cache.entries,
      categories: _cache.categories,
      paymentModes: [..._cache.paymentModes, mode],
    );
    await _store.save(_cache);
    return mode;
  }

  @override
  Future<CashBook> setBookCloudSynced({
    required String bookId,
    required bool synced,
  }) async {
    final index = _cache.books.indexWhere((b) => b.id == bookId);
    if (index < 0) throw StateError('Book not found');

    final updated = _cache.books[index].copyWith(syncedToCloud: synced);
    final books = [..._cache.books];
    books[index] = updated;
    _cache = FinancialSnapshot(
      books: books,
      entries: _cache.entries,
      categories: _cache.categories,
      paymentModes: _cache.paymentModes,
    );
    await _store.save(_cache);
    return updated;
  }

  Future<void> replaceAll(FinancialSnapshot snapshot) async {
    _cache = snapshot;
    await _store.save(_cache);
  }

  FinancialSnapshot get current => _cache;

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
