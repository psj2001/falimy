import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/features/financial/domain/entities/cash_book.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key, this.initialName});

  final String? initialName;

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  static const _suggestions = [
    'August Expenses',
    'New Project',
    'Client Record',
    'Personal',
  ];

  late final TextEditingController _nameController;
  BookAccess _access = BookAccess.justMe;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final book = await ref.read(financialNotifierProvider.notifier).createBook(
          name: _nameController.text,
          access: _access,
        );
    if (book != null && mounted) {
      Navigator.of(context).pop(book);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(financialNotifierProvider).isSaving;
    final canCreate = _nameController.text.trim().isNotEmpty && !isSaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add new book'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  AppTextField(
                    label: 'Enter Book Name',
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(s),
                                backgroundColor:
                                    FalimyTheme.seed.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: FalimyTheme.seed,
                                  fontWeight: FontWeight.w600,
                                ),
                                onPressed: () {
                                  _nameController.text = s;
                                  _nameController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(offset: s.length),
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Who can access this book?',
                    style: TextStyle(
                      color: FalimyTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AccessCard(
                          icon: Icons.person_outline,
                          label: 'Just me',
                          selected: _access == BookAccess.justMe,
                          onTap: () =>
                              setState(() => _access = BookAccess.justMe),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccessCard(
                          icon: Icons.groups_outlined,
                          label: 'With team/family',
                          selected: _access == BookAccess.team,
                          onTap: () =>
                              setState(() => _access = BookAccess.team),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF5E35B1)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Members added to this book will get access.',
                            style: TextStyle(
                              color: FalimyTheme.ink,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: 'Create Book',
                isLoading: isSaving,
                onPressed: canCreate ? _create : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? FalimyTheme.seed.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? FalimyTheme.seed
                : FalimyTheme.muted.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: FalimyTheme.seed),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: FalimyTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
