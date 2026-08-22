import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/currency/app_currency.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/domain/entities/entry_category.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/choose_category_screen.dart';
import 'package:falimy/features/financial/presentation/screens/payment_modes_screen.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({
    super.key,
    required this.bookId,
    required this.type,
  });

  final String bookId;
  final EntryType type;

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _amountController = TextEditingController();
  final _contactController = TextEditingController();
  final _remarkController = TextEditingController();

  late DateTime _dateTime;
  String? _categoryId;
  String? _paymentMode;
  bool _initializedPayment = false;

  bool get _isCashIn => widget.type == EntryType.cashIn;

  @override
  void initState() {
    super.initState();
    _dateTime = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _contactController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickCategory() async {
    final selected = await Navigator.of(context).push<EntryCategory?>(
      MaterialPageRoute(
        builder: (_) => ChooseCategoryScreen(
          bookId: widget.bookId,
          selectedCategoryId: _categoryId,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _categoryId = selected?.id);
  }

  Future<void> _pickPaymentMode({bool openFull = false}) async {
    if (!openFull) return;
    final selected = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => PaymentModesScreen(
          bookId: widget.bookId,
          selectedMode: _paymentMode,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _paymentMode = selected);
  }

  Future<bool> _save({required bool addNew}) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return false;
    }

    final entry = CashEntry(
      id: '',
      bookId: widget.bookId,
      type: widget.type,
      amount: amount,
      dateTime: _dateTime,
      contact: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
      categoryId: _categoryId,
      paymentMode: _paymentMode,
    );

    final saved =
        await ref.read(financialNotifierProvider.notifier).addEntry(entry);
    if (saved == null || !mounted) return false;

    if (addNew) {
      _amountController.clear();
      _contactController.clear();
      _remarkController.clear();
      setState(() {
        _categoryId = null;
        _dateTime = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved')),
      );
      return true;
    }

    Navigator.of(context).pop(saved);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialNotifierProvider);
    final modes = state.paymentModesFor(widget.bookId);
    final categories = state.categoriesFor(widget.bookId);
    EntryCategory? selectedCategory;
    for (final c in categories) {
      if (c.id == _categoryId) {
        selectedCategory = c;
        break;
      }
    }

    if (!_initializedPayment && modes.isNotEmpty && _paymentMode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initializedPayment) return;
        setState(() {
          _initializedPayment = true;
          _paymentMode = modes.first.name;
        });
      });
    }

    final accent = _isCashIn ? FalimyTheme.seed : const Color(0xFFC1121F);
    final visibleModes = modes.take(2).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          _isCashIn ? 'Add Cash In Entry' : 'Add Cash Out Entry',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: FalimyTheme.seed),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: FalimyTheme.seed, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are on Free Trial. 30 days remaining.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: FalimyTheme.muted),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          icon: Icons.calendar_today_outlined,
                          label: FinancialFormat.pickerDate(_dateTime),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerField(
                          icon: Icons.access_time,
                          label: FinancialFormat.pickerTime(_dateTime),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      label: Text.rich(
                        TextSpan(
                          text: 'Amount ',
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                      prefixText: AppCurrency.prefix(
                        ref.watch(preferredCurrencyProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact (Customer/Supplier)',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarkController,
                    decoration: const InputDecoration(
                      labelText: 'Remark',
                      suffixIcon: Icon(
                        Icons.mic_none_outlined,
                        color: FalimyTheme.seed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attachments coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.attach_file, color: FalimyTheme.seed),
                    label: const Text(
                      'Attach image or PDF',
                      style: TextStyle(color: FalimyTheme.seed),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickCategory,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        selectedCategory?.name ?? 'Category',
                        style: TextStyle(
                          color: selectedCategory == null
                              ? FalimyTheme.muted
                              : FalimyTheme.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(
                      color: FalimyTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...visibleModes.map(
                        (m) => ChoiceChip(
                          label: Text(m.name),
                          selected: _paymentMode == m.name,
                          selectedColor: FalimyTheme.seed,
                          labelStyle: TextStyle(
                            color: _paymentMode == m.name
                                ? Colors.white
                                : FalimyTheme.seed,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setState(() => _paymentMode = m.name),
                        ),
                      ),
                      ActionChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Show more'),
                            Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                        onPressed: () => _pickPaymentMode(openFull: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Custom fields coming soon'),
                        ),
                      );
                    },
                    child: const Text('Add more fields'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isSaving
                          ? null
                          : () => _save(addNew: true),
                      child: const Text('Save & add new'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save',
                      isLoading: state.isSaving,
                      onPressed: () => _save(addNew: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: FalimyTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FalimyTheme.ink,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: FalimyTheme.muted),
          ],
        ),
      ),
    );
  }
}
