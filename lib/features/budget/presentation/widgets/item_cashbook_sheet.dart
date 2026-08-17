import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/entities/budget_item.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/add_book_screen.dart';

Future<void> showBudgetItemCashBookSheet({
  required BuildContext context,
  required BudgetItem item,
  required String currency,
  double? suggestedAmount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FalimyTheme.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CashBookLogSheet(
      item: item,
      currency: currency,
      suggestedAmount: suggestedAmount ?? item.planned,
    ),
  );
}

class _CashBookLogSheet extends ConsumerStatefulWidget {
  const _CashBookLogSheet({
    required this.item,
    required this.currency,
    required this.suggestedAmount,
  });

  final BudgetItem item;
  final String currency;
  final double suggestedAmount;

  @override
  ConsumerState<_CashBookLogSheet> createState() => _CashBookLogSheetState();
}

class _CashBookLogSheetState extends ConsumerState<_CashBookLogSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _remark;
  String? _bookId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final amount = widget.suggestedAmount;
    _amount = TextEditingController(
      text: amount <= 0
          ? ''
          : amount.truncateToDouble() == amount
              ? amount.toStringAsFixed(0)
              : amount.toStringAsFixed(2),
    );
    _remark = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    _amount.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _ensureBookSelected(List<CashBook> books) async {
    if (_bookId != null) return;
    if (books.isEmpty) return;
    setState(() => _bookId = books.first.id);
  }

  Future<void> _createBook() async {
    final book = await Navigator.of(context).push<CashBook>(
      MaterialPageRoute(builder: (_) => const AddBookScreen()),
    );
    if (book == null || !mounted) return;
    setState(() => _bookId = book.id);
  }

  Future<void> _save() async {
    final books = ref.read(financialNotifierProvider).books;
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a cash book first')),
      );
      return;
    }
    final bookId = _bookId ?? books.first.id;
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(financialNotifierProvider.notifier);
    final categories = ref.read(financialNotifierProvider).categoriesFor(bookId);
    final targetName = widget.item.name.trim().toLowerCase();
    String? categoryId;
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == targetName) {
        categoryId = category.id;
        break;
      }
    }
    if (categoryId == null) {
      final created = await notifier.addCategory(
        bookId: bookId,
        name: widget.item.name.trim(),
      );
      categoryId = created?.id;
    }

    final entry = CashEntry(
      id: '',
      bookId: bookId,
      type: EntryType.cashOut,
      amount: amount,
      dateTime: DateTime.now(),
      remark: _remark.text.trim().isEmpty ? widget.item.name : _remark.text.trim(),
      categoryId: categoryId,
    );
    final saved = await notifier.addEntry(entry);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      final error = ref.read(financialNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not add entry')),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${BudgetFormat.money(amount, currency: widget.currency)} to cash book',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financial = ref.watch(financialNotifierProvider);
    final books = [...financial.books]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (_bookId == null && books.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureBookSelected(books);
      });
    }
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
            'Add to cash book',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Log “${widget.item.name}” as a cash-out entry.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (books.isEmpty)
            OutlinedButton.icon(
              onPressed: _createBook,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a cash book'),
            )
          else ...[
            Text(
              'Cash book',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FalimyTheme.ink,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: books.any((book) => book.id == _bookId)
                  ? _bookId
                  : books.first.id,
              items: [
                for (final book in books)
                  DropdownMenuItem(
                    value: book.id,
                    child: Text(book.name),
                  ),
              ],
              onChanged: (value) => setState(() => _bookId = value),
              decoration: const InputDecoration(isDense: true),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (${widget.currency})',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remark,
            decoration: const InputDecoration(
              labelText: 'Remark',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || books.isEmpty ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add cash-out entry'),
          ),
        ],
      ),
    );
  }
}
