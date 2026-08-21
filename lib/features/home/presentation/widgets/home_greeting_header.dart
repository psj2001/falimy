import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

/// Shared greeting header: avatar + two-line greeting + notification button.
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.profile,
    required this.unreadCount,
    this.onTapAvatar,
    required this.onTapNotifications,
  });

  final FamilyProfile profile;
  final int unreadCount;
  final VoidCallback? onTapAvatar;
  final VoidCallback onTapNotifications;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  String get _firstName {
    final name = profile.fullName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTapAvatar,
          child: ProfileAvatar(
            photoPath: profile.photoPath,
            radius: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: FalimyTheme.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _firstName,
                      style: const TextStyle(
                        color: FalimyTheme.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const TextSpan(
                      text: ' 👋',
                      style: TextStyle(fontSize: 18, height: 1.2),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onTapNotifications,
          badgeCount: unreadCount,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFE8E9EB)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
              child: Icon(icon, size: 24, color: FalimyTheme.ink),
            ),
          ),
        ),
      ),
    );
  }
}
