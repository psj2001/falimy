import 'package:falimy/features/financial/data/api_financial_cloud_repository.dart';
import 'package:falimy/features/financial/data/local_financial_repository.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/domain/entities/payment_mode.dart';
import 'package:falimy/features/financial/domain/repositories/financial_repository.dart';

class SyncingFinancialRepository implements FinancialRepository {
  SyncingFinancialRepository({
    required LocalFinancialRepository local,
    required ApiFinancialCloudRepository cloud,
  })  : _local = local,
        _cloud = cloud;

  final LocalFinancialRepository _local;
  final ApiFinancialCloudRepository _cloud;

  @override
  Future<FinancialSnapshot> load() async {
    final local = await _local.load();
    try {
      final remote = await _cloud.fetchSnapshot();
      final merged = _merge(local, remote);
      await _local.replaceAll(merged);
      await _uploadMissingOrNewer(local, remote);
      return _local.current;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<CashBook> createBook({
    required String name,
    required BookAccess access,
  }) async {
    final book = await _local.createBook(name: name, access: access);
    await _pushBook(book.id);
    return _local.current.bookById(book.id) ?? book;
  }

  @override
  Future<CashBook> renameBook({
    required String bookId,
    required String name,
  }) async {
    final book = await _local.renameBook(bookId: bookId, name: name);
    await _pushBook(bookId);
    return _local.current.bookById(bookId) ?? book;
  }

  @override
  Future<CashBook> duplicateBook(String bookId) async {
    final book = await _local.duplicateBook(bookId);
    await _pushBook(book.id);
    return _local.current.bookById(book.id) ?? book;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _local.deleteBook(bookId);
    try {
      await _cloud.removeBook(bookId);
    } catch (_) {}
  }

  @override
  Future<CashEntry> addEntry(CashEntry entry) async {
    final saved = await _local.addEntry(entry);
    await _pushBook(saved.bookId);
    return saved;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    String? bookId;
    for (final entry in _local.current.entries) {
      if (entry.id == entryId) {
        bookId = entry.bookId;
        break;
      }
    }
    await _local.deleteEntry(entryId);
    if (bookId != null) await _pushBook(bookId);
  }

  @override
  Future<EntryCategory> addCategory({
    required String bookId,
    required String name,
  }) async {
    final category = await _local.addCategory(bookId: bookId, name: name);
    await _pushBook(bookId);
    return category;
  }

  @override
  Future<PaymentMode> addPaymentMode({
    required String bookId,
    required String name,
  }) async {
    final mode = await _local.addPaymentMode(bookId: bookId, name: name);
    await _pushBook(bookId);
    return mode;
  }

  @override
  Future<CashBook> setBookCloudSynced({
    required String bookId,
    required bool synced,
  }) {
    return _local.setBookCloudSynced(bookId: bookId, synced: synced);
  }

  Future<void> _pushBook(String bookId) async {
    try {
      final snap = _local.current;
      final book = snap.bookById(bookId);
      if (book == null) return;
      await _cloud.upsertBook(
        book: book,
        entries: snap.entries.where((e) => e.bookId == bookId).toList(),
        categories: snap.categories.where((c) => c.bookId == bookId).toList(),
        paymentModes: snap.paymentModes.where((p) => p.bookId == bookId).toList(),
      );
      await _local.setBookCloudSynced(bookId: bookId, synced: true);
    } catch (_) {}
  }

  Future<void> _uploadMissingOrNewer(
    FinancialSnapshot local,
    List<CloudBookPackage> remote,
  ) async {
    final remoteById = {for (final pack in remote) pack.book.id: pack.book};
    for (final book in local.books) {
      final remoteBook = remoteById[book.id];
      if (remoteBook == null || book.updatedAt.isAfter(remoteBook.updatedAt)) {
        await _pushBook(book.id);
      }
    }
  }

  FinancialSnapshot _merge(
    FinancialSnapshot local,
    List<CloudBookPackage> remote,
  ) {
    final localById = {for (final book in local.books) book.id: book};
    final remoteById = {for (final pack in remote) pack.book.id: pack};
    final ids = {...localById.keys, ...remoteById.keys};

    final books = <CashBook>[];
    final entries = <CashEntry>[];
    final categories = <EntryCategory>[];
    final paymentModes = <PaymentMode>[];

    for (final id in ids) {
      final localBook = localById[id];
      final remotePack = remoteById[id];
      final useRemote = localBook == null ||
          (remotePack != null &&
              !remotePack.book.updatedAt.isBefore(localBook.updatedAt));

      if (useRemote && remotePack != null) {
        books.add(remotePack.book.copyWith(syncedToCloud: true));
        entries.addAll(remotePack.entries);
        categories.addAll(remotePack.categories);
        paymentModes.addAll(remotePack.paymentModes);
      } else if (localBook != null) {
        books.add(localBook);
        entries.addAll(local.entries.where((e) => e.bookId == id));
        categories.addAll(local.categories.where((c) => c.bookId == id));
        paymentModes.addAll(local.paymentModes.where((p) => p.bookId == id));
      }
    }

    books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return FinancialSnapshot(
      books: books,
      entries: entries,
      categories: categories,
      paymentModes: paymentModes,
    );
  }
}

extension on FinancialSnapshot {
  CashBook? bookById(String bookId) {
    for (final book in books) {
      if (book.id == bookId) return book;
    }
    return null;
  }
}
