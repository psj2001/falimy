import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/add_entry_screen.dart';
import 'package:falimy/features/financial/presentation/widgets/entry_tile.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';
import 'package:falimy/features/financial/presentation/widgets/summary_card.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.showCreatedCelebration = false,
  });

  final String bookId;
  final bool showCreatedCelebration;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  final _searchController = TextEditingController();
  EntryType? _typeFilter;
  DateTime? _dateFilter;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _showCelebration = widget.showCreatedCelebration;
    _searchController.addListener(() => setState(() {}));
    if (widget.showCreatedCelebration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New book successfully created.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEntry(EntryType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          bookId: widget.bookId,
          type: type,
        ),
      ),
    );
  }

  List<CashEntry> _filtered(List<CashEntry> entries) {
    final q = _searchController.text.trim().toLowerCase();
    return entries.where((e) {
      if (_typeFilter != null && e.type != _typeFilter) return false;
      if (_dateFilter != null) {
        final d = _dateFilter!;
        if (e.dateTime.year != d.year ||
            e.dateTime.month != d.month ||
            e.dateTime.day != d.day) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      final remark = (e.remark ?? '').toLowerCase();
      final amount = FinancialFormat.amount(e.amount).toLowerCase();
      final contact = (e.contact ?? '').toLowerCase();
      return remark.contains(q) ||
          amount.contains(q) ||
          contact.contains(q) ||
          e.amount.toString().contains(q);
    }).toList();
  }

  Map<String, List<CashEntry>> _groupByDay(List<CashEntry> entries) {
    final map = <String, List<CashEntry>>{};
    for (final e in entries) {
      final key = FinancialFormat.dayKey(e.dateTime);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Map<String, double> _runningBalances(List<CashEntry> chronological) {
    // chronological: oldest first
    var balance = 0.0;
    final result = <String, double>{};
    for (final e in chronological) {
      balance += e.isCashIn ? e.amount : -e.amount;
      result[e.id] = balance;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialNotifierProvider);
    final book = state.bookById(widget.bookId);
    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book')),
        body: const Center(child: Text('Book not found')),
      );
    }

    final balance = state.balanceFor(book.id);
    final allEntries = state.entriesFor(book.id);
    final filtered = _filtered(allEntries);
    final chronological = [...allEntries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final running = _runningBalances(chronological);
    final grouped = _groupByDay(filtered);
    final dayKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          children: [
            Text(book.name),
            Text(
              book.access == BookAccess.justMe
                  ? 'Tap here for Book settings'
                  : 'Add Member, Book Activity etc.',
              style: const TextStyle(
                fontSize: 12,
                color: FalimyTheme.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add members coming soon')),
              );
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F5E9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by remark or amount',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            icon: Icons.tune,
                            label: 'Filters',
                            selected: _typeFilter != null || _dateFilter != null,
                            onTap: () async {
                              final type = await showModalBottomSheet<EntryType?>(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text('All entries'),
                                        onTap: () => Navigator.pop(ctx, null),
                                      ),
                                      ListTile(
                                        title: const Text('Cash In only'),
                                        onTap: () =>
                                            Navigator.pop(ctx, EntryType.cashIn),
                                      ),
                                      ListTile(
                                        title: const Text('Cash Out only'),
                                        onTap: () =>
                                            Navigator.pop(ctx, EntryType.cashOut),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              setState(() => _typeFilter = type);
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.calendar_today_outlined,
                            label: _dateFilter == null
                                ? 'Select Date'
                                : FinancialFormat.pickerDate(_dateFilter!),
                            selected: _dateFilter != null,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dateFilter ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _dateFilter = picked);
                              }
                            },
                          ),
                          if (_dateFilter != null || _typeFilter != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => setState(() {
                                _dateFilter = null;
                                _typeFilter = null;
                              }),
                              child: const Text('Clear'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SummaryCard(
                      netBalance: balance.net,
                      totalIn: balance.totalIn,
                      totalOut: balance.totalOut,
                      onViewReports: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reports coming soon'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Text(
                              'Add your first entry',
                              style: TextStyle(
                                color: FalimyTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Icon(Icons.arrow_downward, color: FalimyTheme.seed),
                          ],
                        ),
                      )
                    else
                      ...dayKeys.map((key) {
                        final dayEntries = grouped[key]!;
                        final label = FinancialFormat.entryDay(
                          dayEntries.first.dateTime,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                '${dayEntries.length} ${dayEntries.length == 1 ? 'entry' : 'entries'} · $label',
                                style: const TextStyle(
                                  color: FalimyTheme.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...dayEntries.map(
                              (e) => EntryTile(
                                entry: e,
                                runningBalance: running[e.id] ?? 0,
                                onLongPress: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete entry?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await ref
                                        .read(financialNotifierProvider.notifier)
                                        .deleteEntry(e.id);
                                  }
                                },
                              ),
                            ),
                            if (book.access == BookAccess.justMe)
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_outline,
                                        color: FalimyTheme.seed, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Only you can see these entries.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Record Income',
                        style: TextStyle(
                          color: FalimyTheme.seed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: FalimyTheme.seed,
                          ),
                          onPressed: () => _openEntry(EntryType.cashIn),
                          child: const Text('+ Cash In'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Record Expense',
                        style: TextStyle(
                          color: Color(0xFFC1121F),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC1121F),
                          ),
                          onPressed: () => _openEntry(EntryType.cashOut),
                          child: const Text('— Cash Out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showCelebration)
            Positioned.fill(
              child: _CreatedModal(
                onStart: () {
                  setState(() => _showCelebration = false);
                  _openEntry(EntryType.cashIn);
                },
                onDismiss: () => setState(() => _showCelebration = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? FalimyTheme.seed.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? FalimyTheme.seed
                : FalimyTheme.muted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: FalimyTheme.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedModal extends StatelessWidget {
  const _CreatedModal({
    required this.onStart,
    required this.onDismiss,
  });

  final VoidCallback onStart;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          FalimyTheme.seed.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 36,
                        color: FalimyTheme.seed,
                      ),
                    ),
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: FalimyTheme.seed,
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'New Book Created!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: FalimyTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can customize entry fields & start adding entries to your book.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FalimyTheme.muted),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: FalimyTheme.muted.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enable notifications so you never miss an entry across any of your books.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Enable notification'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onStart,
                    child: const Text('Start adding entries'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
