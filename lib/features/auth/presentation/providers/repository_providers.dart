import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/auth/data/api_auth_repository.dart';
import 'package:falimy/features/auth/domain/repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(apiClient: ref.watch(apiClientProvider));
});

final apiAuthRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  return ref.watch(authRepositoryProvider) as ApiAuthRepository;
});
