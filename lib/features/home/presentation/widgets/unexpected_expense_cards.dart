import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/home/domain/unexpected_expense_category.dart';
import 'package:falimy/features/home/presentation/screens/add_unexpected_expense_screen.dart';
import 'package:falimy/features/home/presentation/screens/unexpected_expenses_screen.dart';

class UnexpectedExpenseCards extends StatelessWidget {
  const UnexpectedExpenseCards({super.key});

  void _openCategory(
    BuildContext context,
    UnexpectedExpenseCategory category,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddUnexpectedExpenseScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const categories = UnexpectedExpenseCategory.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Unexpected expenses',
                  style: TextStyle(
                    color: FalimyTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UnexpectedExpensesScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: FalimyTheme.seed,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _ExpenseTypeCard(
                category: category,
                onTap: () => _openCategory(context, category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpenseTypeCard extends StatelessWidget {
  const _ExpenseTypeCard({
    required this.category,
    required this.onTap,
  });

  final UnexpectedExpenseCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 112,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 42,
                width: 42,
                child: category.assetPath != null
                    ? Image.asset(
                        category.assetPath!,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        category.fallbackIcon ?? Icons.category_outlined,
                        size: 32,
                        color: FalimyTheme.seed,
                      ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  category.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FalimyTheme.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
