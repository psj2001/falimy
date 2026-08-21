import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/home/presentation/screens/edit_profile_screen.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _openEdit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(onboardingNotifierProvider.notifier).reset();
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingNotifierProvider);
    final name = profile.fullName?.trim();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
                child: Column(
                  children: [
                    ProfileAvatar(
                      photoPath: profile.photoPath,
                      radius: 56,
                    ),
                    if (name != null && name.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openEdit(context),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => _logout(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
