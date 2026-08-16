import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.netBalance,
    required this.totalIn,
    required this.totalOut,
    this.onViewReports,
  });

  final double netBalance;
  final double totalIn;
  final double totalOut;
  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _row(
            label: 'Net Balance',
            value: FinancialFormat.amount(netBalance),
            valueColor: FalimyTheme.ink,
            bold: true,
          ),
          const Divider(height: 20),
          _row(
            label: 'Total In (+)',
            value: FinancialFormat.amount(totalIn),
            valueColor: FalimyTheme.seed,
          ),
          const SizedBox(height: 10),
          _row(
            label: 'Total Out (-)',
            value: FinancialFormat.amount(totalOut),
            valueColor: const Color(0xFFC1121F),
          ),
          if (onViewReports != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onViewReports,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Reports',
                    style: TextStyle(
                      color: FalimyTheme.seed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: FalimyTheme.seed, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    required Color valueColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: FalimyTheme.ink,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}
