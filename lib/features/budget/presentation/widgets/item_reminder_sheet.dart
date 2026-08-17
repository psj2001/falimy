import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/entities/budget_item.dart';
import 'package:falimy/features/budget/presentation/providers/budget_notifier.dart';

Future<void> showBudgetItemReminderSheet({
  required BuildContext context,
  required String categoryId,
  required BudgetItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FalimyTheme.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ReminderSheet(categoryId: categoryId, item: item),
  );
}

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({
    required this.categoryId,
    required this.item,
  });

  final String categoryId;
  final BudgetItem item;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late bool _enabled;
  late int _day;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _enabled = widget.item.reminderEnabled;
    _day = widget.item.reminderDay ?? 1;
    _note = TextEditingController(text: widget.item.reminderNote ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(budgetNotifierProvider.notifier).setItemReminder(
          categoryId: widget.categoryId,
          itemId: widget.item.id,
          enabled: _enabled,
          day: _day,
          note: _note.text,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            'Reminder · ${widget.item.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Get a nudge on this day each month so you don’t miss the payment.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind me monthly'),
            value: _enabled,
            activeThumbColor: FalimyTheme.seed,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          if (_enabled) ...[
            const SizedBox(height: 4),
            Text(
              'Day of month',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FalimyTheme.ink,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 28,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final selected = day == _day;
                  return ChoiceChip(
                    label: Text('$day'),
                    selected: selected,
                    onSelected: (_) => setState(() => _day = day),
                    selectedColor: FalimyTheme.seed.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected ? FalimyTheme.seed : FalimyTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Pay landlord via bank transfer',
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: Text(_enabled ? 'Save reminder' : 'Turn off reminder'),
          ),
        ],
      ),
    );
  }
}
