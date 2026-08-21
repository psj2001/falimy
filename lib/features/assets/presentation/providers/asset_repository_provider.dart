import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/assets/data/local_asset_repository.dart';
import 'package:falimy/features/assets/domain/repositories/asset_repository.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return LocalAssetRepository();
});
