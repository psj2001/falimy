import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../providers/onboarding_notifier.dart';

class ChildrenQuestionScreen extends ConsumerWidget {
  const ChildrenQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      title: 'Do you have children?',
      subtitle: 'We\'ll collect their details next if you do',
      child: Column(
        children: [
          const Spacer(),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(onboardingNotifierProvider.notifier)
                  .setHasChildren(true);
              if (context.mounted) context.push(AppRoutes.childrenCount);
            },
            style: FilledButton.styleFrom(
              backgroundColor: FalimyTheme.seed,
              minimumSize: const Size.fromHeight(64),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const Text('Yes'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref
                  .read(onboardingNotifierProvider.notifier)
                  .setHasChildren(false);
              if (context.mounted) context.go(AppRoutes.home);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const Text('No'),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
