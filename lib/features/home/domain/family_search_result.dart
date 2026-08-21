import 'package:equatable/equatable.dart';

import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

class FamilySearchMember extends Equatable {
  const FamilySearchMember({
    required this.name,
    required this.role,
    this.photoPath,
  });

  final String name;
  final String role;
  final String? photoPath;

  factory FamilySearchMember.fromJson(Map<String, dynamic> json) {
    return FamilySearchMember(
      name: (json['name'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim() ?? 'Member',
      photoPath: (json['photoPath'] as String?)?.trim(),
    );
  }

  @override
  List<Object?> get props => [name, role, photoPath];
}

class FamilySearchResult extends Equatable {
  const FamilySearchResult({
    required this.familyName,
    required this.members,
  });

  final String familyName;
  final List<FamilySearchMember> members;

  int get personCount => members.length;

  factory FamilySearchResult.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = <FamilySearchMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is! Map) continue;
        final member = FamilySearchMember.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (member.name.isEmpty) continue;
        members.add(member);
      }
    }
    return FamilySearchResult(
      familyName: (json['familyName'] as String?)?.trim() ?? '',
      members: members,
    );
  }

  factory FamilySearchResult.fromProfile(FamilyProfile profile) {
    final familyName = profile.familyName?.trim() ?? '';
    final members = <FamilySearchMember>[];
    final seen = <String>{};

    void add(String? name, String role, String? photoPath) {
      final clean = name?.trim() ?? '';
      if (clean.isEmpty) return;
      final key = clean.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      members.add(
        FamilySearchMember(name: clean, role: role, photoPath: photoPath),
      );
    }

    add(profile.fullName, 'You', profile.photoPath);
    add(
      profile.fatherName,
      'Father',
      profile.memberLinks['father']?.photoPath,
    );
    add(
      profile.motherName,
      'Mother',
      profile.memberLinks['mother']?.photoPath,
    );

    for (var i = 0; i < profile.siblings.length; i++) {
      final sibling = profile.siblings[i];
      final isElder = sibling.seniority == SiblingSeniority.elder;
      final role = sibling.gender == SiblingGender.male
          ? (isElder ? 'Elder brother' : 'Younger brother')
          : (isElder ? 'Elder sister' : 'Younger sister');
      add(sibling.name, role, profile.memberLinks['sibling_$i']?.photoPath);
    }

    if (profile.isMarried == true && profile.spouse != null) {
      final suggestion = profile.spouseSuggestionRole?.trim().toLowerCase();
      final role = suggestion == 'wife'
          ? 'Wife'
          : suggestion == 'husband'
          ? 'Husband'
          : 'Spouse';
      add(
        profile.spouse!.name,
        role,
        profile.memberLinks['spouse']?.photoPath,
      );
    }

    for (var i = 0; i < profile.children.length; i++) {
      add(
        profile.children[i].name,
        'Child',
        profile.memberLinks['child_$i']?.photoPath,
      );
    }

    return FamilySearchResult(familyName: familyName, members: members);
  }

  FamilySearchResult merge(FamilySearchResult other) {
    final byName = <String, FamilySearchMember>{
      for (final member in members) member.name.toLowerCase(): member,
    };
    for (final member in other.members) {
      final key = member.name.toLowerCase();
      final existing = byName[key];
      if (existing == null) {
        byName[key] = member;
        continue;
      }
      if ((existing.photoPath == null || existing.photoPath!.isEmpty) &&
          member.photoPath != null &&
          member.photoPath!.isNotEmpty) {
        byName[key] = FamilySearchMember(
          name: existing.name,
          role: existing.role,
          photoPath: member.photoPath,
        );
      }
    }
    return FamilySearchResult(
      familyName: familyName.isNotEmpty ? familyName : other.familyName,
      members: byName.values.toList(),
    );
  }

  @override
  List<Object?> get props => [familyName, members];
}
