import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/assets/data/asset_local_store.dart';
import 'package:falimy/features/assets/data/local_asset_repository.dart';
import 'package:falimy/features/assets/data/syncing_asset_repository.dart';
import 'package:falimy/features/assets/domain/repositories/asset_repository.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
  return SyncingAssetRepository(
    local: LocalAssetRepository(
      store: AssetLocalStore(userId: userId),
    ),
    apiClient: ref.watch(apiClientProvider),
  );
});
