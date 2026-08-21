import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/presentation/providers/asset_repository_provider.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';

class AssetState extends Equatable {
  const AssetState({
    this.assets = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  final List<FamilyAsset> assets;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  List<FamilyAsset> filtered({String? ownerId, AssetCategory? category}) {
    return assets.where((asset) {
      if (ownerId != null && asset.ownerId != ownerId) return false;
      if (category != null && asset.category != category) return false;
      return true;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  double totalValue({String? ownerId, AssetCategory? category}) {
    var total = 0.0;
    for (final asset in filtered(ownerId: ownerId, category: category)) {
      total += asset.value;
    }
    return total;
  }

  int count({String? ownerId, AssetCategory? category}) {
    return filtered(ownerId: ownerId, category: category).length;
  }

  FamilyAsset? byId(String id) {
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  List<FamilyAsset> vehiclesWithInsurance() {
    final list = assets
        .where(
          (asset) =>
              asset.category == AssetCategory.vehicles && asset.hasInsurance,
        )
        .toList();
    list.sort((a, b) {
      final aEnd = a.insuranceEnd ?? DateTime(2100);
      final bEnd = b.insuranceEnd ?? DateTime(2100);
      return aEnd.compareTo(bEnd);
    });
    return list;
  }

  AssetState copyWith({
    List<FamilyAsset>? assets,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return AssetState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [assets, isLoading, isSaving, error];
}

class AssetNotifier extends Notifier<AssetState> {
  @override
  AssetState build() {
    ref.listen(authNotifierProvider.select((s) => s.user?.id), (previous, next) {
      if (previous != next) Future.microtask(load);
    });
    Future.microtask(load);
    return const AssetState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final assets = await ref.read(assetRepositoryProvider).load();
      state = state.copyWith(assets: assets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<FamilyAsset?> upsert(FamilyAsset asset) async {
    if (asset.name.trim().isEmpty) {
      state = state.copyWith(error: 'Name is required');
      return null;
    }
    if (asset.value < 0) {
      state = state.copyWith(error: 'Value cannot be negative');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await ref.read(assetRepositoryProvider).upsert(asset);
      final index = state.assets.indexWhere((a) => a.id == saved.id);
      final next = [...state.assets];
      if (index >= 0) {
        next[index] = saved;
      } else {
        next.add(saved);
      }
      state = state.copyWith(assets: next, isSaving: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(assetRepositoryProvider).delete(id);
      state = state.copyWith(
        assets: state.assets.where((a) => a.id != id).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final assetNotifierProvider = NotifierProvider<AssetNotifier, AssetState>(
  AssetNotifier.new,
);

String newAssetId() => 'asset_${DateTime.now().microsecondsSinceEpoch}';
