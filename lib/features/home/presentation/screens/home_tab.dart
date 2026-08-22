import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/budget/domain/budget_analysis.dart';
import 'package:falimy/features/budget/presentation/providers/budget_notifier.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_style.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/screens/add_book_screen.dart';
import 'package:falimy/features/financial/presentation/screens/book_detail_screen.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/home/presentation/screens/add_salary_screen.dart';
import 'package:falimy/features/home/presentation/widgets/add_asset_insight_card.dart';
import 'package:falimy/features/home/presentation/widgets/cash_book_insight_card.dart';
import 'package:falimy/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:falimy/features/home/presentation/widgets/salary_insight_card.dart';
import 'package:falimy/features/home/presentation/widgets/unexpected_expense_cards.dart';
import 'package:falimy/features/home/presentation/widgets/vehicle_insurance_cards.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';
import 'package:falimy/features/reminders/presentation/widgets/pay_reminder_insight_card.dart';
import 'package:falimy/features/reminders/presentation/widgets/upcoming_pay_reminder_cards.dart';

/// Dashboard landing tab: greeting + insight cards + monthly budget.
class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onOpenBudget,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenBudget;

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(onboardingNotifierProvider.notifier).reload();
    await ref.read(financialNotifierProvider.notifier).load();
    await ref.read(notificationNotifierProvider.notifier).load();
    await ref.read(budgetNotifierProvider.notifier).load(silent: true);
    await ref.read(assetNotifierProvider.notifier).load();
    await ref.read(paymentReminderNotifierProvider.notifier).load();
  }

  Future<void> _openAddSalary(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddSalaryScreen()));
  }

  Future<void> _createCashBook(BuildContext context) async {
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final book = await Navigator.of(context).push<CashBook>(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(initialName: '$monthName Expenses'),
      ),
    );
    if (book == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BookDetailScreen(bookId: book.id, showCreatedCelebration: true),
      ),
    );
  }

  bool _needsSalary(num? salary) => salary == null || salary <= 0;

  bool _hasBookForCurrentMonth(List<CashBook> books) {
    final now = DateTime.now();
    return books.any(
      (b) => b.createdAt.year == now.year && b.createdAt.month == now.month,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingNotifierProvider);
    final notifications = ref.watch(notificationNotifierProvider);
    final financial = ref.watch(financialNotifierProvider);
    final budgetState = ref.watch(budgetNotifierProvider);
    final analysis = ref.watch(budgetAnalysisProvider);
    final assets = ref.watch(assetNotifierProvider);
    final reminders = ref.watch(paymentReminderNotifierProvider);
    final showSalaryCard = _needsSalary(profile.salary);
    final hasAnyBook = financial.books.isNotEmpty;
    final showCashBookCard =
        !financial.isLoading && !_hasBookForCurrentMonth(financial.books);

    final insightCards = <Widget>[
      if (showSalaryCard) SalaryInsightCard(onAddSalary: () => _openAddSalary(context)),
      if (showCashBookCard)
        CashBookInsightCard(
          hasAnyBook: hasAnyBook,
          onCreateBook: () => _createCashBook(context),
        ),
      AddAssetInsightCard(
        itemCount: assets.count(),
        totalValue: assets.totalValue(),
      ),
      PayReminderInsightCard(next: reminders.next()),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            color: FalimyTheme.seed,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeGreetingHeader(
                    profile: profile,
                    onTapAvatar: onOpenProfile,
                    onTapNotifications: onOpenNotifications,
                    unreadCount: notifications.unreadCount,
                  ),
                ),
                const SizedBox(height: 16),
                if (insightCards.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: insightCards.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final cardWidth = insightCards.length == 1
                            ? screenWidth - 40
                            : screenWidth * 0.78;
                        return SizedBox(
                          width: cardWidth,
                          child: insightCards[index],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BudgetCard(
                    isLoading: budgetState.isLoading && analysis == null,
                    analysis: analysis,
                    onOpen: onOpenBudget,
                  ),
                ),
                const SizedBox(height: 24),
                const VehicleInsuranceCards(),
                const UpcomingPayReminderCards(),
                const UnexpectedExpenseCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.isLoading,
    required this.analysis,
    required this.onOpen,
  });

  final bool isLoading;
  final BudgetAnalysis? analysis;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = analysis;
    final hasPlan = data?.hasPlan ?? false;
    final currency = ref.watch(preferredCurrencyProvider);

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
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

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

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
        child: Padding(padding: const EdgeInsets.all(16), child: child),
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
