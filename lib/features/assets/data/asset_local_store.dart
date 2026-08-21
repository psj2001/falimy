import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/assets/domain/entities/family_asset.dart';

class AssetLocalStore {
  AssetLocalStore({this.userId});

  static const _legacyKey = 'falimy_assets_v1';

  final String? userId;

  String get _key {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return _legacyKey;
    return '${_legacyKey}_$id';
  }

  Future<List<FamilyAsset>> load() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_key);
    if ((raw == null || raw.isEmpty) && _key != _legacyKey) {
      raw = prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        await prefs.setString(_key, raw);
      }
    }
    if (raw == null || raw.isEmpty) return const [];

    final json = jsonDecode(raw);
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => FamilyAsset.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> save(List<FamilyAsset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(assets.map((e) => e.toJson()).toList()),
    );
  }
}
