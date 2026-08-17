import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../domain/entities/family_profile.dart';
import '../providers/onboarding_notifier.dart';

class OccupationStatusScreen extends ConsumerWidget {
  const OccupationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      title: 'What describes you best?',
      subtitle: 'Select your current status',
      child: Column(
        children: [
          const Spacer(),
          _ChoiceButton(
            label: 'Studying',
            onPressed: () {
              ref
                  .read(onboardingNotifierProvider.notifier)
                  .setOccupationStatus(OccupationStatus.studying);
              context.push(AppRoutes.studyDetails);
            },
          ),
          const SizedBox(height: 12),
          _ChoiceButton(
            label: 'Unemployed',
            outlined: true,
            onPressed: () {
              ref
                  .read(onboardingNotifierProvider.notifier)
                  .setOccupationStatus(OccupationStatus.unemployed);
              context.push(AppRoutes.parents);
            },
          ),
          const SizedBox(height: 12),
          _ChoiceButton(
            label: 'Retired',
            outlined: true,
            onPressed: () {
              ref
                  .read(onboardingNotifierProvider.notifier)
                  .setOccupationStatus(OccupationStatus.retired);
              context.push(AppRoutes.parents);
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: FalimyTheme.seed,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
