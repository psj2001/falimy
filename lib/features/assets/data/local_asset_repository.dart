import 'package:falimy/features/assets/data/asset_local_store.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/domain/repositories/asset_repository.dart';

class LocalAssetRepository implements AssetRepository {
  LocalAssetRepository({AssetLocalStore? store})
    : _store = store ?? AssetLocalStore();

  final AssetLocalStore _store;
  List<FamilyAsset> _cache = const [];

  @override
  Future<List<FamilyAsset>> load() async {
    _cache = await _store.load();
    return _cache;
  }

  @override
  Future<FamilyAsset> upsert(FamilyAsset asset) async {
    final index = _cache.indexWhere((a) => a.id == asset.id);
    if (index >= 0) {
      final next = [..._cache];
      next[index] = asset;
      _cache = next;
    } else {
      _cache = [..._cache, asset];
    }
    await _store.save(_cache);
    return asset;
  }

  @override
  Future<void> delete(String id) async {
    _cache = _cache.where((a) => a.id != id).toList();
    await _store.save(_cache);
  }
}
