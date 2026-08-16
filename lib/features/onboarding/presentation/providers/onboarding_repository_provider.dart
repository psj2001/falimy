import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/onboarding/data/api_onboarding_repository.dart';
import 'package:falimy/features/onboarding/domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return ApiOnboardingRepository(apiClient: ref.watch(apiClientProvider));
});
