import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../domain/entities/family_profile.dart';
import '../providers/onboarding_notifier.dart';

class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _dob;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingNotifierProvider);
    _applyProfileDefaults(profile);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
      if (!mounted) return;
      _applyProfileDefaults(ref.read(onboardingNotifierProvider));
    });
  }

  void _applyProfileDefaults(FamilyProfile profile) {
    var changed = false;
    final fullName = profile.fullName?.trim() ?? '';
    final familyName = profile.familyName?.trim() ?? '';

    if (_fullNameController.text.trim().isEmpty && fullName.isNotEmpty) {
      _fullNameController.text = fullName;
      changed = true;
    }
    if (_familyNameController.text.trim().isEmpty && familyName.isNotEmpty) {
      _familyNameController.text = familyName;
      changed = true;
    }
    if (_dob == null && profile.dateOfBirth != null) {
      _dob = profile.dateOfBirth;
      _dobController.text = DateFormat.yMMMMd().format(_dob!);
      changed = true;
    }
    if (_photoPath == null && profile.photoPath != null) {
      _photoPath = profile.photoPath;
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _familyNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await showPhotoSourceSheet(context);
      if (path != null && mounted) {
        setState(() => _photoPath = path);
      }
    } on PhotoPickException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick a photo. Please try again.')),
      );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobController.text = DateFormat.yMMMMd().format(picked);
      });
    }
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    ref.read(onboardingNotifierProvider.notifier).setBasicInfo(
          fullName: _fullNameController.text,
          dateOfBirth: _dob!,
          familyName: _familyNameController.text,
          photoPath: _photoPath,
        );
    context.push(AppRoutes.working);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FamilyProfile>(onboardingNotifierProvider, (_, profile) {
      _applyProfileDefaults(profile);
    });

    return OnboardingScaffold(
      title: 'About you',
      subtitle: 'Tell us your name and family details',
      showBack: false,
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  ProfileAvatar(
                    photoPath: _photoPath,
                    onTap: _pickPhoto,
                    radius: 52,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photo',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Full name',
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Date of birth',
              controller: _dobController,
              readOnly: true,
              onTap: _pickDob,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              validator: (_) => _dob == null ? 'Select date of birth' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Family name',
              controller: _familyNameController,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your family name' : null,
            ),
          ],
        ),
      ),
    );
  }
}
