import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/currency/app_currency.dart';

Future<String?> showCurrencyPickerSheet(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FalimyTheme.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CurrencyPickerSheet(selected: selected),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selected});

  final String selected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppCurrency> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return AppCurrency.all;
    return AppCurrency.all
        .where(
          (currency) =>
              currency.code.toLowerCase().contains(query) ||
              currency.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selected = AppCurrency.normalize(widget.selected);
    final items = _filtered;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FalimyTheme.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Currency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Amounts stay the same. Only the currency label changes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FalimyTheme.muted,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              autofocus: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search currency',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No matching currency'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: FalimyTheme.muted.withValues(alpha: 0.16),
                      ),
                      itemBuilder: (context, index) {
                        final currency = items[index];
                        final isSelected = currency.code == selected;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: FalimyTheme.seed.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: FalimyTheme.seed,
                            child: Text(
                              currency.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(currency.name),
                          subtitle: Text(currency.code),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: FalimyTheme.seed,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(currency.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
