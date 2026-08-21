import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/onboarding_scaffold.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class SalaryCashBookPromptScreen extends ConsumerStatefulWidget {
  const SalaryCashBookPromptScreen({
    super.key,
    required this.salary,
  });

  final double salary;

  @override
  ConsumerState<SalaryCashBookPromptScreen> createState() =>
      _SalaryCashBookPromptScreenState();
}

class _SalaryCashBookPromptScreenState
    extends ConsumerState<SalaryCashBookPromptScreen> {
  bool _saving = false;

  Future<bool> _saveSalary() async {
    try {
      await ref.read(onboardingNotifierProvider.notifier).setSalary(widget.salary);
      return true;
    } catch (e) {
      if (!mounted) return false;
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message: 'Could not save salary.',
      );
      return false;
    }
  }

  Future<void> _onYes() async {
    if (_saving) return;
    setState(() => _saving = true);

    final saved = await _saveSalary();
    if (!saved || !mounted) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    final book = await ref
        .read(financialNotifierProvider.notifier)
        .addSalaryAsMonthlyIncome(widget.salary);

    if (!mounted) return;
    if (book == null) {
      setState(() => _saving = false);
      final error = ref.read(financialNotifierProvider).error;
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message: error ?? 'Something went wrong.',
      );
      return;
    }

    await showResultDialog(
      context,
      kind: ResultDialogKind.success,
      message: 'Your salary was added as income in ${book.name}.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _onNo() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await _saveSalary();
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = BudgetFormat.money(widget.salary);

    return OnboardingScaffold(
      title: 'Add salary to cash book?',
      subtitle:
          'Do you want to add your salary ($amount) as your monthly income in cash book?',
      child: Column(
        children: [
          const Spacer(),
          FilledButton(
            onPressed: _saving ? null : _onYes,
            style: FilledButton.styleFrom(
              backgroundColor: FalimyTheme.seed,
              minimumSize: const Size.fromHeight(64),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Yes'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _saving ? null : _onNo,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('No'),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
