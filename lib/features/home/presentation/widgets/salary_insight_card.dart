import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';

/// Prompt card shown when the user has not added a salary.
class SalaryInsightCard extends StatelessWidget {
  const SalaryInsightCard({
    super.key,
    required this.onAddSalary,
  });

  final VoidCallback onAddSalary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: FalimyTheme.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5B8DEF),
                      Color(0xFFD6E4FF),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Salary missing',
                  style: TextStyle(
                    color: FalimyTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: FalimyTheme.muted.withValues(alpha: 0.95),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(text: 'Add your salary to unlock a more accurate '),
                  TextSpan(
                    text: 'monthly budget',
                    style: TextStyle(
                      color: FalimyTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: onAddSalary,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Add Salary'),
            ),
          ),
        ],
      ),
    );
  }
}
