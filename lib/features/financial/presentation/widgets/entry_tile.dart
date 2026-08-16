import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/domain/entities/cash_entry.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.runningBalance,
    this.onLongPress,
  });

  final CashEntry entry;
  final double runningBalance;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isIn = entry.isCashIn;
    final amountColor = isIn ? FalimyTheme.seed : const Color(0xFFC1121F);

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FalimyTheme.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.paymentMode ?? 'Cash',
                    style: const TextStyle(
                      color: FalimyTheme.seed,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  FinancialFormat.amount(entry.amount),
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Balance: ${FinancialFormat.amount(runningBalance)}',
                style: const TextStyle(
                  color: FalimyTheme.muted,
                  fontSize: 12,
                ),
              ),
            ),
            if (entry.remark != null && entry.remark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.remark!,
                style: const TextStyle(color: FalimyTheme.ink, fontSize: 13),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Entry by ${entry.createdByLabel} at ${FinancialFormat.entryTime(entry.dateTime)}',
              style: const TextStyle(color: FalimyTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
