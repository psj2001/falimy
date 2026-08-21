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
        subtitle: 'Type a family name to see its members.',
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

class _FamilyResultCard extends StatelessWidget {
  const _FamilyResultCard({required this.family});

  final FamilySearchResult family;

  @override
  Widget build(BuildContext context) {
    final count = family.personCount;
    final countLabel = count == 1 ? '1 person' : '$count people';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            family.familyName,
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              for (final member in family.members)
                _MemberTile(member: member),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final FamilySearchMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          ProfileAvatar(photoPath: member.photoPath, radius: 28),
          const SizedBox(height: 8),
          Text(
            member.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FalimyTheme.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            member.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FalimyTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
