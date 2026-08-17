import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/onboarding_notifier.dart';

class ChildrenCountScreen extends ConsumerStatefulWidget {
  const ChildrenCountScreen({super.key});

  @override
  ConsumerState<ChildrenCountScreen> createState() =>
      _ChildrenCountScreenState();
}

class _ChildrenCountScreenState extends ConsumerState<ChildrenCountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
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
    context.pushReplacement(
      AppRoutes.childrenDetails,
      extra: profile.children.length,
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final count = int.parse(_countController.text.trim());
    context.push(AppRoutes.childrenDetails, extra: count);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'How many children?',
      subtitle: 'Enter the number of children you have',
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              label: 'Number of children',
              controller: _countController,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1 || n > 10) {
                  return 'Enter a number between 1 and 10';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
