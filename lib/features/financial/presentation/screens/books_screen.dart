import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/add_book_screen.dart';
import 'package:falimy/features/financial/presentation/screens/book_detail_screen.dart';
import 'package:falimy/features/financial/presentation/widgets/book_actions_sheet.dart';
import 'package:falimy/features/financial/presentation/widgets/book_tile.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  static const _suggestions = [
    'August Expenses',
    'New Project',
    'Client Record',
    'Project Book',
  ];

  String _search = '';
  bool _showTip = true;

  Future<void> _openAddBook({String? prefill}) async {
    final book = await Navigator.of(context).push<CashBook>(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(initialName: prefill),
      ),
    );
    if (book != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            bookId: book.id,
            showCreatedCelebration: true,
          ),
        ),
      );
    }
  }

  Future<void> _handleBookAction(CashBook book) async {
    final action = await BookActionsSheet.show(context, book);
    if (action == null || !mounted) return;

    final notifier = ref.read(financialNotifierProvider.notifier);
    switch (action) {
      case BookAction.rename:
        final name = await _promptText(
          title: 'Rename book',
          initial: book.name,
          confirmLabel: 'Rename',
        );
        if (name != null) {
          await notifier.renameBook(bookId: book.id, name: name);
        }
      case BookAction.duplicate:
        await notifier.duplicateBook(book.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book duplicated')),
          );
        }
      case BookAction.addMembers:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sharing with family members coming soon'),
            ),
          );
        }
      case BookAction.move:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Move book coming soon')),
          );
        }
      case BookAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete book?'),
            content: Text(
              'Delete "${book.name}" and all its entries? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC1121F),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await notifier.deleteBook(book.id);
        }
    }
  }

  Future<String?> _promptText({
    required String title,
    required String initial,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Book name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialNotifierProvider);
    final profile = ref.watch(onboardingNotifierProvider);
    final workspaceName = (profile.fullName?.trim().isNotEmpty ?? false)
        ? "${profile.fullName!.trim().split(' ').first}'s Business"
        : 'My Business';

    final books = state.books.where((b) {
      if (_search.trim().isEmpty) return true;
      return b.name.toLowerCase().contains(_search.trim().toLowerCase());
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Material(
      type: MaterialType.transparency,
      child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD8F3DC),
            Color(0xFFF7F3EB),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_outlined,
                          color: FalimyTheme.seed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspaceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: FalimyTheme.ink,
                              ),
                            ),
                            const Text(
                              'Tap to switch business',
                              style: TextStyle(
                                color: FalimyTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add members coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: FalimyTheme.seed, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are on Free Trial. 30 days remaining.',
                          style: TextStyle(
                            color: FalimyTheme.ink,
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
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Your Books',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: FalimyTheme.ink,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.filter_list),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final value = await _promptText(
                                      title: 'Search books',
                                      initial: _search,
                                      confirmLabel: 'Search',
                                    );
                                    if (value != null) {
                                      setState(() => _search = value);
                                    }
                                  },
                                  icon: const Icon(Icons.search),
                                ),
                              ],
                            ),
                            if (_showTip)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline,
                                        color: Color(0xFF5E35B1)),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Tap to view your entries in this book.',
                                        style: TextStyle(
                                          color: FalimyTheme.ink,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          setState(() => _showTip = false),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            if (books.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'No books yet. Create your first cash book.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: FalimyTheme.muted),
                                ),
                              )
                            else
                              ...books.map(
                                (book) => BookTile(
                                  book: book,
                                  balance: state.balanceFor(book.id).net,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BookDetailScreen(bookId: book.id),
                                      ),
                                    );
                                  },
                                  onMore: () => _handleBookAction(book),
                                ),
                              ),
                            const SizedBox(height: 16),
                            _quickAddCard(),
                          ],
                        ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton.extended(
                onPressed: () => _openAddBook(),
                backgroundColor: FalimyTheme.seed,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add new book'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _quickAddCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Book',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: FalimyTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Click to quickly add books for',
            style: TextStyle(color: FalimyTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    backgroundColor: FalimyTheme.seed.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: FalimyTheme.seed,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => _openAddBook(prefill: s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
