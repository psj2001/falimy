import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/study_options.dart';
import '../providers/onboarding_notifier.dart';

class StudyDetailsScreen extends ConsumerStatefulWidget {
  const StudyDetailsScreen({super.key});

  @override
  ConsumerState<StudyDetailsScreen> createState() => _StudyDetailsScreenState();
}

class _StudyDetailsScreenState extends ConsumerState<StudyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otherController = TextEditingController();
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingNotifierProvider);
    final options = StudyOptions.optionsForDateOfBirth(profile.dateOfBirth);
    final existing = profile.studyClassOrCourse;
    if (existing != null && existing.isNotEmpty) {
      if (options.contains(existing)) {
        _selectedOption = existing;
      } else {
        _selectedOption = options.contains('Other') ? 'Other' : null;
        _otherController.text = existing;
      }
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class or course')),
      );
      return;
    }

    final isOther = _selectedOption == 'Other';
    if (isOther && !_formKey.currentState!.validate()) return;

    final value = isOther ? _otherController.text.trim() : _selectedOption!;

    ref.read(onboardingNotifierProvider.notifier).setStudyDetails(value);
    context.push(AppRoutes.parents);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingNotifierProvider);
    final options = StudyOptions.optionsForDateOfBirth(profile.dateOfBirth);
    final age = StudyOptions.ageFromDateOfBirth(profile.dateOfBirth);

    return OnboardingScaffold(
      title: 'What are you studying?',
      subtitle: 'Pick your class or course (age $age)',
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() => _selectedOption = value);
                  },
                ),
              ),
            ),
            if (_selectedOption == 'Other') ...[
              const SizedBox(height: 8),
              AppTextField(
                label: 'Specify class or course',
                controller: _otherController,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please specify' : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
