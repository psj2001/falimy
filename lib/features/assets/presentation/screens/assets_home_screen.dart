import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/domain/asset_owner.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/assets/presentation/screens/add_edit_asset_screen.dart';
import 'package:falimy/features/assets/presentation/screens/asset_category_list_screen.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class AssetsHomeScreen extends ConsumerStatefulWidget {
  const AssetsHomeScreen({super.key});

  @override
  ConsumerState<AssetsHomeScreen> createState() => _AssetsHomeScreenState();
}

class _AssetsHomeScreenState extends ConsumerState<AssetsHomeScreen> {
  String? _ownerFilter;

  Future<void> _openAdd({AssetCategory? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditAssetScreen(
          initialCategory: category,
          initialOwnerId: _ownerFilter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingNotifierProvider);
    final assetState = ref.watch(assetNotifierProvider);
    final owners = ownersFromProfile(profile);
    final total = assetState.totalValue(ownerId: _ownerFilter);
    final count = assetState.count(ownerId: _ownerFilter);

    return Scaffold(
      backgroundColor: FalimyTheme.mistBlueSoft,
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () => _openAdd(),
          backgroundColor: FalimyTheme.ink,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
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
                    const Expanded(
                      child: Text(
                        'Family assets',
                        style: TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (owners.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: owners.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _MemberChip(
                          label: 'All',
                          selected: _ownerFilter == null,
                          onTap: () => setState(() => _ownerFilter = null),
                        );
                      }
                      final owner = owners[index - 1];
                      return _MemberChip(
                        label: owner.chipLabel,
                        selected: _ownerFilter == owner.id,
                        onTap: () => setState(() => _ownerFilter = owner.id),
                      );
                    },
                  ),
                ),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(assetNotifierProvider.notifier).load(),
                  color: FalimyTheme.seed,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      _WealthCard(
                        isLoading: assetState.isLoading,
                        total: total,
                        itemCount: count,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 148,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AssetCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = AssetCategory.values[index];
                            return _CategoryTile(
                              category: category,
                              count: assetState.count(
                                ownerId: _ownerFilter,
                                category: category,
                              ),
                              value: assetState.totalValue(
                                ownerId: _ownerFilter,
                                category: category,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AssetCategoryListScreen(
                                      category: category,
                                      ownerId: _ownerFilter,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

class _WealthCard extends StatelessWidget {
  const _WealthCard({
    required this.isLoading,
    required this.total,
    required this.itemCount,
  });

  final bool isLoading;
  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: FalimyTheme.seed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: FalimyTheme.seed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Total Family Wealth',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Text(
              BudgetFormat.money(total),
              style: const TextStyle(
                color: FalimyTheme.ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              itemCount == 0
                  ? 'No assets yet — tap + to add one'
                  : '$itemCount ${itemCount == 1 ? 'item' : 'items'} across the family',
              style: const TextStyle(
                color: FalimyTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.value,
    required this.onTap,
  });

  final AssetCategory category;
  final int count;
  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 132,
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
              Text(category.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                category.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FalimyTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  '$count ${count == 1 ? 'item' : 'items'} · ${BudgetFormat.money(value)}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FalimyTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? FalimyTheme.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? FalimyTheme.ink : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : FalimyTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
