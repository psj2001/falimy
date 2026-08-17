import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/budget_analysis.dart';

const Color budgetAmber = Color(0xFFB4791F);
const Color budgetRust = Color(0xFFA83E2C);

IconData budgetIconFor(String iconKey) {
  switch (iconKey) {
    case 'housing':
      return Icons.home_rounded;
    case 'utilities':
      return Icons.bolt_rounded;
    case 'family':
      return Icons.school_rounded;
    case 'grocery':
      return Icons.shopping_cart_rounded;
    case 'transport':
      return Icons.directions_car_rounded;
    case 'financial':
      return Icons.credit_card_rounded;
    case 'savings':
      return Icons.savings_rounded;
    case 'lifestyle':
      return Icons.restaurant_rounded;
    case 'personal':
      return Icons.checkroom_rounded;
    case 'social':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.more_horiz_rounded;
  }
}

Color budgetStatusColor(BudgetStatus status) {
  switch (status) {
    case BudgetStatus.withinLimit:
      return FalimyTheme.seed;
    case BudgetStatus.nearLimit:
      return budgetAmber;
    case BudgetStatus.overLimit:
    case BudgetStatus.belowTarget:
      return budgetRust;
  }
}

Color savingsGaugeColor(double savingsPct, double target) {
  final diff = savingsPct - target;
  if (diff >= 1) return FalimyTheme.seed;
  if (diff >= -1) return budgetAmber;
  return budgetRust;
}

Color insightColor(InsightSeverity severity) {
  switch (severity) {
    case InsightSeverity.critical:
      return budgetRust;
    case InsightSeverity.warning:
      return budgetAmber;
    case InsightSeverity.good:
      return FalimyTheme.seed;
  }
}

IconData insightIcon(InsightSeverity severity) {
  switch (severity) {
    case InsightSeverity.critical:
      return Icons.error_rounded;
    case InsightSeverity.warning:
      return Icons.warning_amber_rounded;
    case InsightSeverity.good:
      return Icons.check_circle_rounded;
  }
}
