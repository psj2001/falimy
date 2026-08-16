import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/invites/domain/family_invite.dart';
import 'package:falimy/features/invites/domain/invite_repository.dart';

class ApiInviteRepository implements InviteRepository {
  ApiInviteRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  Future<InviteSendResult> sendInvite({
    required String inviteeEmail,
    required String memberKey,
    required String memberName,
    required String memberKind,
    required String memberRole,
    String? familyName,
  }) async {
    final json = await _api.postJson('/api/invites', {
      'inviteeEmail': _normalizeEmail(inviteeEmail),
      'memberKey': memberKey,
      'memberName': memberName,
      'memberKind': memberKind,
      'memberRole': memberRole,
      'familyName': familyName,
    });

    final invite = json['invite'];
    final inviteMap =
        invite is Map ? Map<String, dynamic>.from(invite) : <String, dynamic>{};

    return InviteSendResult(
      inviteeEmail: _normalizeEmail(inviteeEmail),
      emailDelivered: json['emailDelivered'] == true,
      memberName: (inviteMap['memberName'] as String?) ?? memberName,
      memberRole: (inviteMap['memberRole'] as String?) ?? memberRole,
      inviterName: (inviteMap['inviterName'] as String?) ?? 'A family member',
    );
  }

  @override
  Future<List<FamilyInvite>> findPendingByEmail(String email) async {
    // Claiming is handled during sign-in / sign-up on the server.
    return const [];
  }

  @override
  Future<List<FamilyInvite>> claimInvitesForUser({
    required String userId,
    required String email,
  }) async {
    // Server claims invites automatically on auth; nothing to do client-side.
    return const [];
  }
}
