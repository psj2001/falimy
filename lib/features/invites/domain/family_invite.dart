enum InviteStatus { pending, accepted, cancelled }

class FamilyInvite {
  const FamilyInvite({
    required this.id,
    required this.inviteeEmail,
    required this.inviterUserId,
    required this.inviterName,
    required this.memberKey,
    required this.memberName,
    required this.memberKind,
    required this.memberRole,
    this.familyName,
    this.status = InviteStatus.pending,
    this.acceptedUserId,
    this.createdAt,
  });

  final String id;
  final String inviteeEmail;
  final String inviterUserId;
  final String inviterName;
  final String memberKey;
  final String memberName;
  final String memberKind;
  final String memberRole;
  final String? familyName;
  final InviteStatus status;
  final String? acceptedUserId;
  final DateTime? createdAt;
}
