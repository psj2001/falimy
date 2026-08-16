import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/financial/presentation/providers/financial_notifier.dart';

class ChooseCategoryScreen extends ConsumerStatefulWidget {
  const ChooseCategoryScreen({
    super.key,
    required this.bookId,
    this.selectedCategoryId,
  });

  final String bookId;
  final String? selectedCategoryId;

  @override
  ConsumerState<ChooseCategoryScreen> createState() =>
      _ChooseCategoryScreenState();
}

class _ChooseCategoryScreenState extends ConsumerState<ChooseCategoryScreen> {
  late String? _selectedId = widget.selectedCategoryId;
  String _query = '';

  Future<void> _addNew() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final category = await ref
        .read(financialNotifierProvider.notifier)
        .addCategory(bookId: widget.bookId, name: name);
    if (category != null && mounted) {
      setState(() => _selectedId = category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref
        .watch(financialNotifierProvider)
        .categoriesFor(widget.bookId)
        .where((c) =>
            _query.isEmpty ||
            c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Choose Category'),
        actions: [
          IconButton(
            onPressed: () async {
              final controller = TextEditingController(text: _query);
              final value = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Search'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (value != null) setState(() => _query = value.trim());
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNew,
        backgroundColor: FalimyTheme.seed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add new'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const Text(
            'Categories in this book',
            style: TextStyle(
              color: FalimyTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _CategoryTile(
            label: 'No Category',
            selected: _selectedId == null,
            onTap: () => Navigator.pop(context, null),
          ),
          ...categories.map(
            (c) => _CategoryTile(
              label: c.name,
              selected: _selectedId == c.id,
              onTap: () => Navigator.pop(context, c),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? FalimyTheme.seed.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? FalimyTheme.seed
                  : FalimyTheme.muted.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? FalimyTheme.seed : FalimyTheme.muted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FalimyTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
