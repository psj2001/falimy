import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/assets/presentation/screens/add_edit_asset_screen.dart';
import 'package:falimy/features/assets/presentation/screens/asset_detail_screen.dart';
import 'package:falimy/features/assets/presentation/widgets/asset_type_image.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';

class AssetCategoryListScreen extends ConsumerWidget {
  const AssetCategoryListScreen({
    super.key,
    required this.category,
    this.ownerId,
  });

  final AssetCategory category;
  final String? ownerId;

  Future<void> _openAdd(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditAssetScreen(
          initialCategory: category,
          initialOwnerId: ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      assetNotifierProvider.select(
        (s) => s.filtered(ownerId: ownerId, category: category),
      ),
    );
    final total = items.fold<double>(0, (sum, a) => sum + a.value);

    return Scaffold(
      backgroundColor: FalimyTheme.mistBlueSoft,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: FalimyTheme.ink,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: FalimyTheme.ink,
                    ),
                    Text(category.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.title,
                        style: const TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'} · ${BudgetFormat.money(total)}',
                  style: const TextStyle(
                    color: FalimyTheme.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No ${category.title.toLowerCase()} yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: FalimyTheme.muted,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final asset = items[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AssetDetailScreen(assetId: asset.id),
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
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AssetTypeIconBox(
                                      path: asset.typeImagePath,
                                      fallbackEmoji: asset.displayEmoji,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            asset.name,
                                            style: const TextStyle(
                                              color: FalimyTheme.ink,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            asset.listSubtitle,
                                            style: const TextStyle(
                                              color: FalimyTheme.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      BudgetFormat.money(asset.value),
                                      style: const TextStyle(
                                        color: FalimyTheme.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
