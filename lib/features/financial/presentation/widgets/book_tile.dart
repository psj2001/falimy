import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/widgets/financial_format.dart';

class BookTile extends StatelessWidget {
  const BookTile({
    super.key,
    required this.book,
    required this.balance,
    required this.onTap,
    required this.onMore,
    required this.onCloudToggle,
    this.cloudBusy = false,
  });

  final CashBook book;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onMore;
  final VoidCallback onCloudToggle;
  final bool cloudBusy;

  @override
  Widget build(BuildContext context) {
    final synced = book.syncedToCloud;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FinancialFormat.bookMeta(
                      createdAt: book.createdAt,
                      updatedAt: book.updatedAt,
                    ),
                    style: const TextStyle(
                      color: FalimyTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (synced) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Saved in cloud',
                      style: TextStyle(
                        color: FalimyTheme.seed,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              FinancialFormat.amount(balance),
              style: TextStyle(
                color: balance >= 0 ? FalimyTheme.seed : const Color(0xFFC1121F),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            if (cloudBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: synced ? 'Remove from cloud' : 'Save to cloud',
                onPressed: onCloudToggle,
                icon: Icon(
                  synced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  color: synced ? FalimyTheme.seed : FalimyTheme.muted,
                ),
              ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, color: FalimyTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
