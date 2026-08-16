import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';

enum BookAction { rename, duplicate, addMembers, move, delete }

class BookActionsSheet extends StatelessWidget {
  const BookActionsSheet({
    super.key,
    required this.book,
  });

  final CashBook book;

  static Future<BookAction?> show(BuildContext context, CashBook book) {
    return showModalBottomSheet<BookAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BookActionsSheet(book: book),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: FalimyTheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              book.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: FalimyTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            _item(
              context,
              icon: Icons.edit_outlined,
              label: 'Rename',
              action: BookAction.rename,
            ),
            _item(
              context,
              icon: Icons.copy_outlined,
              label: 'Duplicate Book',
              action: BookAction.duplicate,
            ),
            _item(
              context,
              icon: Icons.person_add_alt_1_outlined,
              label: 'Add members',
              action: BookAction.addMembers,
            ),
            _item(
              context,
              icon: Icons.drive_file_move_outline,
              label: 'Move book',
              action: BookAction.move,
            ),
            _item(
              context,
              icon: Icons.delete_outline,
              label: 'Delete Book',
              action: BookAction.delete,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required BookAction action,
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFC1121F) : FalimyTheme.ink;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: () => Navigator.pop(context, action),
    );
  }
}
