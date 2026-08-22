import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/budget/data/api_budget_repository.dart';
import 'package:falimy/features/budget/domain/budget_analysis.dart';
import 'package:falimy/features/budget/domain/default_budget.dart';
import 'package:falimy/features/budget/domain/entities/budget_category.dart';
import 'package:falimy/features/budget/domain/entities/budget_item.dart';
import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';
import 'package:falimy/features/budget/domain/repositories/budget_repository.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class BudgetState extends Equatable {
  const BudgetState({
    this.budget,
    this.monthKey = '',
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final MonthlyBudget? budget;
  final String monthKey;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  BudgetState copyWith({
    MonthlyBudget? budget,
    String? monthKey,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool clearBudget = false,
  }) {
    return BudgetState(
      budget: clearBudget ? null : (budget ?? this.budget),
      monthKey: monthKey ?? this.monthKey,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [budget, monthKey, isLoading, isSaving, error];
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return ApiBudgetRepository(apiClient: ref.watch(apiClientProvider));
});

class BudgetNotifier extends Notifier<BudgetState> {
  String? _loadedUserId;
  Timer? _saveTimer;
  bool _saveQueued = false;

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  BudgetState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    ref.listen(onboardingNotifierProvider.select((s) => s.salary), (_, next) {
      _applySalaryIfNeeded(next);
    });
    ref.listen(preferredCurrencyProvider, (_, next) {
      _applyCurrency(next);
    });
    ref.onDispose(() {
      _saveTimer?.cancel();
    });
    if (userId == null) {
      _saveTimer?.cancel();
      _saveQueued = false;
      _loadedUserId = null;
      return const BudgetState();
    }
    final month = currentBudgetMonth();
    if (_loadedUserId != userId) {
      _loadedUserId = userId;
      Future.microtask(() => load(month: month));
    }
    return BudgetState(monthKey: month, isLoading: true);
  }

  Future<void> load({String? month, bool silent = false}) async {
    if (ref.read(authNotifierProvider).user == null) return;
    final monthKey = month ?? state.monthKey;
    if (monthKey.isEmpty) return;
    if (state.isLoading && state.monthKey == monthKey && state.budget != null) {
      return;
    }
    state = state.copyWith(
      monthKey: monthKey,
      isLoading: silent && state.budget != null ? state.isLoading : true,
      clearError: true,
    );
    try {
      var budget = await _repo.load(monthKey);
      final loadedCurrency = budget.currency;
      budget = _prefillSalary(budget);
      budget = _withPreferredCurrency(budget);
      state = state.copyWith(
        budget: budget,
        monthKey: monthKey,
        isLoading: false,
        clearError: true,
      );
      if ((budget.isDefault && budget.totalIncome > 0) ||
          budget.currency != loadedCurrency) {
        _scheduleSave();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
        budget: state.budget ??
            defaultMonthlyBudget(
              monthKey,
              currency: ref.read(preferredCurrencyProvider),
            ),
      );
    }
  }

  MonthlyBudget _prefillSalary(MonthlyBudget budget) {
    final salary = ref.read(onboardingNotifierProvider).salary;
    return _withSalary(budget, salary);
  }

  MonthlyBudget _withPreferredCurrency(MonthlyBudget budget) {
    final currency = ref.read(preferredCurrencyProvider);
    if (budget.currency == currency) return budget;
    return budget.copyWith(currency: currency);
  }

  void _applyCurrency(String currency) {
    final budget = state.budget;
    if (budget == null) return;
    final next = _withPreferredCurrency(budget);
    if (next == budget) return;
    _replace(next);
  }

  void _applySalaryIfNeeded(num? salary) {
    final budget = state.budget;
    if (budget == null) return;
    final next = _withSalary(budget, salary);
    if (next == budget) return;
    _replace(next);
  }

  MonthlyBudget _withSalary(MonthlyBudget budget, num? salary) {
    if (!budget.isDefault) return budget;
    if (salary == null || salary <= 0) return budget;
    if (budget.totalIncome > 0) return budget;
    final incomes = [...budget.incomes];
    if (incomes.isEmpty) {
      incomes.add(
        IncomeSource(
          id: budgetNewId('inc'),
          name: 'Salary',
          amount: salary.toDouble(),
        ),
      );
    } else {
      incomes[0] = incomes[0].copyWith(amount: salary.toDouble());
    }
    return budget.copyWith(incomes: incomes);
  }

  Future<void> changeMonth(String month) async {
    await flushSave();
    await load(month: month);
  }

  void shiftMonth(int delta) {
    final parts = state.monthKey.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '') ??
        DateTime.now().year;
    final month = int.tryParse(parts.length > 1 ? parts[1] : '') ??
        DateTime.now().month;
    final next = DateTime(year, month + delta, 1);
    unawaited(changeMonth(currentBudgetMonth(next)));
  }

  void _replace(MonthlyBudget budget) {
    state = state.copyWith(budget: budget, clearError: true);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveQueued = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () {
      unawaited(_persist());
    });
  }

  Future<void> flushSave() async {
    _saveTimer?.cancel();
    if (_saveQueued) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    _saveQueued = false;
    final budget = state.budget;
    if (budget == null) return;
    state = state.copyWith(isSaving: true);
    try {
      final saved = await _repo.save(budget);
      if (state.monthKey == saved.month) {
        state = state.copyWith(
          budget: saved.copyWith(isDefault: false),
          isSaving: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(isSaving: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setIncomes(List<IncomeSource> incomes) {
    final budget = state.budget;
    if (budget == null) return;
    _replace(budget.copyWith(incomes: incomes, isDefault: false));
  }

  void addIncomeSource({String name = 'Income', double amount = 0}) {
    final budget = state.budget;
    if (budget == null) return;
    _replace(
      budget.copyWith(
        incomes: [
          ...budget.incomes,
          IncomeSource(id: budgetNewId('inc'), name: name, amount: amount),
        ],
        isDefault: false,
      ),
    );
  }

  void updateIncomeSource({
    required String id,
    String? name,
    double? amount,
  }) {
    final budget = state.budget;
    if (budget == null) return;
    _replace(
      budget.copyWith(
        incomes: budget.incomes
            .map(
              (source) => source.id == id
                  ? source.copyWith(name: name, amount: amount)
                  : source,
            )
            .toList(),
        isDefault: false,
      ),
    );
  }

  void removeIncomeSource(String id) {
    final budget = state.budget;
    if (budget == null) return;
    final next = budget.incomes.where((source) => source.id != id).toList();
    _replace(budget.copyWith(incomes: next, isDefault: false));
  }

  void setItemPlanned({
    required String categoryId,
    required String itemId,
    required double amount,
  }) {
    _updateCategory(
      categoryId,
      (category) => category.copyWith(
        items: category.items
            .map(
              (item) =>
                  item.id == itemId ? item.copyWith(planned: amount) : item,
            )
            .toList(),
      ),
    );
  }

  void setItemReminder({
    required String categoryId,
    required String itemId,
    required bool enabled,
    int? day,
    String? note,
  }) {
    _updateCategory(
      categoryId,
      (category) => category.copyWith(
        items: category.items.map((item) {
          if (item.id != itemId) return item;
          if (!enabled) {
            return item.copyWith(
              reminderEnabled: false,
              clearReminderDay: true,
              clearReminderNote: true,
            );
          }
          final nextDay = (day ?? item.reminderDay ?? 1).clamp(1, 28);
          final trimmed = note?.trim();
          return item.copyWith(
            reminderEnabled: true,
            reminderDay: nextDay,
            reminderNote: trimmed == null
                ? item.reminderNote
                : (trimmed.isEmpty ? null : trimmed),
            clearReminderNote: trimmed != null && trimmed.isEmpty,
          );
        }).toList(),
      ),
    );
  }

  void addItem({required String categoryId, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _updateCategory(
      categoryId,
      (category) => category.copyWith(
        items: [
          ...category.items,
          BudgetItem(
            id: budgetNewId('item'),
            name: trimmed,
            matchKeys: matchKeysFor(trimmed),
          ),
        ],
      ),
    );
  }

  void removeItem({required String categoryId, required String itemId}) {
    _updateCategory(
      categoryId,
      (category) => category.copyWith(
        items: category.items.where((item) => item.id != itemId).toList(),
      ),
    );
  }

  void setCategoryTarget({
    required String categoryId,
    required double target,
  }) {
    _updateCategory(
      categoryId,
      (category) => category.copyWith(targetPercent: target),
    );
  }

  void addCategory(String name) {
    final budget = state.budget;
    if (budget == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = budgetNewId('cat');
    _replace(
      budget.copyWith(
        categories: [
          ...budget.categories,
          BudgetCategory(
            id: id,
            name: trimmed,
            iconKey: 'misc',
            targetPercent: 2,
          ),
        ],
        isDefault: false,
      ),
    );
  }

  void removeCategory(String categoryId) {
    final budget = state.budget;
    if (budget == null) return;
    _replace(
      budget.copyWith(
        categories: budget.categories
            .where((category) => category.id != categoryId)
            .toList(),
        isDefault: false,
      ),
    );
  }

  void _updateCategory(
    String categoryId,
    BudgetCategory Function(BudgetCategory) update,
  ) {
    final budget = state.budget;
    if (budget == null) return;
    _replace(
      budget.copyWith(
        categories: budget.categories
            .map(
              (category) =>
                  category.id == categoryId ? update(category) : category,
            )
            .toList(),
        isDefault: false,
      ),
    );
  }
}

final budgetNotifierProvider =
    NotifierProvider<BudgetNotifier, BudgetState>(BudgetNotifier.new);

final budgetAnalysisProvider = Provider<BudgetAnalysis?>((ref) {
  final budgetState = ref.watch(budgetNotifierProvider);
  final financial = ref.watch(financialNotifierProvider);
  final budget = budgetState.budget;
  if (budget == null) return null;
  return BudgetAnalysis.compute(
    budget: budget,
    entries: financial.entries,
    categories: financial.categories,
  );
});
