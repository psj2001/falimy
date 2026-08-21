import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/home/domain/family_search_result.dart';

class ApiFamilySearchRepository {
  ApiFamilySearchRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<FamilySearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final json = await _api.getJson(
      '/api/families/search?q=${Uri.encodeQueryComponent(trimmed)}',
    );
    final raw = json['families'];
    if (raw is! List) return const [];

    final families = <FamilySearchResult>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final family = FamilySearchResult.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (family.familyName.isEmpty || family.members.isEmpty) continue;
      families.add(family);
    }
    return families;
  }
}
