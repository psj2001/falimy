import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';

/// Prompt when the user has no cash book, or none for the current month.
class CashBookInsightCard extends StatelessWidget {
  const CashBookInsightCard({
    super.key,
    required this.hasAnyBook,
    required this.onCreateBook,
  });

  final bool hasAnyBook;
  final VoidCallback onCreateBook;

  String get _monthLabel => DateFormat.MMMM().format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final title = hasAnyBook ? "$_monthLabel cash book" : 'Cash book missing';
    final body = hasAnyBook
        ? 'You have not created a cash book for '
        : 'Create a cash book to track your ';
    final highlight = hasAnyBook ? _monthLabel : 'income and expenses';
    final suffix = hasAnyBook ? ' yet.' : '.';

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
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
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
                children: [
                  TextSpan(text: body),
                  TextSpan(
                    text: highlight,
                    style: const TextStyle(
                      color: FalimyTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: suffix),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: onCreateBook,
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
              child: const Text('Create Book'),
            ),
          ),
        ],
      ),
    );
  }
}
