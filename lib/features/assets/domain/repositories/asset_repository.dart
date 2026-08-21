import 'package:falimy/features/assets/domain/entities/family_asset.dart';

abstract class AssetRepository {
  Future<List<FamilyAsset>> load();

  Future<FamilyAsset> upsert(FamilyAsset asset);

  Future<void> delete(String id);
}
