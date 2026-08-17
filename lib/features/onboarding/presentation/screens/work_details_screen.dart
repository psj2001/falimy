import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/onboarding_notifier.dart';

class WorkDetailsScreen extends ConsumerStatefulWidget {
  const WorkDetailsScreen({super.key});

  @override
  ConsumerState<WorkDetailsScreen> createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends ConsumerState<WorkDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _salaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingNotifierProvider);
    _companyController.text = profile.companyName ?? '';
    if (profile.salary != null) {
      _salaryController.text = profile.salary!.toString();
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    num? salary;
    final salaryText = _salaryController.text.trim();
    if (salaryText.isNotEmpty) {
      salary = num.tryParse(salaryText.replaceAll(',', ''));
    }

    ref.read(onboardingNotifierProvider.notifier).setWorkDetails(
          companyName: _companyController.text,
          salary: salary,
        );
    context.push(AppRoutes.parents);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Work details',
      subtitle: 'Where do you work?',
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              label: 'Company name',
              controller: _companyController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Salary (optional)',
              controller: _salaryController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
