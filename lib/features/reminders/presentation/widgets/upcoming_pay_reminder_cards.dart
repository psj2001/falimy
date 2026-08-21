import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';
import 'package:falimy/features/reminders/presentation/screens/add_edit_payment_reminder_screen.dart';
import 'package:falimy/features/reminders/presentation/screens/payment_reminders_screen.dart';
import 'package:falimy/features/reminders/presentation/widgets/payment_status_prompt.dart';

final Set<String> _promptedPaymentReminders = <String>{};

class UpcomingPayReminderCards extends ConsumerStatefulWidget {
  const UpcomingPayReminderCards({super.key});

  @override
  ConsumerState<UpcomingPayReminderCards> createState() =>
      _UpcomingPayReminderCardsState();
}

class _UpcomingPayReminderCardsState
    extends ConsumerState<UpcomingPayReminderCards> {
  bool _asking = false;

  @override
  Widget build(BuildContext context) {
    final dueSoon = ref.watch(
      paymentReminderNotifierProvider.select((s) => s.dueSoon()),
    );
    final pending = dueSoon.where(
      (item) =>
          item.needsPaymentPrompt &&
          !_promptedPaymentReminders.contains(item.inboxId),
    );
    if (pending.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askIfNeeded());
    }

    if (dueSoon.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment reminders',
                  style: TextStyle(
                    color: FalimyTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PaymentRemindersScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: FalimyTheme.seed,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < dueSoon.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ReminderCard(
              reminder: dueSoon[i],
              onOpen: () => _open(dueSoon[i]),
              onPaid: () => recordReminderAsPaid(context, ref, dueSoon[i]),
              onNotPaid: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('We’ll keep this reminder until you pay.'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _askIfNeeded() async {
    if (!mounted || _asking) return;
    _asking = true;
    try {
      final due = ref
          .read(paymentReminderNotifierProvider)
          .dueSoon()
          .where((item) => item.needsPaymentPrompt)
          .toList();
      for (final reminder in due) {
        if (_promptedPaymentReminders.contains(reminder.inboxId)) continue;
        _promptedPaymentReminders.add(reminder.inboxId);
        if (!mounted) return;
        await promptPaymentReminderStatus(context, ref, reminder);
      }
    } finally {
      _asking = false;
    }
  }

  Future<void> _open(PaymentReminder reminder) async {
    if (reminder.needsPaymentPrompt) {
      _promptedPaymentReminders.add(reminder.inboxId);
      await promptPaymentReminderStatus(context, ref, reminder);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditPaymentReminderScreen(existing: reminder),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onOpen,
    required this.onPaid,
    required this.onNotPaid,
  });

  final PaymentReminder reminder;
  final VoidCallback onOpen;
  final VoidCallback onPaid;
  final VoidCallback onNotPaid;

  @override
  Widget build(BuildContext context) {
    final days = reminder.daysUntilDue();
    final ask = reminder.needsPaymentPrompt;
    final accent = days < 0
        ? const Color(0xFFC1121F)
        : days <= 1
        ? const Color(0xFFD97706)
        : FalimyTheme.seed;
    final radius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FalimyTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reminder.amountLabel}'
                          '${reminder.monthly ? ' · Monthly' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FalimyTheme.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ask ? 'Did you pay this?' : reminder.dueLabel(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!ask)
                    const Icon(Icons.chevron_right, color: FalimyTheme.muted),
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
