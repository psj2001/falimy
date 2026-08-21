import 'dart:math' as math;

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

  static String? _yearRange(DateTime? dob, {int? age}) {
    if (dob != null) return '${dob.year} - ';
    if (age != null) {
      final birthYear = DateTime.now().year - age;
      return '$birthYear - ';
    }
    return null;
  }

  static String _spouseRelation(FamilyProfile profile) {
    final role = profile.spouseSuggestionRole?.trim() ?? '';
    switch (role.toLowerCase()) {
      case 'wife':
        return 'Wife';
      case 'husband':
        return 'Husband';
      default:
        return 'Spouse';
    }
  }

  Widget _siblingCard(BuildContext context, Sibling sibling) {
    final index = profile.siblings.indexOf(sibling);
    final link = profile.memberLinks['sibling_$index'];
    final isElder = sibling.seniority == SiblingSeniority.elder;
    final role = sibling.gender == SiblingGender.male
        ? (isElder ? 'Elder brother' : 'Younger brother')
        : (isElder ? 'Elder sister' : 'Younger sister');
    return _TreeMember(
      name: sibling.name,
      subtitle: role,
      photoPath: link?.photoPath,
      onTap: () => _openMember(
        context,
        FamilyMemberDetail(
          memberKey: 'sibling_$index',
          name: sibling.name,
          role: role,
          kind: FamilyMemberKind.sibling,
          genderLabel: sibling.gender == SiblingGender.male ? 'Male' : 'Female',
          photoPath: link?.photoPath,
          linkedUserId: link?.userId,
          isLinked: link != null,
        ),
      ),
    );
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

    final hasParents =
        profile.fatherName != null || profile.motherName != null;
    final hasSpouse = profile.isMarried == true && profile.spouse != null;
    final spouseRole = _spouseRelation(profile);
    final geometry = _TreeGeometry(
      hasParents: hasParents,
      hasSpouse: hasSpouse,
      elderCount: elders.length,
      youngerCount: youngers.length,
      childCount: profile.children.length,
    );

    final selfNode = _TreeMember(
      name: profile.fullName ?? 'You',
      subtitle: _yearRange(profile.dateOfBirth) ?? 'You',
      photoPath: profile.photoPath,
      highlight: true,
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
    );

    final cards = <Widget>[
      if (hasParents) ...[
        Positioned(
          left: geometry.fatherLeft,
          top: geometry.parentTop,
          child: _TreeMember(
            name: profile.fatherName ?? 'Father',
            subtitle: 'Father',
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
        ),
        Positioned(
          left: geometry.motherLeft,
          top: geometry.parentTop,
          child: _TreeMember(
            name: profile.motherName ?? 'Mother',
            subtitle: 'Mother',
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
        ),
      ],
      for (var i = 0; i < elders.length; i++)
        Positioned(
          left: geometry.elderLeft(i),
          top: geometry.gen2Top,
          child: _siblingCard(context, elders[i]),
        ),
      if (hasSpouse)
        Positioned(
          left: geometry.wifeLeft,
          top: geometry.gen2Top,
          child: _TreeMember(
            name: profile.spouse!.name,
            subtitle: spouseRole,
            photoPath: spouseLink?.photoPath,
            onTap: () => _openMember(
              context,
              FamilyMemberDetail(
                memberKey: 'spouse',
                name: profile.spouse!.name,
                role: spouseRole,
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
        ),
      Positioned(
        left: geometry.meLeft,
        top: geometry.gen2Top,
        child: selfNode,
      ),
      for (var i = 0; i < youngers.length; i++)
        Positioned(
          left: geometry.youngerLeft(i),
          top: geometry.gen2Top,
          child: _siblingCard(context, youngers[i]),
        ),
      for (var i = 0; i < profile.children.length; i++)
        Positioned(
          left: geometry.childLeft(i),
          top: geometry.childrenTop,
          child: _TreeMember(
            name: profile.children[i].name,
            subtitle: 'Child',
            photoPath: profile.memberLinks['child_$i']?.photoPath,
            onTap: () => _openMember(
              context,
              FamilyMemberDetail(
                memberKey: 'child_$i',
                name: profile.children[i].name,
                role: 'Child',
                kind: FamilyMemberKind.child,
                age: profile.children[i].age,
                photoPath: profile.memberLinks['child_$i']?.photoPath,
                linkedUserId: profile.memberLinks['child_$i']?.userId,
                isLinked: profile.memberLinks['child_$i'] != null,
              ),
            ),
          ),
        ),
    ];

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.55,
      maxScale: 2.2,
      child: CustomPaint(
        painter: const _DotGridPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
          child: SizedBox(
            width: geometry.totalWidth,
            height: geometry.totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(geometry.totalWidth, geometry.totalHeight),
                  painter: _FamilyLinesPainter(geometry),
                ),
                ...cards,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Positions for the pedigree-style tree:
/// parents above blood children, spouse to the left of self, children under the marriage.
class _TreeGeometry {
  _TreeGeometry({
    required this.hasParents,
    required this.hasSpouse,
    required this.elderCount,
    required this.youngerCount,
    required this.childCount,
  }) {
    _resolve();
  }

  final bool hasParents;
  final bool hasSpouse;
  final int elderCount;
  final int youngerCount;
  final int childCount;

  static const cardW = _TreeMember.cardWidth;
  static const cardH = 64.0;
  static const siblingGap = 16.0;
  static const spouseLinkW = 36.0;
  static const coupleGap = 20.0;
  static const connectorH = 36.0;

  late final double shiftX;
  late final double totalWidth;
  late final double totalHeight;
  late final double parentTop;
  late final double gen2Top;
  late final double childrenTop;

  double get _eldersBlock =>
      elderCount == 0 ? 0 : elderCount * cardW + elderCount * siblingGap;

  double wifeLeftLocal() => _eldersBlock;

  double meLeftLocal() =>
      wifeLeftLocal() + (hasSpouse ? cardW + spouseLinkW : 0);

  double youngerLeftLocal(int index) =>
      meLeftLocal() + cardW + siblingGap + index * (cardW + siblingGap);

  double get gen2Width {
    final youngersW = youngerCount == 0
        ? 0
        : youngerCount * siblingGap + youngerCount * cardW;
    return meLeftLocal() + cardW + youngersW;
  }

  List<double> get bloodCentersLocal {
    final xs = <double>[];
    for (var i = 0; i < elderCount; i++) {
      xs.add(i * (cardW + siblingGap) + cardW / 2);
    }
    xs.add(meLeftLocal() + cardW / 2);
    for (var i = 0; i < youngerCount; i++) {
      xs.add(youngerLeftLocal(i) + cardW / 2);
    }
    return xs;
  }

  double get bloodMidLocal {
    final centers = bloodCentersLocal;
    return (centers.first + centers.last) / 2;
  }

  double get parentPairW => cardW * 2 + coupleGap;

  double get parentLeftLocal => bloodMidLocal - parentPairW / 2;

  double get coupleLeftLocal => wifeLeftLocal();

  double get coupleWidth =>
      hasSpouse ? cardW + spouseLinkW + cardW : cardW;

  double get childrenWidth => childCount == 0
      ? 0
      : childCount * cardW + (childCount - 1) * siblingGap;

  double get childrenLeftLocal =>
      coupleLeftLocal + (coupleWidth - childrenWidth) / 2;

  void _resolve() {
    parentTop = 0;
    gen2Top = hasParents ? cardH + connectorH : 0;
    childrenTop = gen2Top + cardH + connectorH;
    totalHeight = childCount > 0 ? childrenTop + cardH : gen2Top + cardH;

    var minX = 0.0;
    if (hasParents) minX = math.min(minX, parentLeftLocal);
    if (childCount > 0) minX = math.min(minX, childrenLeftLocal);
    shiftX = minX < 0 ? -minX : 0;

    var maxX = gen2Width;
    if (hasParents) maxX = math.max(maxX, parentLeftLocal + parentPairW);
    if (childCount > 0) maxX = math.max(maxX, childrenLeftLocal + childrenWidth);
    totalWidth = maxX + shiftX;
  }

  double get fatherLeft => parentLeftLocal + shiftX;
  double get motherLeft => fatherLeft + cardW + coupleGap;

  double elderLeft(int index) =>
      index * (cardW + siblingGap) + shiftX;

  double get wifeLeft => wifeLeftLocal() + shiftX;
  double get meLeft => meLeftLocal() + shiftX;

  double youngerLeft(int index) => youngerLeftLocal(index) + shiftX;

  double childLeft(int index) =>
      childrenLeftLocal + index * (cardW + siblingGap) + shiftX;

  List<double> get bloodCenters =>
      bloodCentersLocal.map((x) => x + shiftX).toList();

  double get coupleMid => coupleLeftLocal + coupleWidth / 2 + shiftX;

  double get meCenter => meLeft + cardW / 2;

  double get wifeRight => wifeLeft + cardW;
}

class _FamilyLinesPainter extends CustomPainter {
  _FamilyLinesPainter(this.g);

  final _TreeGeometry g;

  static const _lineColor = Color(0xFFD1D5DB);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (g.hasParents) {
      _paintParentFork(canvas, paint);
    }
    if (g.hasSpouse) {
      _paintSpouseLink(canvas, paint);
    }
    if (g.childCount > 0) {
      _paintChildrenFork(canvas, paint);
    }
  }

  void _paintParentFork(Canvas canvas, Paint paint) {
    final fatherX = g.fatherLeft + _TreeGeometry.cardW / 2;
    final motherX = g.motherLeft + _TreeGeometry.cardW / 2;
    final parentBottom = g.parentTop + _TreeGeometry.cardH;
    const marriageY = 10.0;
    final barY = parentBottom + marriageY;
    final forkY = g.gen2Top - 16;
    final pairMid = (fatherX + motherX) / 2;

    canvas.drawLine(Offset(fatherX, parentBottom), Offset(fatherX, barY), paint);
    canvas.drawLine(Offset(motherX, parentBottom), Offset(motherX, barY), paint);
    canvas.drawLine(Offset(fatherX, barY), Offset(motherX, barY), paint);
    canvas.drawLine(Offset(pairMid, barY), Offset(pairMid, forkY), paint);

    final drops = g.bloodCenters;
    if (drops.length >= 2) {
      canvas.drawLine(Offset(drops.first, forkY), Offset(drops.last, forkY), paint);
    } else if (drops.length == 1 && (pairMid - drops.first).abs() > 0.5) {
      canvas.drawLine(Offset(pairMid, forkY), Offset(drops.first, forkY), paint);
    }
    for (final x in drops) {
      canvas.drawLine(Offset(x, forkY), Offset(x, g.gen2Top), paint);
    }
  }

  void _paintSpouseLink(Canvas canvas, Paint paint) {
    final y = g.gen2Top + _TreeGeometry.cardH / 2;
    final from = Offset(g.meLeft, y);
    final to = Offset(g.wifeRight, y);
    canvas.drawLine(from, to, paint);
    _arrowHead(canvas, paint, from: from, to: to);
  }

  void _paintChildrenFork(Canvas canvas, Paint paint) {
    final gen2Bottom = g.gen2Top + _TreeGeometry.cardH;
    final barY = gen2Bottom + 10;
    final forkY = g.childrenTop - 16;
    final coupleLeft = g.hasSpouse
        ? g.wifeLeft + _TreeGeometry.cardW / 2
        : g.meCenter;
    final coupleRight = g.meCenter;

    if (g.hasSpouse) {
      canvas.drawLine(
        Offset(coupleLeft, gen2Bottom),
        Offset(coupleLeft, barY),
        paint,
      );
      canvas.drawLine(
        Offset(coupleRight, gen2Bottom),
        Offset(coupleRight, barY),
        paint,
      );
      canvas.drawLine(Offset(coupleLeft, barY), Offset(coupleRight, barY), paint);
      canvas.drawLine(Offset(g.coupleMid, barY), Offset(g.coupleMid, forkY), paint);
    } else {
      canvas.drawLine(Offset(g.meCenter, gen2Bottom), Offset(g.meCenter, forkY), paint);
    }

    final childCenters = [
      for (var i = 0; i < g.childCount; i++)
        g.childLeft(i) + _TreeGeometry.cardW / 2,
    ];
    final stemX = g.hasSpouse ? g.coupleMid : g.meCenter;
    if (childCenters.length >= 2) {
      canvas.drawLine(
        Offset(childCenters.first, forkY),
        Offset(childCenters.last, forkY),
        paint,
      );
    } else if (childCenters.length == 1 &&
        (stemX - childCenters.first).abs() > 0.5) {
      canvas.drawLine(
        Offset(stemX, forkY),
        Offset(childCenters.first, forkY),
        paint,
      );
    }
    for (final x in childCenters) {
      canvas.drawLine(Offset(x, forkY), Offset(x, g.childrenTop), paint);
    }
  }

  void _arrowHead(
    Canvas canvas,
    Paint paint, {
    required Offset from,
    required Offset to,
  }) {
    const size = 6.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    final left = Offset(
      to.dx - ux * size + uy * size * 0.55,
      to.dy - uy * size - ux * size * 0.55,
    );
    final right = Offset(
      to.dx - ux * size - uy * size * 0.55,
      to.dy - uy * size + ux * size * 0.55,
    );
    canvas.drawLine(to, left, paint);
    canvas.drawLine(to, right, paint);
  }

  @override
  bool shouldRepaint(covariant _FamilyLinesPainter oldDelegate) =>
      oldDelegate.g.hasParents != g.hasParents ||
      oldDelegate.g.hasSpouse != g.hasSpouse ||
      oldDelegate.g.elderCount != g.elderCount ||
      oldDelegate.g.youngerCount != g.youngerCount ||
      oldDelegate.g.childCount != g.childCount;
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    const radius = 1.1;
    for (var y = spacing; y < size.height; y += spacing) {
      for (var x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TreeMember extends StatelessWidget {
  const _TreeMember({
    required this.name,
    required this.subtitle,
    this.photoPath,
    this.highlight = false,
    this.muted = false,
    this.onTap,
  });

  static const double cardWidth = 168;

  final String name;
  final String subtitle;
  final String? photoPath;
  final bool highlight;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? const Color(0xFFE8F1FF)
        : Colors.white.withValues(alpha: muted ? 0.7 : 1);
    final border = highlight
        ? const Color(0xFFBFDBFE)
        : const Color(0xFFE5E7EB);
    final nameColor = muted ? FalimyTheme.muted : FalimyTheme.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: cardWidth,
          height: _TreeGeometry.cardH,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ProfileAvatar(photoPath: photoPath, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: FalimyTheme.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
