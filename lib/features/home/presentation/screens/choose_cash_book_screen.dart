import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/onboarding_scaffold.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';

class ChooseCashBookScreen extends ConsumerWidget {
  const ChooseCashBookScreen({
    super.key,
    this.subtitle = 'Choose where to add this unexpected expense',
  });

  final String subtitle;

  bool _isCurrentMonth(CashBook book) {
    final now = DateTime.now();
    return book.createdAt.year == now.year && book.createdAt.month == now.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financial = ref.watch(financialNotifierProvider);
    final books = [...financial.books]
      ..sort((a, b) {
        final aCurrent = _isCurrentMonth(a);
        final bCurrent = _isCurrentMonth(b);
        if (aCurrent != bCurrent) return aCurrent ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return OnboardingScaffold(
      title: 'Which cash book?',
      subtitle: subtitle,
      child: ListView.separated(
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final book = books[index];
          final thisMonth = _isCurrentMonth(book);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(book),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: thisMonth
                      ? FalimyTheme.seed.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: thisMonth
                        ? FalimyTheme.seed.withValues(alpha: 0.45)
                        : FalimyTheme.muted.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FalimyTheme.seed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: FalimyTheme.seed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: FalimyTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            thisMonth
                                ? 'This month'
                                : FinancialFormat.bookMeta(
                                    createdAt: book.createdAt,
                                    updatedAt: book.updatedAt,
                                  ),
                            style: TextStyle(
                              color: thisMonth
                                  ? FalimyTheme.seed
                                  : FalimyTheme.muted,
                              fontSize: 12,
                              fontWeight: thisMonth
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: FalimyTheme.muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
