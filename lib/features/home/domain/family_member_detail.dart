enum FamilyMemberKind {
  self,
  father,
  mother,
  sibling,
  spouse,
  child,
}

/// Snapshot shown on the member detail screen when a tree card is tapped.
class FamilyMemberDetail {
  const FamilyMemberDetail({
    required this.memberKey,
    required this.name,
    required this.role,
    required this.kind,
    this.photoPath,
    this.familyName,
    this.dateOfBirth,
    this.profession,
    this.age,
    this.genderLabel,
  });

  /// Stable slot id within the inviter's tree (e.g. father, sibling_0).
  final String memberKey;
  final String name;
  final String role;
  final FamilyMemberKind kind;
  final String? photoPath;
  final String? familyName;
  final DateTime? dateOfBirth;
  final String? profession;
  final int? age;
  final String? genderLabel;

  bool get canInvite => kind != FamilyMemberKind.self;
}
