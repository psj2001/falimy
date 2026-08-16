import 'package:equatable/equatable.dart';

enum SiblingGender { male, female }

enum SiblingSeniority { elder, younger }

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
      ];
}
