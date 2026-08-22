import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/entities/monthly_budget.dart';
import 'package:falimy/features/budget/presentation/providers/budget_notifier.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

Future<void> showIncomeSourcesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FalimyTheme.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _IncomeSourcesSheet(),
  );
}

class _IncomeSourcesSheet extends ConsumerWidget {
  const _IncomeSourcesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetNotifierProvider).budget;
    final incomes = budget?.incomes ?? const <IncomeSource>[];
    final currency = ref.watch(preferredCurrencyProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FalimyTheme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Income sources',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${BudgetFormat.money(
              incomes.fold<double>(0, (sum, item) => sum + item.amount),
              currency: currency,
            )}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final source in incomes)
                  _IncomeRow(
                    key: ValueKey(source.id),
                    source: source,
                    currency: currency,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(budgetNotifierProvider.notifier).addIncomeSource();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add income source'),
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends ConsumerStatefulWidget {
  const _IncomeRow({
    super.key,
    required this.source,
    required this.currency,
  });

  final IncomeSource source;
  final String currency;

  @override
  ConsumerState<_IncomeRow> createState() => _IncomeRowState();
}

class _IncomeRowState extends ConsumerState<_IncomeRow> {
  late final TextEditingController _name;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.source.name);
    _amount = TextEditingController(
      text: widget.source.amount == 0
          ? ''
          : widget.source.amount.toStringAsFixed(
              widget.source.amount.truncateToDouble() == widget.source.amount
                  ? 0
                  : 2,
            ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _commit() {
    ref.read(budgetNotifierProvider.notifier).updateIncomeSource(
          id: widget.source.id,
          name: _name.text.trim().isEmpty ? widget.source.name : _name.text,
          amount: double.tryParse(_amount.text.replaceAll(',', '')) ?? 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              onChanged: (_) => _commit(),
              decoration: const InputDecoration(
                labelText: 'Source',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _commit(),
              decoration: InputDecoration(
                labelText: widget.currency,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () {
              ref
                  .read(budgetNotifierProvider.notifier)
                  .removeIncomeSource(widget.source.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFA83E2C)),
          ),
        ],
      ),
    );
  }
}
