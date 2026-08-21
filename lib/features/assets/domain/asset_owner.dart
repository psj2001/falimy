import 'package:equatable/equatable.dart';

import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

class AssetOwnerOption extends Equatable {
  const AssetOwnerOption({
    required this.id,
    required this.name,
    required this.chipLabel,
  });

  final String id;
  final String name;
  final String chipLabel;

  @override
  List<Object?> get props => [id, name, chipLabel];
}

List<AssetOwnerOption> ownersFromProfile(FamilyProfile profile) {
  final owners = <AssetOwnerOption>[];
  final you = profile.fullName?.trim() ?? '';
  owners.add(
    AssetOwnerOption(
      id: 'self',
      name: you.isEmpty ? 'You' : you,
      chipLabel: 'You',
    ),
  );

  final dad = profile.fatherName?.trim() ?? '';
  if (dad.isNotEmpty) {
    owners.add(AssetOwnerOption(id: 'father', name: dad, chipLabel: 'Dad'));
  }

  final mom = profile.motherName?.trim() ?? '';
  if (mom.isNotEmpty) {
    owners.add(AssetOwnerOption(id: 'mother', name: mom, chipLabel: 'Mom'));
  }

  final spouseName = profile.spouse?.name.trim() ?? '';
  if (profile.isMarried == true && spouseName.isNotEmpty) {
    final role = profile.spouseSuggestionRole?.trim().toLowerCase();
    final chip = role == 'wife'
        ? 'Wife'
        : role == 'husband'
        ? 'Husband'
        : 'Spouse';
    owners.add(
      AssetOwnerOption(id: 'spouse', name: spouseName, chipLabel: chip),
    );
  }

  for (var i = 0; i < profile.siblings.length; i++) {
    final sibling = profile.siblings[i];
    final name = sibling.name.trim();
    if (name.isEmpty) continue;
    owners.add(
      AssetOwnerOption(
        id: 'sibling_$i',
        name: name,
        chipLabel: name.split(' ').first,
      ),
    );
  }

  for (var i = 0; i < profile.children.length; i++) {
    final child = profile.children[i];
    final name = child.name.trim();
    if (name.isEmpty) continue;
    owners.add(
      AssetOwnerOption(
        id: 'child_$i',
        name: name,
        chipLabel: name.split(' ').first,
      ),
    );
  }

  return owners;
}
