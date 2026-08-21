import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';
import 'package:falimy/features/reminders/presentation/screens/add_edit_payment_reminder_screen.dart';
import 'package:falimy/features/reminders/presentation/widgets/payment_status_prompt.dart';

class PaymentRemindersScreen extends ConsumerWidget {
  const PaymentRemindersScreen({super.key});

  Future<void> _openAdd(BuildContext context, {PaymentReminder? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditPaymentReminderScreen(existing: existing),
      ),
    );
  }

  Future<void> _openReminder(
    BuildContext context,
    WidgetRef ref,
    PaymentReminder reminder,
  ) async {
    if (reminder.needsPaymentPrompt) {
      await promptPaymentReminderStatus(context, ref, reminder);
      return;
    }
    await _openAdd(context, existing: reminder);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PaymentReminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('${reminder.title} will no longer send a notification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC1121F)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(paymentReminderNotifierProvider.notifier)
        .delete(reminder.id);
    if (!context.mounted) return;
    if (!ok) {
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message:
            ref.read(paymentReminderNotifierProvider).error ??
            'Could not delete.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentReminderNotifierProvider);
    final reminders = state.upcoming();

    return Scaffold(
      backgroundColor: FalimyTheme.mistBlueSoft,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: FalimyTheme.ink,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: FalimyTheme.ink,
                    ),
                    const Expanded(
                      child: Text(
                        'Pay reminders',
                        style: TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'We’ll notify you before each due date.',
                  style: TextStyle(
                    color: FalimyTheme.muted.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: reminders.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
                        children: const [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 56,
                            color: FalimyTheme.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No payment reminders yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FalimyTheme.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add rent, bills or school fees and we will ping you before they are due.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FalimyTheme.muted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: reminders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final reminder = reminders[index];
                          return _ReminderTile(
                            reminder: reminder,
                            onTap: () => _openReminder(context, ref, reminder),
                            onEdit: () => _openAdd(context, existing: reminder),
                            onPaid: () =>
                                recordReminderAsPaid(context, ref, reminder),
                            onNotPaid: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'We’ll keep this reminder until you pay.',
                                  ),
                                ),
                              );
                            },
                            onDelete: () => _delete(context, ref, reminder),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onTap,
    required this.onEdit,
    required this.onPaid,
    required this.onNotPaid,
    required this.onDelete,
  });

  final PaymentReminder reminder;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPaid;
  final VoidCallback onNotPaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final days = reminder.daysUntilDue();
    final ask = reminder.needsPaymentPrompt;
    final accent = days < 0
        ? const Color(0xFFC1121F)
        : days <= 1
        ? const Color(0xFFD97706)
        : FalimyTheme.seed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            color: FalimyTheme.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reminder.amountLabel} · ${reminder.dueLabel()}'
                          '${reminder.monthly ? ' · Monthly' : ''}',
                          style: const TextStyle(
                            color: FalimyTheme.muted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ask
                              ? 'Did you pay this?'
                              : 'Notify ${reminder.remindLabel().toLowerCase()}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (ask) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onNotPaid,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: onPaid,
                        style: FilledButton.styleFrom(
                          backgroundColor: FalimyTheme.ink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Paid'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
