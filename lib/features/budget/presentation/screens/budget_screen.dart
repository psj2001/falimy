import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/budget_analysis.dart';
import 'package:falimy/features/budget/domain/entities/budget_category.dart';
import 'package:falimy/features/budget/presentation/providers/budget_notifier.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_style.dart';
import 'package:falimy/features/budget/presentation/widgets/income_sources_sheet.dart';
import 'package:falimy/features/budget/presentation/widgets/item_cashbook_sheet.dart';
import 'package:falimy/features/budget/presentation/widgets/item_reminder_sheet.dart';
import 'package:falimy/features/budget/presentation/widgets/savings_gauge.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _expanded = <String>{'housing'};
  String? _addingSubFor;
  String? _addingCatName;
  final _subDraft = TextEditingController();
  final _catDraft = TextEditingController();

  @override
  void dispose() {
    _subDraft.dispose();
    _catDraft.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetNotifierProvider);
    final analysis = ref.watch(budgetAnalysisProvider);
    final budget = state.budget;
    final currency = ref.watch(preferredCurrencyProvider);

    return Scaffold(
      backgroundColor: FalimyTheme.cream,
      appBar: AppBar(
        title: const Text('Household budget'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          ref.read(budgetNotifierProvider.notifier).flushSave();
        },
        child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: state.isLoading && budget == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: FalimyTheme.seed,
                onRefresh: () =>
                    ref.read(budgetNotifierProvider.notifier).load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    _MonthSwitcher(
                      monthKey: state.monthKey,
                      onPrev: () => ref
                          .read(budgetNotifierProvider.notifier)
                          .shiftMonth(-1),
                      onNext: () => ref
                          .read(budgetNotifierProvider.notifier)
                          .shiftMonth(1),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: const TextStyle(color: budgetRust),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (analysis != null)
                      _SummaryCard(
                        analysis: analysis,
                        onEditIncome: () => showIncomeSourcesSheet(context),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Needs your attention',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What to improve based on your plan and cashbook spend.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (analysis != null)
                      for (final insight in analysis.insights.take(6))
                        _InsightTile(insight: insight),
                    const SizedBox(height: 24),
                    Text(
                      'Expense ratio vs. thumb rule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actual share of income against the commonly practiced benchmark per category.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (analysis != null)
                      for (final row in analysis.perCategory)
                        _RatioBar(row: row),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Categories',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 18),
                          ),
                        ),
                        Text(
                          'tap to edit',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (analysis != null)
                      for (final row in analysis.perCategory)
                        _CategoryCard(
                          row: row,
                          monthElapsedPercent: analysis.monthElapsedPercent,
                          currency: currency,
                          expanded: _expanded.contains(row.category.id),
                          addingSub: _addingSubFor == row.category.id,
                          subDraft: _subDraft,
                          onToggle: () => _toggle(row.category.id),
                          onStartAddSub: () {
                            setState(() {
                              _addingSubFor = row.category.id;
                              _subDraft.clear();
                            });
                          },
                          onCancelAddSub: () {
                            setState(() => _addingSubFor = null);
                          },
                          onConfirmAddSub: () {
                            ref.read(budgetNotifierProvider.notifier).addItem(
                                  categoryId: row.category.id,
                                  name: _subDraft.text,
                                );
                            setState(() => _addingSubFor = null);
                          },
                        ),
                    if (_addingCatName != null)
                      _AddCategoryField(
                        controller: _catDraft,
                        onConfirm: () {
                          ref
                              .read(budgetNotifierProvider.notifier)
                              .addCategory(_catDraft.text);
                          setState(() {
                            _addingCatName = null;
                            _catDraft.clear();
                          });
                        },
                        onCancel: () {
                          setState(() {
                            _addingCatName = null;
                            _catDraft.clear();
                          });
                        },
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _addingCatName = '';
                            _catDraft.clear();
                          });
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add category'),
                      ),
                  ],
                ),
              ),
      ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.monthKey,
    required this.onPrev,
    required this.onNext,
  });

  final String monthKey;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'HOUSEHOLD LEDGER',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      letterSpacing: 1.6,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                BudgetFormat.monthTitle(monthKey),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.analysis,
    required this.onEditIncome,
  });

  final BudgetAnalysis analysis;
  final VoidCallback onEditIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = savingsGaugeColor(
      analysis.savingsRate,
      analysis.budget.savingsTargetPercent,
    );
    final currency = ref.watch(preferredCurrencyProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FalimyTheme.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEditIncome,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTHLY INCOME',
                        style: TextStyle(
                          color: Color(0xFFE8D9B0),
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              BudgetFormat.money(
                                analysis.totalIncome,
                                currency: currency,
                              ),
                              style: const TextStyle(
                                color: Color(0xFFE3ECE1),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFFE8D9B0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SavingsGauge(percent: analysis.savingsRate, color: color),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF33473C), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InkStat(
                  label: 'Expense',
                  value: BudgetFormat.money(
                    analysis.totalPlannedExpense,
                    currency: currency,
                  ),
                ),
              ),
              Expanded(
                child: _InkStat(
                  label: 'Net savings',
                  value: BudgetFormat.money(
                    analysis.netSavings,
                    currency: currency,
                  ),
                  valueColor: analysis.netSavings >= 0
                      ? const Color(0xFFBFE3D0)
                      : const Color(0xFFE3A08F),
                ),
              ),
            ],
          ),
          if (analysis.totalActualExpense > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Cashbook this month: ${BudgetFormat.money(analysis.totalActualExpense, currency: currency)} spent'
              '${analysis.actualIncome > 0 ? ' · ${BudgetFormat.money(analysis.actualIncome, currency: currency)} in' : ''}',
              style: const TextStyle(
                color: Color(0xFFE8D9B0),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Thumb-rule target: save ${analysis.budget.savingsTargetPercent.round()}% of income · you’re at ${analysis.savingsRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFFE8D9B0),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InkStat extends StatelessWidget {
  const _InkStat({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFFE3ECE1),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFE8D9B0),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final BudgetInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = insightColor(insight.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(insightIcon(insight.severity), color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(
                      color: FalimyTheme.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.detail,
                    style: const TextStyle(
                      color: FalimyTheme.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.row});

  final CategoryBreakdown row;

  @override
  Widget build(BuildContext context) {
    final color = budgetStatusColor(row.status);
    final barPct = row.percentOfIncome.clamp(0, 40);
    final tickPct = row.category.targetPercent.clamp(0, 40);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.category.name,
                  style: const TextStyle(
                    color: FalimyTheme.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${row.percentOfIncome.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                ' / ${row.category.targetPercent.round()}%',
                style: const TextStyle(
                  color: FalimyTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: width,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E2D3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: width * (barPct / 40),
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Positioned(
                      left: (width * (tickPct / 40)).clamp(0, width - 2),
                      top: -2,
                      child: Container(
                        width: 2,
                        height: 12,
                        color: FalimyTheme.ink,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.row,
    required this.monthElapsedPercent,
    required this.currency,
    required this.expanded,
    required this.addingSub,
    required this.subDraft,
    required this.onToggle,
    required this.onStartAddSub,
    required this.onCancelAddSub,
    required this.onConfirmAddSub,
  });

  final CategoryBreakdown row;
  final double monthElapsedPercent;
  final String currency;
  final bool expanded;
  final bool addingSub;
  final TextEditingController subDraft;
  final VoidCallback onToggle;
  final VoidCallback onStartAddSub;
  final VoidCallback onCancelAddSub;
  final VoidCallback onConfirmAddSub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = budgetStatusColor(row.status);
    final spentPct =
        row.planned > 0 ? (row.actual / row.planned) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FalimyTheme.seed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        budgetIconFor(row.category.iconKey),
                        color: FalimyTheme.ink,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.category.name,
                            style: const TextStyle(
                              color: FalimyTheme.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${BudgetFormat.money(row.planned, currency: currency)} planned · ${row.category.items.length} items',
                            style: const TextStyle(
                              color: FalimyTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${row.percentOfIncome.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: FalimyTheme.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    _TargetRow(category: row.category),
                    if (row.planned > 0 || row.actual > 0) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: row.planned <= 0
                              ? 0
                              : (row.actual / row.planned).clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFD6E2D3),
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${spentPct.round()}% spent, ${monthElapsedPercent.round()}% of month elapsed · actual ${BudgetFormat.money(row.actual, currency: currency)}',
                          style: const TextStyle(
                            color: FalimyTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    for (final item in row.items)
                      _ItemRow(
                        key: ValueKey(item.item.id),
                        categoryId: row.category.id,
                        item: item,
                        currency: currency,
                      ),
                    if (addingSub)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: subDraft,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Subcategory name',
                                isDense: true,
                              ),
                              onSubmitted: (_) => onConfirmAddSub(),
                            ),
                          ),
                          IconButton(
                            onPressed: onConfirmAddSub,
                            icon: const Icon(
                              Icons.check_rounded,
                              color: FalimyTheme.seed,
                            ),
                          ),
                          IconButton(
                            onPressed: onCancelAddSub,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: budgetRust,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onStartAddSub,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add subcategory'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .removeCategory(row.category.id);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: budgetRust,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: budgetRust),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends ConsumerWidget {
  const _TargetRow({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            'Thumb-rule target (${category.limitType == LimitType.min ? 'min' : 'max'})',
            style: const TextStyle(color: FalimyTheme.muted, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: 48,
            child: _TinyNumberField(
              value: category.targetPercent,
              onChanged: (value) {
                ref.read(budgetNotifierProvider.notifier).setCategoryTarget(
                      categoryId: category.id,
                      target: value,
                    );
              },
            ),
          ),
          const SizedBox(width: 4),
          const Text('%', style: TextStyle(color: FalimyTheme.ink)),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    super.key,
    required this.categoryId,
    required this.item,
    required this.currency,
  });

  final String categoryId;
  final ItemActual item;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderOn =
        item.item.reminderEnabled && item.item.reminderDay != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: const TextStyle(
                    color: FalimyTheme.ink,
                    fontSize: 13,
                  ),
                ),
                if (item.actual > 0)
                  Text(
                    'Actual ${BudgetFormat.money(item.actual, currency: currency)}',
                    style: const TextStyle(
                      color: FalimyTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                if (reminderOn)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 12,
                          color: FalimyTheme.seed,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Day ${item.item.reminderDay}'
                            '${item.item.reminderNote?.trim().isNotEmpty == true ? ' · ${item.item.reminderNote}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FalimyTheme.seed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            currency,
            style: const TextStyle(color: FalimyTheme.muted, fontSize: 12),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: _TinyNumberField(
              value: item.item.planned,
              onChanged: (value) {
                ref.read(budgetNotifierProvider.notifier).setItemPlanned(
                      categoryId: categoryId,
                      itemId: item.item.id,
                      amount: value,
                    );
              },
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Actions',
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: reminderOn ? FalimyTheme.seed : FalimyTheme.muted,
            ),
            onSelected: (value) async {
              if (value == 'delete') {
                ref.read(budgetNotifierProvider.notifier).removeItem(
                      categoryId: categoryId,
                      itemId: item.item.id,
                    );
                return;
              }
              if (value == 'reminder') {
                await showBudgetItemReminderSheet(
                  context: context,
                  categoryId: categoryId,
                  item: item.item,
                );
                return;
              }
              if (value == 'cashbook') {
                await showBudgetItemCashBookSheet(
                  context: context,
                  item: item.item,
                  currency: currency,
                  suggestedAmount:
                      item.item.planned > 0 ? item.item.planned : null,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reminder',
                child: Row(
                  children: [
                    Icon(
                      reminderOn
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: FalimyTheme.ink,
                    ),
                    const SizedBox(width: 10),
                    Text(reminderOn ? 'Edit reminder' : 'Set reminder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cashbook',
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: FalimyTheme.ink,
                    ),
                    SizedBox(width: 10),
                    Text('Add to cash book'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: budgetRust,
                    ),
                    SizedBox(width: 10),
                    Text('Remove', style: TextStyle(color: budgetRust)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyNumberField extends StatefulWidget {
  const _TinyNumberField({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_TinyNumberField> createState() => _TinyNumberFieldState();
}

class _TinyNumberFieldState extends State<_TinyNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        widget.onChanged(double.tryParse(_controller.text.replaceAll(',', '')) ?? 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TinyNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _format(double value) {
    if (value == 0) return '';
    if (value.truncateToDouble() == value) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
        color: FalimyTheme.ink,
        fontSize: 13,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      onChanged: (text) {
        widget.onChanged(double.tryParse(text.replaceAll(',', '')) ?? 0);
      },
    );
  }
}

class _AddCategoryField extends StatelessWidget {
  const _AddCategoryField({
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FalimyTheme.accent),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'New category name',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => onConfirm(),
            ),
          ),
          IconButton(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_rounded, color: FalimyTheme.seed),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, color: budgetRust),
          ),
        ],
      ),
    );
  }
}
