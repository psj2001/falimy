import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/budget/domain/budget_analysis.dart';
import 'package:falimy/features/budget/presentation/providers/budget_notifier.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_style.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/add_book_screen.dart';
import 'package:falimy/features/financial/presentation/screens/book_detail_screen.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';

/// Dashboard landing tab: greeting, family + cashbook snapshot,
/// quick actions and recent entries.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({
    super.key,
    required this.onOpenFamilyTree,
    required this.onOpenProfile,
    required this.onOpenFinancial,
    required this.onOpenNotifications,
    required this.onOpenBudget,
  });

  final VoidCallback onOpenFamilyTree;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenFinancial;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenBudget;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  Future<void> _refresh() async {
    await ref.read(onboardingNotifierProvider.notifier).reload();
    await ref.read(financialNotifierProvider.notifier).load();
    await ref.read(notificationNotifierProvider.notifier).load();
    await ref.read(budgetNotifierProvider.notifier).load(silent: true);
  }

  Future<void> _openBook(String bookId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  Future<void> _addBook() async {
    final book = await Navigator.of(context).push<CashBook>(
      MaterialPageRoute(builder: (_) => const AddBookScreen()),
    );
    if (book == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          bookId: book.id,
          showCreatedCelebration: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingNotifierProvider);
    final financial = ref.watch(financialNotifierProvider);
    final notifications = ref.watch(notificationNotifierProvider);
    final budgetState = ref.watch(budgetNotifierProvider);
    final analysis = ref.watch(budgetAnalysisProvider);

    var totalIn = 0.0;
    var totalOut = 0.0;
    for (final entry in financial.entries) {
      if (entry.isCashIn) {
        totalIn += entry.amount;
      } else {
        totalOut += entry.amount;
      }
    }

    final recent = financial.entries.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: FalimyTheme.seed,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _Greeting(
                  profile: profile,
                  onTapAvatar: widget.onOpenProfile,
                  onTapNotifications: widget.onOpenNotifications,
                  unreadCount: notifications.unreadCount,
                ),
                const SizedBox(height: 20),
                _FamilyCard(
                  profile: profile,
                  onViewTree: widget.onOpenFamilyTree,
                  onCompleteProfile: widget.onOpenProfile,
                ),
                const SizedBox(height: 16),
                _BalanceCard(
                  isLoading: financial.isLoading,
                  bookCount: financial.books.length,
                  totalIn: totalIn,
                  totalOut: totalOut,
                  onOpenBooks: widget.onOpenFinancial,
                ),
                const SizedBox(height: 16),
                _BudgetCard(
                  isLoading: budgetState.isLoading && analysis == null,
                  analysis: analysis,
                  onOpen: widget.onOpenBudget,
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Quick actions'),
                const SizedBox(height: 12),
                _QuickActions(
                  onOpenFamilyTree: widget.onOpenFamilyTree,
                  onOpenProfile: widget.onOpenProfile,
                  onOpenBooks: widget.onOpenFinancial,
                  onAddBook: _addBook,
                  onOpenBudget: widget.onOpenBudget,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _sectionTitle(context, 'Recent activity')),
                    if (recent.isNotEmpty)
                      TextButton(
                        onPressed: widget.onOpenFinancial,
                        child: const Text('See all'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (financial.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recent.isEmpty)
                  _EmptyActivity(onAddBook: _addBook)
                else
                  ...recent.take(5).map(
                        (entry) => _ActivityTile(
                          entry: entry,
                          bookName: financial.bookById(entry.bookId)?.name,
                          onTap: () => _openBook(entry.bookId),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.profile,
    required this.onTapAvatar,
    required this.onTapNotifications,
    required this.unreadCount,
  });

  final FamilyProfile profile;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapNotifications;
  final int unreadCount;

  String get _timeOfDay {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName {
    final name = profile.fullName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final family = profile.familyName?.trim();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _timeOfDay,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _firstName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (family != null && family.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '$family family',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onTapNotifications,
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTapAvatar,
          child: ProfileAvatar(
            photoPath: profile.photoPath,
            radius: 28,
          ),
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.profile,
    required this.onViewTree,
    required this.onCompleteProfile,
  });

  final FamilyProfile profile;
  final VoidCallback onViewTree;
  final VoidCallback onCompleteProfile;

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  int get _memberCount {
    var count = 0;
    if (_hasText(profile.fullName)) count++;
    if (_hasText(profile.fatherName)) count++;
    if (_hasText(profile.motherName)) count++;
    count += profile.siblings.length;
    if (profile.spouse != null) count++;
    count += profile.children.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final count = _memberCount;

    if (count == 0) {
      return _HomeCard(
        onTap: onCompleteProfile,
        child: Row(
          children: [
            const _CardIcon(icon: Icons.account_tree_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build your family tree',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add your family details to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FalimyTheme.muted),
          ],
        ),
      );
    }

    return _HomeCard(
      onTap: onViewTree,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardIcon(icon: Icons.account_tree_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your family',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'member' : 'members'} in your tree',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: FalimyTheme.muted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'Siblings',
                value: profile.siblings.length.toString(),
              ),
              _MiniStat(
                label: 'Children',
                value: profile.children.length.toString(),
              ),
              _MiniStat(
                label: 'Spouse',
                value: profile.spouse == null ? '—' : '1',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.isLoading,
    required this.bookCount,
    required this.totalIn,
    required this.totalOut,
    required this.onOpenBooks,
  });

  final bool isLoading;
  final int bookCount;
  final double totalIn;
  final double totalOut;
  final VoidCallback onOpenBooks;

  @override
  Widget build(BuildContext context) {
    final net = totalIn - totalOut;

    return _HomeCard(
      onTap: onOpenBooks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardIcon(icon: Icons.account_balance_wallet_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Net balance',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              FinancialFormat.amount(net),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: net < 0 ? const Color(0xFFC1121F) : FalimyTheme.ink,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'In (+)',
                value: FinancialFormat.amount(totalIn),
                valueColor: FalimyTheme.seed,
              ),
              _MiniStat(
                label: 'Out (-)',
                value: FinancialFormat.amount(totalOut),
                valueColor: const Color(0xFFC1121F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.isLoading,
    required this.analysis,
    required this.onOpen,
  });

  final bool isLoading;
  final BudgetAnalysis? analysis;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final data = analysis;
    final hasPlan = data?.hasPlan ?? false;
    final currency = data?.budget.currency ?? 'AED';

    return _HomeCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardIcon(icon: Icons.pie_chart_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly budget',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right, color: FalimyTheme.muted),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!hasPlan) ...[
            Text(
              'Set your monthly income',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Plan expenses against thumb-rule targets and see what to improve.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            Row(
              children: [
                _MiniStat(
                  label: 'Income',
                  value: BudgetFormat.money(
                    data!.totalIncome,
                    currency: currency,
                  ),
                ),
                _MiniStat(
                  label: 'Expense',
                  value: BudgetFormat.money(
                    data.totalPlannedExpense,
                    currency: currency,
                  ),
                  valueColor: const Color(0xFFC1121F),
                ),
                _MiniStat(
                  label: 'Saved',
                  value: BudgetFormat.percent(data.savingsRate),
                  valueColor: savingsGaugeColor(
                    data.savingsRate,
                    data.budget.savingsTargetPercent,
                  ),
                ),
              ],
            ),
            if (data.insights.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final insight in data.insights.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        insightIcon(insight.severity),
                        size: 16,
                        color: insightColor(insight.severity),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: const TextStyle(
                            color: FalimyTheme.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenFamilyTree,
    required this.onOpenProfile,
    required this.onOpenBooks,
    required this.onAddBook,
    required this.onOpenBudget,
  });

  final VoidCallback onOpenFamilyTree;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenBooks;
  final VoidCallback onAddBook;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.account_tree_rounded,
                label: 'Family tree',
                onTap: onOpenFamilyTree,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.menu_book_rounded,
                label: 'Cash books',
                onTap: onOpenBooks,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: 'New book',
                onTap: onAddBook,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.person_rounded,
                label: 'My profile',
                onTap: onOpenProfile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.pie_chart_rounded,
          label: 'Household budget',
          onTap: onOpenBudget,
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.entry,
    required this.bookName,
    required this.onTap,
  });

  final CashEntry entry;
  final String? bookName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isCashIn;
    final amountColor = isIn ? FalimyTheme.seed : const Color(0xFFC1121F);
    final remark = entry.remark?.trim();
    final subtitle = remark != null && remark.isNotEmpty
        ? remark
        : (bookName ?? 'Cash book');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _HomeCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 18,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FalimyTheme.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bookName ?? 'Cash book'} · '
                    '${FinancialFormat.entryDay(entry.dateTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FalimyTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIn ? '+' : '-'}${FinancialFormat.amount(entry.amount)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onAddBook});

  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No entries yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a cash book and add your first entry to see activity here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAddBook,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Add a cash book'),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: FalimyTheme.seed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: FalimyTheme.seed, size: 20),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.valueColor = FalimyTheme.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: FalimyTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: FalimyTheme.seed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FalimyTheme.ink,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
