import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/assets/presentation/screens/asset_detail_screen.dart';
import 'package:falimy/features/assets/presentation/widgets/asset_type_image.dart';

class VehicleInsuranceCards extends ConsumerWidget {
  const VehicleInsuranceCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(
      assetNotifierProvider.select((s) => s.vehiclesWithInsurance()),
    );
    if (vehicles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Vehicle insurance',
              style: TextStyle(
                color: FalimyTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = vehicles.length == 1
                  ? constraints.maxWidth - 40
                  : constraints.maxWidth * 0.78;
              return SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: _InsuranceCard(asset: vehicles[index]),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  const _InsuranceCard({required this.asset});

  final FamilyAsset asset;

  @override
  Widget build(BuildContext context) {
    final remaining = asset.insuranceRemaining!;
    final accent = remaining.expired
        ? const Color(0xFFC1121F)
        : remaining.urgent
            ? const Color(0xFFD97706)
            : FalimyTheme.seed;
    final radius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(assetId: asset.id),
            ),
          );
        },
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              AssetTypeIconBox(
                path: asset.typeImagePath,
                fallbackEmoji: asset.displayEmoji,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FalimyTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.typeLabel.isEmpty
                          ? asset.ownerName
                          : '${asset.typeLabel} · ${asset.ownerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FalimyTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: FalimyTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
