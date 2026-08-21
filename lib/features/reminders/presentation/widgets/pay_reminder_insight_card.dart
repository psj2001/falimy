import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/presentation/screens/add_edit_payment_reminder_screen.dart';
import 'package:falimy/features/reminders/presentation/screens/payment_reminders_screen.dart';

class PayReminderInsightCard extends StatelessWidget {
  const PayReminderInsightCard({super.key, this.next});

  final PaymentReminder? next;

  void _open(BuildContext context, {bool add = false}) {
    if (add || next == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddEditPaymentReminderScreen()),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentRemindersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final reminder = next;
    final hasReminders = reminder != null;
    final title = hasReminders ? 'Pay reminders' : 'Pay reminder';
    final buttonLabel = hasReminders ? 'View reminders' : 'Add reminder';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5B8DEF), Color(0xFFD6E4FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: FalimyTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: hasReminders
                    ? Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: FalimyTheme.muted.withValues(alpha: 0.95),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: reminder.title,
                              style: const TextStyle(
                                color: FalimyTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' · ${reminder.amountLabel}. ${reminder.dueLabel()}.',
                            ),
                          ],
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: FalimyTheme.muted.withValues(alpha: 0.95),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(text: 'Set a reminder for '),
                            TextSpan(
                              text: 'rent, bills or school fees',
                              style: TextStyle(
                                color: FalimyTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: '. We will notify you before the due date.',
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton(
                  onPressed: () => _open(context, add: !hasReminders),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
