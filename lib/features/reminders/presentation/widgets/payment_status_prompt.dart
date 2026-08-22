import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/home/presentation/screens/choose_cash_book_screen.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';

/// Returns true if the user said they paid, false if not paid, null if dismissed.
Future<bool?> showPaidOrNotPaidDialog(
  BuildContext context,
  PaymentReminder reminder,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _PaidOrNotPaidDialog(reminder: reminder),
  );
}

Future<void> promptPaymentReminderStatus(
  BuildContext context,
  WidgetRef ref,
  PaymentReminder reminder,
) async {
  if (!reminder.needsPaymentPrompt) return;
  final paid = await showPaidOrNotPaidDialog(context, reminder);
  if (!context.mounted || paid == null) return;
  if (paid) {
    await recordReminderAsPaid(context, ref, reminder);
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('We’ll keep this reminder until you pay.')),
  );
}

Future<bool> recordReminderAsPaid(
  BuildContext context,
  WidgetRef ref,
  PaymentReminder reminder,
) async {
  final book = await _resolveCashBook(context, ref);
  if (!context.mounted) return false;
  if (book == null) return false;

  final saved = await ref
      .read(financialNotifierProvider.notifier)
      .addUnexpectedExpense(
        bookId: book.id,
        categoryName: reminder.title,
        amount: reminder.amount,
        note: reminder.note,
      );
  if (!context.mounted) return false;
  if (saved == null) {
    await showResultDialog(
      context,
      kind: ResultDialogKind.failure,
      message:
          ref.read(financialNotifierProvider).error ??
          'Could not add this expense.',
    );
    return false;
  }

  final marked = await ref
      .read(paymentReminderNotifierProvider.notifier)
      .markPaid(reminder);
  if (!context.mounted) return marked;
  if (!marked) {
    await showResultDialog(
      context,
      kind: ResultDialogKind.failure,
      message:
          ref.read(paymentReminderNotifierProvider).error ??
          'Expense was added, but the reminder could not be updated.',
    );
    return false;
  }

  await showResultDialog(
    context,
    kind: ResultDialogKind.success,
    message:
        '${reminder.title} (${reminder.amountLabel(ref.read(preferredCurrencyProvider))}) was added to ${book.name}.',
  );
  return true;
}

Future<CashBook?> _resolveCashBook(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(financialNotifierProvider.notifier);
  var books = ref.read(financialNotifierProvider).books;
  if (books.isEmpty && ref.read(financialNotifierProvider).isLoading) {
    await notifier.load();
    if (!context.mounted) return null;
    books = ref.read(financialNotifierProvider).books;
  }

  if (books.isEmpty) {
    return notifier.createBook(
      name: '${DateFormat.MMMM().format(DateTime.now())} Expenses',
      access: BookAccess.justMe,
    );
  }
  if (books.length == 1) return books.first;

  return Navigator.of(context).push<CashBook>(
    MaterialPageRoute(
      builder: (_) => const ChooseCashBookScreen(
        subtitle: 'Choose which cash book to add this payment to',
      ),
    ),
  );
}

class _PaidOrNotPaidDialog extends ConsumerWidget {
  const _PaidOrNotPaidDialog({required this.reminder});

  final PaymentReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(preferredCurrencyProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: FalimyTheme.seed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: FalimyTheme.seed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Did you pay ${reminder.title}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: FalimyTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${reminder.amountLabel(currency)} · ${reminder.dueLabel()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: FalimyTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: FalimyTheme.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Paid'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FalimyTheme.ink,
                    side: BorderSide(
                      color: FalimyTheme.muted.withValues(alpha: 0.35),
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Not paid'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
