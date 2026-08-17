import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/home/domain/family_member_detail.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

class FamilyOrgChart extends StatelessWidget {
  const FamilyOrgChart({super.key, required this.profile});

  final FamilyProfile profile;

  void _openMember(BuildContext context, FamilyMemberDetail member) {
    context.push(AppRoutes.memberDetail, extra: member);
  }

  @override
  Widget build(BuildContext context) {
    final fatherLink = profile.memberLinks['father'];
    final motherLink = profile.memberLinks['mother'];
    final spouseLink = profile.memberLinks['spouse'];
    final elders = profile.siblings
        .where((s) => s.seniority == SiblingSeniority.elder)
        .toList();
    final youngers = profile.siblings
        .where((s) => s.seniority == SiblingSeniority.younger)
        .toList();

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(120),
      minScale: 0.55,
      maxScale: 2.2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Parents
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Node(
                    name: profile.fatherName ?? 'Father',
                    role: 'Father',
                    photoPath: fatherLink?.photoPath,
                    muted: profile.fatherName == null,
                    onTap: profile.fatherName == null
                        ? null
                        : () => _openMember(
                              context,
                              FamilyMemberDetail(
                                memberKey: 'father',
                                name: profile.fatherName!,
                                role: 'Father',
                                kind: FamilyMemberKind.father,
                                familyName: profile.familyName,
                                photoPath: fatherLink?.photoPath,
                                linkedUserId: fatherLink?.userId,
                                isLinked: fatherLink != null,
                              ),
                            ),
                  ),
                  const SizedBox(width: 24),
                  _Node(
                    name: profile.motherName ?? 'Mother',
                    role: 'Mother',
                    photoPath: motherLink?.photoPath,
                    muted: profile.motherName == null,
                    onTap: profile.motherName == null
                        ? null
                        : () => _openMember(
                              context,
                              FamilyMemberDetail(
                                memberKey: 'mother',
                                name: profile.motherName!,
                                role: 'Mother',
                                kind: FamilyMemberKind.mother,
                                familyName: profile.familyName,
                                photoPath: motherLink?.photoPath,
                                linkedUserId: motherLink?.userId,
                                isLinked: motherLink != null,
                              ),
                            ),
                  ),
                ],
              ),
              const _Connector(),
              // Self + siblings
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...elders.map(
                    (s) {
                      final index = profile.siblings.indexOf(s);
                      final link = profile.memberLinks['sibling_$index'];
                      final role = s.gender == SiblingGender.male
                          ? 'Elder brother'
                          : 'Elder sister';
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _Node(
                          name: s.name,
                          role: role,
                          photoPath: link?.photoPath,
                          onTap: () => _openMember(
                            context,
                            FamilyMemberDetail(
                              memberKey: 'sibling_$index',
                              name: s.name,
                              role: role,
                              kind: FamilyMemberKind.sibling,
                              genderLabel: s.gender == SiblingGender.male
                                  ? 'Male'
                                  : 'Female',
                              photoPath: link?.photoPath,
                              linkedUserId: link?.userId,
                              isLinked: link != null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  _Node(
                    name: profile.fullName ?? 'You',
                    role: 'You',
                    highlight: true,
                    photoHint: profile.photoPath != null,
                    photoPath: profile.photoPath,
                    onTap: () => _openMember(
                      context,
                      FamilyMemberDetail(
                        memberKey: 'self',
                        name: profile.fullName ?? 'You',
                        role: 'You',
                        kind: FamilyMemberKind.self,
                        photoPath: profile.photoPath,
                        familyName: profile.familyName,
                        dateOfBirth: profile.dateOfBirth,
                      ),
                    ),
                  ),
                  ...youngers.map(
                    (s) {
                      final index = profile.siblings.indexOf(s);
                      final link = profile.memberLinks['sibling_$index'];
                      final role = s.gender == SiblingGender.male
                          ? 'Younger brother'
                          : 'Younger sister';
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _Node(
                          name: s.name,
                          role: role,
                          photoPath: link?.photoPath,
                          onTap: () => _openMember(
                            context,
                            FamilyMemberDetail(
                              memberKey: 'sibling_$index',
                              name: s.name,
                              role: role,
                              kind: FamilyMemberKind.sibling,
                              genderLabel: s.gender == SiblingGender.male
                                  ? 'Male'
                                  : 'Female',
                              photoPath: link?.photoPath,
                              linkedUserId: link?.userId,
                              isLinked: link != null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (profile.isMarried == true && profile.spouse != null) ...[
                const _Connector(),
                _Node(
                  name: profile.spouse!.name,
                  role: 'Spouse · ${profile.spouse!.profession}',
                  photoPath: spouseLink?.photoPath,
                  onTap: () => _openMember(
                    context,
                    FamilyMemberDetail(
                      memberKey: 'spouse',
                      name: profile.spouse!.name,
                      role: 'Spouse',
                      kind: FamilyMemberKind.spouse,
                      profession: profile.spouse!.profession,
                      age: profile.spouse!.age,
                      familyName: profile.spouse!.familyName,
                      photoPath: spouseLink?.photoPath,
                      linkedUserId: spouseLink?.userId,
                      isLinked: spouseLink != null,
                    ),
                  ),
                ),
              ],
              if (profile.children.isNotEmpty) ...[
                const _Connector(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < profile.children.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _Node(
                        name: profile.children[i].name,
                        role: 'Child · ${profile.children[i].age} yrs',
                        photoPath:
                            profile.memberLinks['child_$i']?.photoPath,
                        onTap: () => _openMember(
                          context,
                          FamilyMemberDetail(
                            memberKey: 'child_$i',
                            name: profile.children[i].name,
                            role: 'Child',
                            kind: FamilyMemberKind.child,
                            age: profile.children[i].age,
                            photoPath:
                                profile.memberLinks['child_$i']?.photoPath,
                            linkedUserId:
                                profile.memberLinks['child_$i']?.userId,
                            isLinked:
                                profile.memberLinks['child_$i'] != null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: FalimyTheme.seed.withValues(alpha: 0.45),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.name,
    required this.role,
    this.highlight = false,
    this.muted = false,
    this.photoHint = false,
    this.photoPath,
    this.onTap,
  });

  final String name;
  final String role;
  final bool highlight;
  final bool muted;
  final bool photoHint;
  final String? photoPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: highlight
                ? FalimyTheme.seed
                : Colors.white.withValues(alpha: muted ? 0.55 : 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? FalimyTheme.seed
                  : FalimyTheme.muted.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (photoPath != null && photoPath!.isNotEmpty)
                ProfileAvatar(photoPath: photoPath, radius: 18)
              else if (photoHint || highlight)
                Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: highlight ? Colors.white : FalimyTheme.seed,
                ),
              if ((photoPath != null && photoPath!.isNotEmpty) ||
                  photoHint ||
                  highlight)
                const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: highlight
                      ? Colors.white
                      : (muted ? FalimyTheme.muted : FalimyTheme.ink),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: highlight
                      ? Colors.white.withValues(alpha: 0.85)
                      : FalimyTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
