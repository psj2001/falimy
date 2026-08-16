import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../providers/onboarding_notifier.dart';

class MarriedQuestionScreen extends ConsumerWidget {
  const MarriedQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      title: 'Are you married?',
      subtitle: 'This helps us build your family tree',
      child: Column(
        children: [
          const Spacer(),
          _ChoiceButton(
            label: 'Yes',
            onPressed: () async {
              await ref.read(onboardingNotifierProvider.notifier).setMarried(true);
              if (context.mounted) context.push(AppRoutes.spouse);
            },
          ),
          const SizedBox(height: 16),
          _ChoiceButton(
            label: 'No',
            outlined: true,
            onPressed: () async {
              await ref.read(onboardingNotifierProvider.notifier).setMarried(false);
              if (context.mounted) context.go(AppRoutes.home);
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
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: FalimyTheme.seed,
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
