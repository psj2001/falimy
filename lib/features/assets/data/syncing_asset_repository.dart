import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/core/sync/sync_merge.dart';
import 'package:falimy/features/assets/data/local_asset_repository.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/domain/repositories/asset_repository.dart';

class SyncingAssetRepository implements AssetRepository {
  SyncingAssetRepository({
    required LocalAssetRepository local,
    required ApiClient apiClient,
  })  : _local = local,
        _api = apiClient;

  final LocalAssetRepository _local;
  final ApiClient _api;

  @override
  Future<List<FamilyAsset>> load() async {
    final local = await _local.load();
    try {
      final remote = await _fetchAll();
      final merged = mergeByUpdatedAt(
        local: local,
        remote: remote,
        idOf: (asset) => asset.id,
        updatedAtOf: (asset) => asset.updatedAt,
      );
      await _local.replaceAll(merged);

      final remoteById = {for (final asset in remote) asset.id: asset};
      for (final asset in merged) {
        final remoteAsset = remoteById[asset.id];
        if (remoteAsset == null || asset.updatedAt.isAfter(remoteAsset.updatedAt)) {
          await _push(asset);
        }
      }
      return merged;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<FamilyAsset> upsert(FamilyAsset asset) async {
    final saved = await _local.upsert(asset);
    try {
      await _push(saved);
    } catch (_) {}
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    try {
      await _api.delete('/api/assets/$id');
    } catch (_) {}
  }

  Future<List<FamilyAsset>> _fetchAll() async {
    final json = await _api.getJson('/api/assets');
    final raw = json['assets'];
    if (raw is! List) return const [];
    return raw
        .map(asJsonMap)
        .whereType<Map<String, dynamic>>()
        .map(FamilyAsset.fromJson)
        .toList();
  }

  Future<void> _push(FamilyAsset asset) async {
    await _api.putJson('/api/assets/${asset.id}', {'asset': asset.toJson()});
  }
}
