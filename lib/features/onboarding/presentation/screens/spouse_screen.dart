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
    _applySpouseDefaults(ref.read(onboardingNotifierProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
      if (!mounted) return;
      _applySpouseDefaults(ref.read(onboardingNotifierProvider));
    });
  }

  void _applySpouseDefaults(FamilyProfile profile) {
    final spouse = profile.spouse;
    if (spouse == null) return;

    var changed = false;
    if (_nameController.text.trim().isEmpty && spouse.name.trim().isNotEmpty) {
      _nameController.text = spouse.name.trim();
      changed = true;
    }
    if (_professionController.text.trim().isEmpty &&
        spouse.profession.trim().isNotEmpty) {
      _professionController.text = spouse.profession.trim();
      changed = true;
    }
    if (_ageController.text.trim().isEmpty && spouse.age > 0) {
      _ageController.text = spouse.age.toString();
      changed = true;
    }
    if (_familyNameController.text.trim().isEmpty &&
        spouse.familyName.trim().isNotEmpty) {
      _familyNameController.text = spouse.familyName.trim();
      changed = true;
    } else if (_familyNameController.text.trim().isEmpty &&
        (profile.familyName?.trim().isNotEmpty ?? false)) {
      _familyNameController.text = profile.familyName!.trim();
      changed = true;
    }

    if (changed && mounted) setState(() {});
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

    final profile = ref.read(onboardingNotifierProvider);
    if (profile.hasInviteChildrenSuggestion) {
      context.push(
        AppRoutes.childrenDetails,
        extra: profile.children.length,
      );
      return;
    }
    context.push(AppRoutes.childrenQuestion);
  }

  String _subtitle(FamilyProfile profile) {
    final role = profile.spouseSuggestionRole?.trim() ?? '';
    final inviter = profile.linkedInviterName?.trim() ?? '';
    final kind = (profile.linkedMemberKind ?? '').toLowerCase();
    if (kind == 'father' && role.toLowerCase() == 'mother') {
      final from = inviter.isEmpty ? "your child's family tree" : "$inviter's family tree";
      return 'Auto-filled as Mother from $from. Confirm or edit details.';
    }
    if (kind == 'mother' && role.toLowerCase() == 'father') {
      final from = inviter.isEmpty ? "your child's family tree" : "$inviter's family tree";
      return 'Auto-filled as Father from $from. Confirm or edit details.';
    }
    if (role.isNotEmpty) {
      return 'Auto-filled as $role from the family invite. Confirm or edit details.';
    }
    return 'Name, profession, age, and family name';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingNotifierProvider);
    ref.listen<FamilyProfile>(onboardingNotifierProvider, (_, next) {
      _applySpouseDefaults(next);
    });

    return OnboardingScaffold(
      title: 'About your spouse',
      subtitle: _subtitle(profile),
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
