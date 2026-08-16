import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/family_profile.dart';
import '../providers/onboarding_notifier.dart';

class SpouseScreen extends ConsumerStatefulWidget {
  const SpouseScreen({super.key});

  @override
  ConsumerState<SpouseScreen> createState() => _SpouseScreenState();
}

class _SpouseScreenState extends ConsumerState<SpouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _ageController = TextEditingController();
  final _familyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final spouse = ref.read(onboardingNotifierProvider).spouse;
    if (spouse != null) {
      _nameController.text = spouse.name;
      _professionController.text = spouse.profession;
      _ageController.text = spouse.age.toString();
      _familyNameController.text = spouse.familyName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _ageController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(onboardingNotifierProvider.notifier).setSpouse(
          Spouse(
            name: _nameController.text.trim(),
            profession: _professionController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            familyName: _familyNameController.text.trim(),
          ),
        );
    context.push(AppRoutes.childrenQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'About your spouse',
      subtitle: 'Name, profession, age, and family name',
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              label: 'Name',
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Profession',
              controller: _professionController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter profession' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Age',
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final age = int.tryParse(v?.trim() ?? '');
                if (age == null || age < 1 || age > 120) {
                  return 'Enter a valid age';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Family name',
              controller: _familyNameController,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter family name' : null,
            ),
          ],
        ),
      ),
    );
  }
}
