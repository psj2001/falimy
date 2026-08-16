import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/domain/entities/payment_mode.dart';
import 'package:falimy/features/financial/presentation/providers/financial_repository_provider.dart';

class BookBalance {
  const BookBalance({
    required this.totalIn,
    required this.totalOut,
  });

  final double totalIn;
  final double totalOut;

  double get net => totalIn - totalOut;
}

class FinancialState extends Equatable {
  const FinancialState({
    this.books = const [],
    this.entries = const [],
    this.categories = const [],
    this.paymentModes = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  final List<CashBook> books;
  final List<CashEntry> entries;
  final List<EntryCategory> categories;
  final List<PaymentMode> paymentModes;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  BookBalance balanceFor(String bookId) {
    var totalIn = 0.0;
    var totalOut = 0.0;
    for (final entry in entries.where((e) => e.bookId == bookId)) {
      if (entry.isCashIn) {
        totalIn += entry.amount;
      } else {
        totalOut += entry.amount;
      }
    }
    return BookBalance(totalIn: totalIn, totalOut: totalOut);
  }

  List<CashEntry> entriesFor(String bookId) {
    final list = entries.where((e) => e.bookId == bookId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  List<EntryCategory> categoriesFor(String bookId) {
    return categories.where((c) => c.bookId == bookId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<PaymentMode> paymentModesFor(String bookId) {
    return paymentModes.where((p) => p.bookId == bookId).toList();
  }

  CashBook? bookById(String bookId) {
    for (final book in books) {
      if (book.id == bookId) return book;
    }
    return null;
  }

  FinancialState copyWith({
    List<CashBook>? books,
    List<CashEntry>? entries,
    List<EntryCategory>? categories,
    List<PaymentMode>? paymentModes,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return FinancialState(
      books: books ?? this.books,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      paymentModes: paymentModes ?? this.paymentModes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [books, entries, categories, paymentModes, isLoading, isSaving, error];
}

class FinancialNotifier extends Notifier<FinancialState> {
  @override
  FinancialState build() {
    Future.microtask(load);
    return const FinancialState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await ref.read(financialRepositoryProvider).load();
      state = state.copyWith(
        books: snapshot.books,
        entries: snapshot.entries,
        categories: snapshot.categories,
        paymentModes: snapshot.paymentModes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CashBook?> createBook({
    required String name,
    required BookAccess access,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Book name is required');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final book = await ref.read(financialRepositoryProvider).createBook(
            name: name,
            access: access,
          );
      await load();
      state = state.copyWith(isSaving: false);
      return book;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> renameBook({
    required String bookId,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Book name is required');
      return false;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(financialRepositoryProvider).renameBook(
            bookId: bookId,
            name: name,
          );
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<CashBook?> duplicateBook(String bookId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final book =
          await ref.read(financialRepositoryProvider).duplicateBook(bookId);
      await load();
      state = state.copyWith(isSaving: false);
      return book;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(financialRepositoryProvider).deleteBook(bookId);
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<CashEntry?> addEntry(CashEntry entry) async {
    if (entry.amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than zero');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await ref.read(financialRepositoryProvider).addEntry(entry);
      await load();
      state = state.copyWith(isSaving: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteEntry(String entryId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(financialRepositoryProvider).deleteEntry(entryId);
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<EntryCategory?> addCategory({
    required String bookId,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Category name is required');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final category = await ref.read(financialRepositoryProvider).addCategory(
            bookId: bookId,
            name: name,
          );
      await load();
      state = state.copyWith(isSaving: false);
      return category;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<PaymentMode?> addPaymentMode({
    required String bookId,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Payment mode name is required');
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final mode = await ref.read(financialRepositoryProvider).addPaymentMode(
            bookId: bookId,
            name: name,
          );
      await load();
      state = state.copyWith(isSaving: false);
      return mode;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }
}

final financialNotifierProvider =
    NotifierProvider<FinancialNotifier, FinancialState>(FinancialNotifier.new);
