import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../providers/onboarding_notifier.dart';

class MarriedQuestionScreen extends ConsumerStatefulWidget {
  const MarriedQuestionScreen({super.key});

  @override
  ConsumerState<MarriedQuestionScreen> createState() =>
      _MarriedQuestionScreenState();
}

class _MarriedQuestionScreenState extends ConsumerState<MarriedQuestionScreen> {
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _skipIfSpouseKnown());
  }

  /// A spouse coming from the inviter's tree already answers this question.
  Future<void> _skipIfSpouseKnown() async {
    if (_skipped) return;
    await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
    if (!mounted) return;
    if (!ref.read(onboardingNotifierProvider).hasInviteSpouseSuggestion) return;

    _skipped = true;
    await ref.read(onboardingNotifierProvider.notifier).setMarried(true);
    if (!mounted) return;
    context.pushReplacement(AppRoutes.spouse);
  }

  String _subtitle() {
    final profile = ref.watch(onboardingNotifierProvider);
    final spouseName = profile.spouse?.name.trim() ?? '';
    final role = profile.spouseSuggestionRole?.trim() ?? '';
    final inviter = profile.linkedInviterName?.trim() ?? '';
    final kind = (profile.linkedMemberKind ?? '').toLowerCase();

    if (kind == 'father' && spouseName.isNotEmpty) {
      final from = inviter.isEmpty ? "your child's family tree" : "$inviter's family tree";
      return 'From $from, your spouse is identified as Mother: $spouseName';
    }
    if (kind == 'mother' && spouseName.isNotEmpty) {
      final from = inviter.isEmpty ? "your child's family tree" : "$inviter's family tree";
      return 'From $from, your spouse is identified as Father: $spouseName';
    }
    if (role.isNotEmpty && spouseName.isNotEmpty) {
      return 'Your spouse is identified as $role: $spouseName';
    }
    return 'This helps us build your family tree';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Are you married?',
      subtitle: _subtitle(),
      child: Column(
        children: [
          const Spacer(),
          _ChoiceButton(
            label: 'Yes',
            onPressed: () async {
              await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
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
