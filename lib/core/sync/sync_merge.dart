List<T> mergeByUpdatedAt<T>({
  required List<T> local,
  required List<T> remote,
  required String Function(T) idOf,
  required DateTime Function(T) updatedAtOf,
}) {
  final merged = <String, T>{};
  for (final item in remote) {
    merged[idOf(item)] = item;
  }
  for (final item in local) {
    final id = idOf(item);
    final existing = merged[id];
    if (existing == null || !updatedAtOf(item).isBefore(updatedAtOf(existing))) {
      merged[id] = item;
    }
  }
  return merged.values.toList();
}

Map<String, dynamic>? asJsonMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}
