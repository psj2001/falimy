import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../providers/onboarding_notifier.dart';

class ChildrenQuestionScreen extends ConsumerStatefulWidget {
  const ChildrenQuestionScreen({super.key});

  @override
  ConsumerState<ChildrenQuestionScreen> createState() =>
      _ChildrenQuestionScreenState();
}

class _ChildrenQuestionScreenState
    extends ConsumerState<ChildrenQuestionScreen> {
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _skipIfKnown());
  }

  Future<void> _skipIfKnown() async {
    if (_skipped) return;
    await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
    if (!mounted) return;
    final profile = ref.read(onboardingNotifierProvider);
    if (!profile.hasInviteChildrenSuggestion) return;

    _skipped = true;
    await ref.read(onboardingNotifierProvider.notifier).setHasChildren(true);
    if (!mounted) return;
    context.pushReplacement(
      AppRoutes.childrenDetails,
      extra: profile.children.length,
    );
  }

  @override
  Widget build(BuildContext context) {
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
