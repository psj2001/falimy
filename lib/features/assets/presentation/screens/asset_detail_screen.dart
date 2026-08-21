import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/assets/presentation/screens/add_edit_asset_screen.dart';
import 'package:falimy/features/assets/presentation/widgets/asset_type_image.dart';
import 'package:falimy/features/budget/presentation/widgets/budget_format.dart';

class AssetDetailScreen extends ConsumerWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  Future<void> _edit(BuildContext context, FamilyAsset asset) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditAssetScreen(existing: asset)),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FamilyAsset asset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete asset?'),
        content: Text('${asset.name} will be removed from family wealth.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC1121F)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(assetNotifierProvider.notifier).delete(asset.id);
    if (!context.mounted) return;
    if (!ok) {
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message: ref.read(assetNotifierProvider).error ?? 'Could not delete.',
      );
      return;
    }
    await showResultDialog(
      context,
      kind: ResultDialogKind.success,
      message: 'Asset deleted.',
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(
      assetNotifierProvider.select((s) => s.byId(assetId)),
    );

    if (asset == null) {
      return Scaffold(
        backgroundColor: FalimyTheme.mistBlueSoft,
        appBar: AppBar(title: const Text('Asset')),
        body: const Center(child: Text('This asset is no longer available.')),
      );
    }

    final rows = <_DetailRow>[
      _DetailRow('Category', asset.category.title),
      _DetailRow('Owner', asset.ownerName),
      _DetailRow('Current value', BudgetFormat.money(asset.value)),
      for (final field in asset.category.extraFields)
        if ((asset.fields[field.key] ?? '').isNotEmpty)
          _DetailRow(
            field.label,
            field.suffix == null
                ? asset.fields[field.key]!
                : '${asset.fields[field.key]} ${field.suffix}',
          ),
      if ((asset.notes ?? '').isNotEmpty) _DetailRow('Notes', asset.notes!),
      _DetailRow('Updated', DateFormat('d MMM yyyy').format(asset.updatedAt)),
    ];

    return Scaffold(
      backgroundColor: FalimyTheme.mistBlueSoft,
      body: Container(
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: FalimyTheme.ink,
                    ),
                    Expanded(
                      child: Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _edit(context, asset),
                      icon: const Icon(Icons.edit_outlined),
                      color: FalimyTheme.ink,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          AssetTypeImage(
                            path: asset.typeImagePath,
                            fallbackEmoji: asset.displayEmoji,
                            size: 72,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            BudgetFormat.money(asset.value),
                            style: const TextStyle(
                              color: FalimyTheme.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            asset.typeLabel.isEmpty
                                ? '${asset.category.title} · ${asset.ownerName}'
                                : '${asset.typeLabel} · ${asset.ownerName}',
                            style: const TextStyle(
                              color: FalimyTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (asset.insuranceRemaining != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Insurance · ${asset.insuranceRemaining!.label}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: asset.insuranceRemaining!.expired
                                    ? const Color(0xFFC1121F)
                                    : asset.insuranceRemaining!.urgent
                                    ? const Color(0xFFD97706)
                                    : FalimyTheme.seed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            _InfoLine(
                              label: rows[i].label,
                              value: rows[i].value,
                            ),
                            if (i != rows.length - 1)
                              Divider(
                                height: 1,
                                color: FalimyTheme.muted.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Edit asset',
                      onPressed: () => _edit(context, asset),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _delete(context, ref, asset),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFC1121F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: FalimyTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: FalimyTheme.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
