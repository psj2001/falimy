import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/onboarding_scaffold.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/reminders/data/payment_reminder_notifications.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';

class AddEditPaymentReminderScreen extends ConsumerStatefulWidget {
  const AddEditPaymentReminderScreen({super.key, this.existing});

  final PaymentReminder? existing;

  @override
  ConsumerState<AddEditPaymentReminderScreen> createState() =>
      _AddEditPaymentReminderScreenState();
}

class _AddEditPaymentReminderScreenState
    extends ConsumerState<AddEditPaymentReminderScreen> {
  static const _suggestions = [
    'Rent',
    'Electricity',
    'Water',
    'Internet',
    'School fees',
    'Maid',
    'Gas',
    'Maintenance',
  ];

  static const _remindOptions = [
    (0, 'On due date'),
    (1, '1 day before'),
    (2, '2 days before'),
    (3, '3 days before'),
    (7, '1 week before'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dueDateController = TextEditingController();
  late DateTime _dueDate;
  int _remindDaysBefore = 1;
  bool _monthly = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text =
          existing.amount == existing.amount.roundToDouble()
          ? existing.amount.toStringAsFixed(0)
          : existing.amount.toString();
      _noteController.text = existing.note ?? '';
      _dueDate = PaymentReminder.dateOnly(existing.dueDate);
      _remindDaysBefore = existing.remindDaysBefore;
      _monthly = existing.monthly;
    } else {
      final now = DateTime.now();
      _dueDate = DateTime(now.year, now.month + 1, 1);
    }
    _dueDateController.text = paymentReminderDateFormat.format(_dueDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _dueDate.isBefore(today) ? today : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = PaymentReminder.dateOnly(picked);
      _dueDateController.text = paymentReminderDateFormat.format(_dueDate);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final existing = widget.existing;
    final reminder = PaymentReminder(
      id: existing?.id ?? newPaymentReminderId(),
      title: _titleController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      remindDaysBefore: _remindDaysBefore,
      monthly: _monthly,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final permission = await PaymentReminderNotifications.instance
        .requestPermission();
    final saved = await ref
        .read(paymentReminderNotifierProvider.notifier)
        .upsert(reminder);

    if (!mounted) return;
    if (saved == null) {
      setState(() => _saving = false);
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message:
            ref.read(paymentReminderNotifierProvider).error ??
            'Could not save reminder.',
      );
      return;
    }

    final notifyAt = saved.scheduleAt();
    final notifyDate = paymentReminderDateFormat.format(
      PaymentReminder.dateOnly(notifyAt ?? saved.displayDueDate()),
    );
    await showResultDialog(
      context,
      kind: ResultDialogKind.success,
      message: permission
          ? 'We will remind you on $notifyDate to pay ${saved.title}.'
          : 'Reminder saved. Enable notifications in system settings to get an alert.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: _isEditing ? 'Edit reminder' : 'Pay reminder',
      subtitle:
          'We’ll notify you before the due date so the family doesn’t miss a payment.',
      bottom: PrimaryButton(
        label: _isEditing ? 'Save reminder' : 'Set reminder',
        isLoading: _saving,
        onPressed: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in _suggestions)
                  ChoiceChip(
                    label: Text(label),
                    selected: _titleController.text == label,
                    onSelected: (_) {
                      setState(() => _titleController.text = label);
                    },
                    selectedColor: FalimyTheme.seed.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _titleController.text == label
                          ? FalimyTheme.seed
                          : FalimyTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'What to pay',
              controller: _titleController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter rent, electricity, school fees…';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'AED  ',
              ),
              validator: (value) {
                final parsed = num.tryParse(
                  (value ?? '').trim().replaceAll(',', ''),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Enter the amount to pay';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Due date',
              controller: _dueDateController,
              readOnly: true,
              onTap: _pickDueDate,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat every month'),
              subtitle: const Text(
                'Use for rent, school fees and other family bills.',
              ),
              value: _monthly,
              activeThumbColor: FalimyTheme.seed,
              onChanged: (value) => setState(() => _monthly = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Notify me',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: FalimyTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _remindOptions)
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _remindDaysBefore == option.$1,
                    onSelected: (_) {
                      setState(() => _remindDaysBefore = option.$1);
                    },
                    selectedColor: FalimyTheme.seed.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _remindDaysBefore == option.$1
                          ? FalimyTheme.seed
                          : FalimyTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Note (optional)',
              controller: _noteController,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
