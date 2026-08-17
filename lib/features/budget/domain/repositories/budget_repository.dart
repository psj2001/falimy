import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';

abstract class BudgetRepository {
  Future<MonthlyBudget> load(String month);

  Future<MonthlyBudget> save(MonthlyBudget budget);

  Future<List<String>> listMonths();
}
