import 'package:equatable/equatable.dart';

import 'package:falimy/features/budget/domain/entities/budget_category.dart';
import 'package:falimy/features/budget/domain/entities/budget_item.dart';
import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/core/currency/app_currency.dart';

enum BudgetStatus { withinLimit, nearLimit, overLimit, belowTarget }

enum InsightSeverity { critical, warning, good }

class BudgetInsight extends Equatable {
  const BudgetInsight({
    required this.severity,
    required this.title,
    required this.detail,
    this.categoryId,
    this.impact = 0,
  });

  final InsightSeverity severity;
  final String title;
  final String detail;
  final String? categoryId;
  final double impact;

  @override
  List<Object?> get props => [severity, title, detail, categoryId, impact];
}

class ItemActual extends Equatable {
  const ItemActual({
    required this.item,
    required this.actual,
  });

  final BudgetItem item;
  final double actual;

  @override
  List<Object?> get props => [item, actual];
}

class CategoryBreakdown extends Equatable {
  const CategoryBreakdown({
    required this.category,
    required this.planned,
    required this.actual,
    required this.percentOfIncome,
    required this.percentOfExpenses,
    required this.status,
    required this.items,
  });

  final BudgetCategory category;
  final double planned;
  final double actual;
  final double percentOfIncome;
  final double percentOfExpenses;
  final BudgetStatus status;
  final List<ItemActual> items;

  /// Share of income used for status vs the thumb-rule target.
  double get comparisonPercent => percentOfIncome;

  @override
  List<Object?> get props => [
        category,
        planned,
        actual,
        percentOfIncome,
        percentOfExpenses,
        status,
        items,
      ];
}

class BudgetAnalysis extends Equatable {
  const BudgetAnalysis({
    required this.budget,
    required this.totalIncome,
    required this.actualIncome,
    required this.totalPlannedExpense,
    required this.totalActualExpense,
    required this.unbudgetedActual,
    required this.netSavings,
    required this.savingsRate,
    required this.monthElapsedPercent,
    required this.perCategory,
    required this.insights,
  });

  final MonthlyBudget budget;
  final double totalIncome;
  final double actualIncome;
  final double totalPlannedExpense;
  final double totalActualExpense;
  final double unbudgetedActual;
  final double netSavings;
  final double savingsRate;
  final double monthElapsedPercent;
  final List<CategoryBreakdown> perCategory;
  final List<BudgetInsight> insights;

  bool get hasPlan => totalIncome > 0 || totalPlannedExpense > 0;

  @override
  List<Object?> get props => [
        budget,
        totalIncome,
        actualIncome,
        totalPlannedExpense,
        totalActualExpense,
        unbudgetedActual,
        netSavings,
        savingsRate,
        monthElapsedPercent,
        perCategory,
        insights,
      ];

  static BudgetAnalysis compute({
    required MonthlyBudget budget,
    required List<CashEntry> entries,
    required List<EntryCategory> categories,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final monthParts = budget.month.split('-');
    final year = int.tryParse(monthParts.isNotEmpty ? monthParts[0] : '') ??
        clock.year;
    final month = int.tryParse(monthParts.length > 1 ? monthParts[1] : '') ??
        clock.month;
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final inMonth = entries.where((entry) {
      return !entry.dateTime.isBefore(monthStart) &&
          entry.dateTime.isBefore(monthEnd);
    }).toList();

    final categoryNames = <String, String>{};
    for (final category in categories) {
      categoryNames[category.id] = category.name;
    }

    var actualIncome = 0.0;
    final unmatched = <CashEntry>[];
    final itemActuals = <String, double>{};

    for (final entry in inMonth) {
      if (entry.isCashIn) {
        actualIncome += entry.amount;
        continue;
      }
      final categoryName = entry.categoryId == null
          ? null
          : categoryNames[entry.categoryId];
      final itemId = _matchItem(
        budget.categories,
        categoryName: categoryName,
        remark: entry.remark,
      );
      if (itemId == null) {
        unmatched.add(entry);
      } else {
        itemActuals[itemId] = (itemActuals[itemId] ?? 0) + entry.amount;
      }
    }

    final unbudgetedActual =
        unmatched.fold<double>(0, (sum, entry) => sum + entry.amount);

    final totalIncome = budget.totalIncome;
    final incomeBase = totalIncome > 0 ? totalIncome : actualIncome;

    final perCategory = <CategoryBreakdown>[];
    var totalPlannedExpense = 0.0;
    var totalActualExpense = unbudgetedActual;

    for (final category in budget.categories) {
      final items = category.items
          .map(
            (item) => ItemActual(
              item: item,
              actual: itemActuals[item.id] ?? 0,
            ),
          )
          .toList();
      final planned = category.plannedTotal;
      final actual = items.fold<double>(0, (sum, item) => sum + item.actual);
      totalPlannedExpense += planned;
      totalActualExpense += actual;
      perCategory.add(
        CategoryBreakdown(
          category: category,
          planned: planned,
          actual: actual,
          percentOfIncome: 0,
          percentOfExpenses: 0,
          status: BudgetStatus.withinLimit,
          items: items,
        ),
      );
    }

    final resolved = perCategory.map((row) {
      final shareOfIncome =
          incomeBase > 0 ? row.planned / incomeBase * 100 : 0.0;
      final shareOfExpenses = totalPlannedExpense > 0
          ? row.planned / totalPlannedExpense * 100
          : 0.0;
      return CategoryBreakdown(
        category: row.category,
        planned: row.planned,
        actual: row.actual,
        percentOfIncome: shareOfIncome,
        percentOfExpenses: shareOfExpenses,
        status: _status(
          shareOfIncome,
          row.category.targetPercent,
          row.category.isMinLimit,
        ),
        items: row.items,
      );
    }).toList();

    final netSavings = incomeBase - totalPlannedExpense;
    final savingsRate = incomeBase > 0 ? (netSavings / incomeBase) * 100 : 0.0;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final elapsedDay = clock.isBefore(monthStart)
        ? 0
        : clock.isAfter(monthEnd.subtract(const Duration(seconds: 1)))
            ? daysInMonth
            : clock.day;
    final monthElapsedPercent =
        daysInMonth > 0 ? (elapsedDay / daysInMonth) * 100 : 0.0;

    final insights = _insights(
      budget: budget,
      incomeBase: incomeBase,
      totalPlannedExpense: totalPlannedExpense,
      totalActualExpense: totalActualExpense,
      unbudgetedActual: unbudgetedActual,
      unmatched: unmatched,
      netSavings: netSavings,
      savingsRate: savingsRate,
      perCategory: resolved,
      now: clock,
      budgetYear: year,
      budgetMonth: month,
    );

    return BudgetAnalysis(
      budget: budget,
      totalIncome: totalIncome,
      actualIncome: actualIncome,
      totalPlannedExpense: totalPlannedExpense,
      totalActualExpense: totalActualExpense,
      unbudgetedActual: unbudgetedActual,
      netSavings: netSavings,
      savingsRate: savingsRate,
      monthElapsedPercent: monthElapsedPercent,
      perCategory: resolved,
      insights: insights,
    );
  }
}

BudgetStatus _status(double actualPct, double target, bool higherIsBetter) {
  final diff = higherIsBetter ? actualPct - target : target - actualPct;
  if (diff >= 1) return BudgetStatus.withinLimit;
  if (diff >= -1) return BudgetStatus.nearLimit;
  return higherIsBetter ? BudgetStatus.belowTarget : BudgetStatus.overLimit;
}

String? _matchItem(
  List<BudgetCategory> categories, {
  String? categoryName,
  String? remark,
}) {
  final needles = <String>[
    if (categoryName != null) _normalize(categoryName),
    if (remark != null) _normalize(remark),
  ].where((value) => value.isNotEmpty).toList();
  if (needles.isEmpty) return null;

  String? bestId;
  var bestScore = 0;
  for (final category in categories) {
    for (final item in category.items) {
      final keys = item.matchKeys.isEmpty
          ? [_normalize(item.name)]
          : item.matchKeys.map(_normalize);
      for (final key in keys) {
        if (key.isEmpty) continue;
        for (final needle in needles) {
          final score = _matchScore(needle, key);
          if (score > bestScore) {
            bestScore = score;
            bestId = item.id;
          }
        }
      }
    }
  }
  return bestScore > 0 ? bestId : null;
}

int _matchScore(String needle, String key) {
  if (needle == key) return 100;
  if (needle.contains(key) || key.contains(needle)) {
    return 40 + (key.length < needle.length ? key.length : needle.length);
  }
  final needleParts = needle.split(' ').where((p) => p.length > 2);
  for (final part in needleParts) {
    if (key.contains(part)) return 20 + part.length;
  }
  return 0;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

String _formatMoney(double amount, {required String currency}) {
  return AppCurrency.format(amount.round(), currency: currency);
}

List<BudgetInsight> _insights({
  required MonthlyBudget budget,
  required double incomeBase,
  required double totalPlannedExpense,
  required double totalActualExpense,
  required double unbudgetedActual,
  required List<CashEntry> unmatched,
  required double netSavings,
  required double savingsRate,
  required List<CategoryBreakdown> perCategory,
  required DateTime now,
  required int budgetYear,
  required int budgetMonth,
}) {
  final insights = <BudgetInsight>[];
  String money(double amount) =>
      _formatMoney(amount, currency: budget.currency);

  if (incomeBase <= 0 && totalPlannedExpense <= 0) {
    return const [
      BudgetInsight(
        severity: InsightSeverity.good,
        title: 'Set this month’s budget',
        detail:
            'Add your income and planned amounts to see where to improve.',
      ),
    ];
  }

  if (totalPlannedExpense > incomeBase && incomeBase > 0) {
    insights.add(
      BudgetInsight(
        severity: InsightSeverity.critical,
        title: 'Spending more than you earn',
        detail:
            'Planned expenses are ${money(totalPlannedExpense - incomeBase)} over income. Cut costs or raise income before the month runs out.',
        impact: totalPlannedExpense - incomeBase,
      ),
    );
  }

  final savingsTarget = budget.savingsTargetPercent;
  if (incomeBase > 0 && savingsRate + 0.5 < savingsTarget) {
    final gap = (savingsTarget / 100) * incomeBase - netSavings;
    final overLimit = perCategory
        .where((row) =>
            !row.category.isMinLimit && row.status == BudgetStatus.overLimit)
        .toList()
      ..sort((a, b) => b.percentOfIncome.compareTo(a.percentOfIncome));
    final cutHint = overLimit.isEmpty
        ? 'Trim the biggest discretionary categories first.'
        : 'Start with ${overLimit.first.category.name}.';
    insights.add(
      BudgetInsight(
        severity: gap >= incomeBase * 0.1
            ? InsightSeverity.critical
            : InsightSeverity.warning,
        title: 'Save ${money(gap)} more to hit ${savingsTarget.round()}%',
        detail:
            'You’re at ${savingsRate.toStringAsFixed(1)}% vs a ${savingsTarget.round()}% target. $cutHint',
        impact: gap,
      ),
    );
  }

  for (final row in perCategory) {
    if (incomeBase <= 0) continue;
    final targetShare = (row.category.targetPercent / 100) * incomeBase;
    if (row.category.isMinLimit && row.status == BudgetStatus.belowTarget) {
      final gap = targetShare - (row.actual > 0 ? row.actual : row.planned);
      insights.add(
        BudgetInsight(
          severity: InsightSeverity.warning,
          title: '${row.category.name} is below target',
          detail:
              'Aim for ${row.category.targetPercent.round()}% of income. You’re short by ${money(gap < 0 ? 0 : gap)}.',
          categoryId: row.category.id,
          impact: gap,
        ),
      );
    } else if (!row.category.isMinLimit &&
        (row.status == BudgetStatus.overLimit ||
            row.status == BudgetStatus.nearLimit)) {
      final used = row.actual > 0 ? row.actual : row.planned;
      final trim = used - targetShare;
      if (trim <= 0) continue;
      final isDebt = row.category.id == 'financial';
      final isCritical =
          isDebt || row.status == BudgetStatus.overLimit && trim > incomeBase * 0.03;
      insights.add(
        BudgetInsight(
          severity: isCritical
              ? InsightSeverity.critical
              : InsightSeverity.warning,
          title:
              '${row.category.name} is ${row.percentOfIncome.round()}% of income vs ${row.category.targetPercent.round()}% recommended',
          detail: isDebt
              ? 'Debt payments compound. Trim ${money(trim)} to get back within the ${row.category.targetPercent.round()}% cap.'
              : 'Trim ${money(trim)} this month to get back within the recommended share.',
          categoryId: row.category.id,
          impact: trim,
        ),
      );
    }

    if (row.actual > row.planned && row.planned > 0) {
      final over = row.actual - row.planned;
      insights.add(
        BudgetInsight(
          severity: over > row.planned * 0.25
              ? InsightSeverity.critical
              : InsightSeverity.warning,
          title: 'You have spent ${money(over)} over your ${row.category.name} plan',
          detail:
              'Actual ${money(row.actual)} vs planned ${money(row.planned)}.',
          categoryId: row.category.id,
          impact: over,
        ),
      );
    } else if (row.actual > 0 && row.planned <= 0) {
      insights.add(
        BudgetInsight(
          severity: InsightSeverity.warning,
          title:
              '${money(row.actual)} spent on ${row.category.name} with no plan',
          detail: 'Add a planned amount so this spend stays in the budget.',
          categoryId: row.category.id,
          impact: row.actual,
        ),
      );
    }
  }

  if (unbudgetedActual >= 50) {
    insights.add(
      BudgetInsight(
        severity: unbudgetedActual > incomeBase * 0.05 && incomeBase > 0
            ? InsightSeverity.critical
            : InsightSeverity.warning,
        title: '${money(unbudgetedActual)} spent outside your budget',
        detail:
            'Cashbook entries didn’t match a budget item. Add these categories or rename them so they count.',
        impact: unbudgetedActual,
      ),
    );
  }

  final isCurrentMonth =
      now.year == budgetYear && now.month == budgetMonth;
  if (isCurrentMonth) {
    for (final category in budget.categories) {
      for (final item in category.items) {
        if (!item.reminderEnabled || item.reminderDay == null) continue;
        final day = item.reminderDay!;
        final daysUntil = day - now.day;
        if (daysUntil < -1 || daysUntil > 5) continue;
        final when = daysUntil < 0
            ? 'was due on day $day'
            : daysUntil == 0
                ? 'is due today'
                : 'is due in $daysUntil day${daysUntil == 1 ? '' : 's'}';
        final note = item.reminderNote?.trim();
        insights.add(
          BudgetInsight(
            severity: daysUntil <= 0
                ? InsightSeverity.critical
                : InsightSeverity.warning,
            title: '${item.name} $when',
            detail: note != null && note.isNotEmpty
                ? note
                : (item.planned > 0
                    ? 'Planned ${money(item.planned)}. Log it to a cash book when paid.'
                    : 'Set a planned amount or log it to a cash book when paid.'),
            categoryId: category.id,
            impact: item.planned > 0 ? item.planned : 1,
          ),
        );
      }
    }
  }

  insights.sort((a, b) {
    final severity = a.severity.index.compareTo(b.severity.index);
    if (severity != 0) return severity;
    return b.impact.compareTo(a.impact);
  });

  if (insights.isEmpty) {
    return [
      BudgetInsight(
        severity: InsightSeverity.good,
        title: 'On track this month',
        detail:
            'Spending is within recommended shares and you’re meeting the ${budget.savingsTargetPercent.round()}% savings target.',
      ),
    ];
  }

  if (insights.every((item) => item.severity == InsightSeverity.good)) {
    return insights;
  }

  return insights;
}
