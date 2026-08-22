import 'package:equatable/equatable.dart';

import 'package:falimy/core/currency/app_currency.dart';

enum SiblingGender { male, female }

enum SiblingSeniority { elder, younger }

enum OccupationStatus { working, studying, unemployed, retired }

class Sibling extends Equatable {
  const Sibling({
    required this.name,
    required this.gender,
    required this.seniority,
  });

  final String name;
  final SiblingGender gender;
  final SiblingSeniority seniority;

  Sibling copyWith({
    String? name,
    SiblingGender? gender,
    SiblingSeniority? seniority,
  }) {
    return Sibling(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      seniority: seniority ?? this.seniority,
    );
  }

  @override
  List<Object?> get props => [name, gender, seniority];
}

class Spouse extends Equatable {
  const Spouse({
    required this.name,
    required this.profession,
    required this.age,
    required this.familyName,
  });

  final String name;
  final String profession;
  final int age;
  final String familyName;

  Spouse copyWith({
    String? name,
    String? profession,
    int? age,
    String? familyName,
  }) {
    return Spouse(
      name: name ?? this.name,
      profession: profession ?? this.profession,
      age: age ?? this.age,
      familyName: familyName ?? this.familyName,
    );
  }

  @override
  List<Object?> get props => [name, profession, age, familyName];
}

class Child extends Equatable {
  const Child({
    required this.name,
    required this.age,
  });

  final String name;
  final int age;

  Child copyWith({String? name, int? age}) {
    return Child(name: name ?? this.name, age: age ?? this.age);
  }

  @override
  List<Object?> get props => [name, age];
}

class LinkedFamilyMember extends Equatable {
  const LinkedFamilyMember({
    required this.userId,
    required this.name,
    required this.kind,
    required this.role,
    this.email,
    this.photoPath,
  });

  final String userId;
  final String name;
  final String kind;
  final String role;
  final String? email;
  final String? photoPath;

  @override
  List<Object?> get props => [userId, name, kind, role, email, photoPath];
}

class FamilyProfile extends Equatable {
  const FamilyProfile({
    this.fullName,
    this.dateOfBirth,
    this.familyName,
    this.photoPath,
    this.fatherName,
    this.motherName,
    this.siblings = const [],
    this.isMarried,
    this.spouse,
    this.hasChildren,
    this.children = const [],
    this.onboardingComplete = false,
    this.occupationStatus,
    this.companyName,
    this.salary,
    this.studyClassOrCourse,
    this.currency = AppCurrency.defaultCode,
    this.linkedInviterName,
    this.linkedMemberKind,
    this.linkedMemberRole,
    this.spouseSuggestionRole,
    this.memberLinks = const {},
  });

  final String? fullName;
  final DateTime? dateOfBirth;
  final String? familyName;
  final String? photoPath;
  final String? fatherName;
  final String? motherName;
  final List<Sibling> siblings;
  final bool? isMarried;
  final Spouse? spouse;
  final bool? hasChildren;
  final List<Child> children;
  final bool onboardingComplete;
  final OccupationStatus? occupationStatus;
  final String? companyName;
  final num? salary;
  final String? studyClassOrCourse;
  final String currency;
  final String? linkedInviterName;
  final String? linkedMemberKind;
  final String? linkedMemberRole;
  final String? spouseSuggestionRole;
  final Map<String, LinkedFamilyMember> memberLinks;

  bool get hasInviteSpouseSuggestion {
    final name = spouse?.name.trim() ?? '';
    if (name.isEmpty) return false;
    if ((spouseSuggestionRole?.trim().isNotEmpty ?? false)) return true;
    final kind = linkedMemberKind?.trim().toLowerCase();
    return kind == 'father' || kind == 'mother';
  }

  bool get hasInviteChildrenSuggestion {
    final kind = linkedMemberKind?.trim().toLowerCase();
    return children.isNotEmpty && (kind == 'father' || kind == 'mother');
  }

  /// Cloud photo for a tree slot. Falls back to any linked account with the
  /// same name so a sibling/parent still shows after the invite keys shift.
  String? photoForMember(String memberKey, {String? name}) {
    final fromKey = _usablePhoto(memberLinks[memberKey]?.photoPath);
    if (fromKey != null) return fromKey;
    final needle = name?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return null;
    for (final link in memberLinks.values) {
      if (link.name.trim().toLowerCase() != needle) continue;
      final photo = _usablePhoto(link.photoPath);
      if (photo != null) return photo;
    }
    return null;
  }

  static String? _usablePhoto(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return null;
  }

  FamilyProfile copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? familyName,
    String? photoPath,
    bool clearPhoto = false,
    String? fatherName,
    String? motherName,
    List<Sibling>? siblings,
    bool? isMarried,
    Spouse? spouse,
    bool clearSpouse = false,
    bool? hasChildren,
    List<Child>? children,
    bool? onboardingComplete,
    OccupationStatus? occupationStatus,
    bool clearOccupationStatus = false,
    String? companyName,
    bool clearCompanyName = false,
    num? salary,
    bool clearSalary = false,
    String? studyClassOrCourse,
    bool clearStudyClassOrCourse = false,
    String? currency,
    String? linkedInviterName,
    String? linkedMemberKind,
    String? linkedMemberRole,
    String? spouseSuggestionRole,
    Map<String, LinkedFamilyMember>? memberLinks,
  }) {
    return FamilyProfile(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      familyName: familyName ?? this.familyName,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      siblings: siblings ?? this.siblings,
      isMarried: isMarried ?? this.isMarried,
      spouse: clearSpouse ? null : (spouse ?? this.spouse),
      hasChildren: hasChildren ?? this.hasChildren,
      children: children ?? this.children,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      occupationStatus: clearOccupationStatus
          ? null
          : (occupationStatus ?? this.occupationStatus),
      companyName:
          clearCompanyName ? null : (companyName ?? this.companyName),
      salary: clearSalary ? null : (salary ?? this.salary),
      studyClassOrCourse: clearStudyClassOrCourse
          ? null
          : (studyClassOrCourse ?? this.studyClassOrCourse),
      currency: currency ?? this.currency,
      linkedInviterName: linkedInviterName ?? this.linkedInviterName,
      linkedMemberKind: linkedMemberKind ?? this.linkedMemberKind,
      linkedMemberRole: linkedMemberRole ?? this.linkedMemberRole,
      spouseSuggestionRole: spouseSuggestionRole ?? this.spouseSuggestionRole,
      memberLinks: memberLinks ?? this.memberLinks,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        dateOfBirth,
        familyName,
        photoPath,
        fatherName,
        motherName,
        siblings,
        isMarried,
        spouse,
        hasChildren,
        children,
        onboardingComplete,
        occupationStatus,
        companyName,
        salary,
        studyClassOrCourse,
        currency,
        linkedInviterName,
        linkedMemberKind,
        linkedMemberRole,
        spouseSuggestionRole,
        memberLinks,
      ];
}
