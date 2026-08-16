import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/invites/data/api_invite_repository.dart';
import 'package:falimy/features/invites/domain/invite_repository.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return ApiInviteRepository(apiClient: ref.watch(apiClientProvider));
});
