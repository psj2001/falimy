import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/financial/data/api_financial_cloud_repository.dart';
import 'package:falimy/features/financial/data/local_financial_repository.dart';
import 'package:falimy/features/financial/domain/repositories/financial_repository.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return LocalFinancialRepository();
});

final financialCloudRepositoryProvider =
    Provider<ApiFinancialCloudRepository>((ref) {
  return ApiFinancialCloudRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});
