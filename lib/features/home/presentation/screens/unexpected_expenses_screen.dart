import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/home/domain/unexpected_expense_category.dart';
import 'package:falimy/features/home/presentation/screens/add_unexpected_expense_screen.dart';

class UnexpectedExpensesScreen extends StatelessWidget {
  const UnexpectedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = UnexpectedExpenseCategory.all;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Unexpected expenses'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddUnexpectedExpenseScreen(
                      category: category,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FalimyTheme.seed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: category.assetPath != null
                          ? Image.asset(
                              category.assetPath!,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              category.fallbackIcon ?? Icons.category_outlined,
                              color: FalimyTheme.seed,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: const TextStyle(
                              color: FalimyTheme.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.examples.first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FalimyTheme.muted,
                              fontSize: 12,
                              height: 1.3,
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
