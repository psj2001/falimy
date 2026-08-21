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

  Future<void> _toggleCloud(CashBook book) async {
    final notifier = ref.read(financialNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (book.syncedToCloud) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove from cloud?'),
          content: Text(
            '"${book.name}" will be removed from the cloud. It stays on this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final ok = await notifier.removeBookFromCloud(book.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Removed from cloud'
                : (ref.read(financialNotifierProvider).error ??
                    'Could not remove from cloud'),
          ),
        ),
      );
      return;
    }

    final ok = await notifier.saveBookToCloud(book.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Saved to cloud'
              : (ref.read(financialNotifierProvider).error ??
                  'Could not save to cloud. Sign in and try again.'),
        ),
      ),
    );
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

    // HomeScreen inflates MediaQuery padding so content clears the pill nav.
    final bottomClearance = MediaQuery.paddingOf(context).bottom;

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
            Colors.white,
            Colors.white,
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
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            bottomClearance + 88,
                          ),
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
                                  cloudBusy: state.cloudBusyBookId == book.id,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BookDetailScreen(bookId: book.id),
                                      ),
                                    );
                                  },
                                  onMore: () => _handleBookAction(book),
                                  onCloudToggle: () => _toggleCloud(book),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: bottomClearance + 16,
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
}
