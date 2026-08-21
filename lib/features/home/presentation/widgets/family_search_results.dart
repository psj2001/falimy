import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/home/domain/family_search_result.dart';
import 'package:falimy/features/home/presentation/providers/family_search_notifier.dart';

class FamilySearchResults extends StatelessWidget {
  const FamilySearchResults({super.key, required this.state});

  final FamilySearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().length < 2) {
      return const _SearchMessage(
        icon: Icons.search_rounded,
        title: 'Search a family',
        subtitle: 'Type a family name to see how many people are in it.',
      );
    }

    if (state.isLoading && state.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (state.error != null && state.results.isEmpty) {
      return _SearchMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Could not search',
        subtitle: state.error!,
      );
    }

    if (state.results.isEmpty) {
      return _SearchMessage(
        icon: Icons.groups_outlined,
        title: 'No families found',
        subtitle: 'No family matches “${state.query}”.',
      );
    }

    return Column(
      children: [
        for (final family in state.results) ...[
          _FamilyResultCard(family: family),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FamilyResultCard extends StatefulWidget {
  const _FamilyResultCard({required this.family});

  final FamilySearchResult family;

  @override
  State<_FamilyResultCard> createState() => _FamilyResultCardState();
}

class _FamilyResultCardState extends State<_FamilyResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    final count = family.personCount;
    final countLabel = count == 1 ? '1 person' : '$count people';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: FalimyTheme.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MemberPreview(members: family.members),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            family.familyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FalimyTheme.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countLabel,
                            style: const TextStyle(
                              color: FalimyTheme.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: FalimyTheme.muted,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: _MemberList(members: family.members),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({required this.members});

  final List<FamilySearchMember> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    if (shown.isEmpty) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: Color(0xFFE8EEF8),
        child: Icon(Icons.groups_rounded, color: FalimyTheme.seed, size: 22),
      );
    }

    const radius = 16.0;
    final overflow = members.length - shown.length;
    final stackWidth =
        radius * 2 + (shown.length - 1) * 18 + (overflow > 0 ? 18 : 0);

    return SizedBox(
      width: stackWidth,
      height: radius * 2,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ProfileAvatar(
                  photoPath: shown[i].photoPath,
                  radius: radius,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * 18.0,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: FalimyTheme.seed,
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members});

  final List<FamilySearchMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'No people listed in this family yet.',
          style: TextStyle(color: FalimyTheme.muted, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          const Divider(height: 20, color: Color(0xFFE8E9EB)),
          for (var i = 0; i < members.length; i++) ...[
            _MemberRow(member: members[i]),
            if (i != members.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final FamilySearchMember member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(photoPath: member.photoPath, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FalimyTheme.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FalimyTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 36, color: FalimyTheme.muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FalimyTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FalimyTheme.muted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
