import 'package:equatable/equatable.dart';

import 'package:falimy/features/budget/domain/entities/budget_category.dart';

class IncomeSource extends Equatable {
  const IncomeSource({
    required this.id,
    required this.name,
    this.amount = 0,
  });

  final String id;
  final String name;
  final double amount;

  IncomeSource copyWith({
    String? id,
    String? name,
    double? amount,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
      };

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Income',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, amount];
}

class MonthlyBudget extends Equatable {
  const MonthlyBudget({
    required this.month,
    this.currency = 'AED',
    this.savingsTargetPercent = 20,
    this.incomes = const [],
    this.categories = const [],
    this.isDefault = false,
  });

  final String month;
  final String currency;
  final double savingsTargetPercent;
  final List<IncomeSource> incomes;
  final List<BudgetCategory> categories;
  final bool isDefault;

  double get totalIncome =>
      incomes.fold(0, (sum, source) => sum + source.amount);

  double get totalPlannedExpense =>
      categories.fold(0, (sum, category) => sum + category.plannedTotal);

  MonthlyBudget copyWith({
    String? month,
    String? currency,
    double? savingsTargetPercent,
    List<IncomeSource>? incomes,
    List<BudgetCategory>? categories,
    bool? isDefault,
  }) {
    return MonthlyBudget(
      month: month ?? this.month,
      currency: currency ?? this.currency,
      savingsTargetPercent:
          savingsTargetPercent ?? this.savingsTargetPercent,
      incomes: incomes ?? this.incomes,
      categories: categories ?? this.categories,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'currency': currency,
        'savingsTargetPercent': savingsTargetPercent,
        'incomes': incomes.map((source) => source.toJson()).toList(),
        'categories': categories.map((category) => category.toJson()).toList(),
      };

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    final incomes = <IncomeSource>[];
    final rawIncomes = json['incomes'];
    if (rawIncomes is List) {
      for (final item in rawIncomes) {
        if (item is Map) {
          incomes.add(IncomeSource.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final categories = <BudgetCategory>[];
    final rawCategories = json['categories'];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        if (item is Map) {
          categories.add(
            BudgetCategory.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return MonthlyBudget(
      month: (json['month'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? 'AED',
      savingsTargetPercent:
          (json['savingsTargetPercent'] as num?)?.toDouble() ?? 20,
      incomes: incomes,
      categories: categories,
      isDefault: json['isDefault'] == true,
    );
  }

  @override
  List<Object?> get props => [
        month,
        currency,
        savingsTargetPercent,
        incomes,
        categories,
        isDefault,
      ];
}
