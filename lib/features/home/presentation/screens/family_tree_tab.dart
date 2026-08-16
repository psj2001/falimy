import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/home/presentation/widgets/family_org_chart.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class FamilyTreeTab extends ConsumerWidget {
  const FamilyTreeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingNotifierProvider);
    final hasData = profile.fullName != null ||
        profile.fatherName != null ||
        profile.motherName != null;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD8F3DC),
            Color(0xFFF7F3EB),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Tree',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pinch to zoom · drag to pan',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: FalimyTheme.muted,
                              ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
