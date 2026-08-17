import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/budget/domain/default_budget.dart';
import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';
import 'package:falimy/features/budget/domain/repositories/budget_repository.dart';

class ApiBudgetRepository implements BudgetRepository {
  ApiBudgetRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<MonthlyBudget> load(String month) async {
    final json = await _api.getJson('/api/budget?month=$month');
    final raw = json['budget'];
    if (raw is Map) {
      return MonthlyBudget.fromJson(Map<String, dynamic>.from(raw));
    }
    return defaultMonthlyBudget(month);
  }

  @override
  Future<MonthlyBudget> save(MonthlyBudget budget) async {
    final json = await _api.putJson(
      '/api/budget/${budget.month}',
      budget.toJson(),
    );
    final raw = json['budget'];
    if (raw is Map) {
      return MonthlyBudget.fromJson(Map<String, dynamic>.from(raw));
    }
    return budget.copyWith(isDefault: false);
  }

  @override
  Future<List<String>> listMonths() async {
    final json = await _api.getJson('/api/budget/months');
    final raw = json['months'];
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }
}
