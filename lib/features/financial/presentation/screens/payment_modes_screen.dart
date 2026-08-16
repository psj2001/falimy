import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';

class PaymentModesScreen extends ConsumerStatefulWidget {
  const PaymentModesScreen({
    super.key,
    required this.bookId,
    this.selectedMode,
  });

  final String bookId;
  final String? selectedMode;

  @override
  ConsumerState<PaymentModesScreen> createState() => _PaymentModesScreenState();
}

class _PaymentModesScreenState extends ConsumerState<PaymentModesScreen> {
  static const _suggestions = [
    'Bank',
    'Debit Card',
    'Credit Card',
    'Cheque',
  ];

  late String? _selected = widget.selectedMode;
  String _query = '';

  Future<void> _addNew({String? prefill}) async {
    final controller = TextEditingController(text: prefill ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add payment mode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Payment mode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final mode = await ref
        .read(financialNotifierProvider.notifier)
        .addPaymentMode(bookId: widget.bookId, name: name);
    if (mode != null && mounted) {
      setState(() => _selected = mode.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = ref
        .watch(financialNotifierProvider)
        .paymentModesFor(widget.bookId)
        .where((m) =>
            _query.isEmpty ||
            m.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final existingNames = modes.map((m) => m.name.toLowerCase()).toSet();
    final suggestions =
        _suggestions.where((s) => !existingNames.contains(s.toLowerCase()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Payment Modes'),
        actions: [
          IconButton(
            onPressed: () async {
              final controller = TextEditingController(text: _query);
              final value = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Search'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (value != null) setState(() => _query = value.trim());
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNew(),
        backgroundColor: FalimyTheme.seed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add new'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const Text(
            'Payment Modes in this book',
            style: TextStyle(
              color: FalimyTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ModeTile(
            label: 'No Payment Mode',
            selected: _selected == null,
            onTap: () => Navigator.pop(context, null),
          ),
          ...modes.map(
            (m) => _ModeTile(
              label: m.name,
              selected: _selected == m.name,
              onTap: () => Navigator.pop(context, m.name),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Suggestions',
              style: TextStyle(
                color: FalimyTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      onPressed: () => _addNew(prefill: s),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? FalimyTheme.seed.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? FalimyTheme.seed
                  : FalimyTheme.muted.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? FalimyTheme.seed : FalimyTheme.muted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FalimyTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
