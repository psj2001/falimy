import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/onboarding_scaffold.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/home/domain/unexpected_expense_category.dart';
import 'package:falimy/features/home/presentation/screens/choose_cash_book_screen.dart';

class AddUnexpectedExpenseScreen extends ConsumerStatefulWidget {
  const AddUnexpectedExpenseScreen({
    super.key,
    required this.category,
  });

  final UnexpectedExpenseCategory category;

  @override
  ConsumerState<AddUnexpectedExpenseScreen> createState() =>
      _AddUnexpectedExpenseScreenState();
}

class _AddUnexpectedExpenseScreenState
    extends ConsumerState<AddUnexpectedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<CashBook?> _resolveBook() async {
    final notifier = ref.read(financialNotifierProvider.notifier);
    final books = ref.read(financialNotifierProvider).books;

    if (books.isEmpty) {
      return notifier.createBook(
        name: '${DateFormat.MMMM().format(DateTime.now())} Expenses',
        access: BookAccess.justMe,
      );
    }
    if (books.length == 1) return books.first;

    return Navigator.of(context).push<CashBook>(
      MaterialPageRoute(builder: (_) => const ChooseCashBookScreen()),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final book = await _resolveBook();
    if (!mounted) return;
    if (book == null) {
      setState(() => _saving = false);
      return;
    }

    final saved = await ref
        .read(financialNotifierProvider.notifier)
        .addUnexpectedExpense(
          bookId: book.id,
          categoryName: widget.category.title,
          amount: amount,
          note: _noteController.text,
        );

    if (!mounted) return;
    if (saved == null) {
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
      message: 'You have added this expense to ${book.name}.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return OnboardingScaffold(
      title: category.title,
      subtitle:
          'Enter the amount and a note. It will be added as an expense in your cash book.',
      bottom: PrimaryButton(
        label: 'Add to cash book',
        isLoading: _saving,
        onPressed: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (category.assetPath != null || category.fallbackIcon != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FalimyTheme.seed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: category.assetPath != null
                      ? Image.asset(category.assetPath!, fit: BoxFit.contain)
                      : Icon(
                          category.fallbackIcon,
                          color: FalimyTheme.seed,
                          size: 28,
                        ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Common costs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: FalimyTheme.ink,
                  ),
            ),
            const SizedBox(height: 8),
            for (final example in category.examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: FalimyTheme.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(
                          color: FalimyTheme.muted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'AED  ',
              ),
              validator: (value) {
                final parsed = num.tryParse(
                  (value ?? '').trim().replaceAll(',', ''),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Enter the expense amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Note',
              controller: _noteController,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
