import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:falimy/features/assets/domain/entities/family_asset.dart';

class AssetLocalStore {
  static const _key = 'falimy_assets_v1';

  Future<List<FamilyAsset>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
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
