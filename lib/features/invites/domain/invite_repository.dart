import 'package:falimy/features/invites/domain/family_invite.dart';

class InviteSendResult {
  const InviteSendResult({
    required this.inviteeEmail,
    required this.emailDelivered,
    required this.memberName,
    required this.memberRole,
    required this.inviterName,
  });

  final String inviteeEmail;
  final bool emailDelivered;
  final String memberName;
  final String memberRole;
  final String inviterName;
}

abstract class InviteRepository {
  Future<InviteSendResult> sendInvite({
    required String inviteeEmail,
    required String memberKey,
    required String memberName,
    required String memberKind,
    required String memberRole,
    String? familyName,
  });

  /// Pending invites addressed to [email], if any.
  Future<List<FamilyInvite>> findPendingByEmail(String email);

  /// Marks matching pending invites as accepted by [userId].
  Future<List<FamilyInvite>> claimInvitesForUser({
    required String userId,
    required String email,
  });
}
