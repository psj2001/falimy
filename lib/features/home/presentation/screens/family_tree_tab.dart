import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/features/home/presentation/widgets/family_org_chart.dart';
import 'package:falimy/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class FamilyTreeTab extends ConsumerWidget {
  const FamilyTreeTab({
    super.key,
    this.onOpenProfile,
  });

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingNotifierProvider);
    final notifications = ref.watch(notificationNotifierProvider);
    final hasData = profile.fullName != null ||
        profile.fatherName != null ||
        profile.motherName != null;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: FalimyTheme.screenGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: HomeGreetingHeader(
                profile: profile,
                unreadCount: notifications.unreadCount,
                onTapAvatar: onOpenProfile,
                onTapNotifications: () =>
                    context.push(AppRoutes.notifications),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Family Tree',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: FalimyTheme.ink,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: hasData
                  ? FamilyOrgChart(profile: profile)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Complete onboarding to see your family tree.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: FalimyTheme.muted,
                                  ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
