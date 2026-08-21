import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/financial/data/api_financial_cloud_repository.dart';
import 'package:falimy/features/financial/data/financial_local_store.dart';
import 'package:falimy/features/financial/data/local_financial_repository.dart';
import 'package:falimy/features/financial/data/syncing_financial_repository.dart';
import 'package:falimy/features/financial/domain/repositories/financial_repository.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
  return SyncingFinancialRepository(
    local: LocalFinancialRepository(
      store: FinancialLocalStore(userId: userId),
    ),
    cloud: ref.watch(financialCloudRepositoryProvider),
  );
});

final financialCloudRepositoryProvider =
    Provider<ApiFinancialCloudRepository>((ref) {
  return ApiFinancialCloudRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});
