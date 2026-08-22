import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/core/currency/app_currency.dart';
import 'package:falimy/core/currency/currency_picker_sheet.dart';
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

  Future<void> _changeCurrency(BuildContext context, WidgetRef ref) async {
    final current = ref.read(preferredCurrencyProvider);
    final selected = await showCurrencyPickerSheet(
      context,
      selected: current,
    );
    if (selected == null || selected == current) return;
    try {
      await ref.read(onboardingNotifierProvider.notifier).setCurrency(selected);
      if (!context.mounted) return;
      final currency = AppCurrency.of(selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency set to ${currency.title}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update currency: $e')),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(onboardingNotifierProvider.notifier).reset();
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingNotifierProvider);
    final currency = AppCurrency.of(ref.watch(preferredCurrencyProvider));
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
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _changeCurrency(context, ref),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Currency',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.title,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
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
