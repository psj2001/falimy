import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/services/photo_picker_service.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/photo_source_sheet.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _fullName;
  late TextEditingController _familyName;
  late TextEditingController _dob;
  late TextEditingController _father;
  late TextEditingController _mother;
  late TextEditingController _spouseName;
  late TextEditingController _spouseProfession;
  late TextEditingController _spouseAge;
  late TextEditingController _spouseFamily;
  late TextEditingController _companyName;
  late TextEditingController _salary;
  late TextEditingController _studyClassOrCourse;

  DateTime? _dateOfBirth;
  String? _photoPath;
  bool _isMarried = false;
  OccupationStatus? _occupationStatus;
  List<_SiblingEdit> _siblings = [];
  List<_ChildEdit> _children = [];

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController();
    _familyName = TextEditingController();
    _dob = TextEditingController();
    _father = TextEditingController();
    _mother = TextEditingController();
    _spouseName = TextEditingController();
    _spouseProfession = TextEditingController();
    _spouseAge = TextEditingController();
    _spouseFamily = TextEditingController();
    _companyName = TextEditingController();
    _salary = TextEditingController();
    _studyClassOrCourse = TextEditingController();
    _loadFromProfile(ref.read(onboardingNotifierProvider));
  }

  void _loadFromProfile(FamilyProfile profile) {
    _fullName.text = profile.fullName ?? '';
    _familyName.text = profile.familyName ?? '';
    _dateOfBirth = profile.dateOfBirth;
    _dob.text = _dateOfBirth == null
        ? ''
        : DateFormat.yMMMMd().format(_dateOfBirth!);
    _photoPath = profile.photoPath;
    _father.text = profile.fatherName ?? '';
    _mother.text = profile.motherName ?? '';
    _isMarried = profile.isMarried == true;
    _occupationStatus = profile.occupationStatus;
    _companyName.text = profile.companyName ?? '';
    _salary.text = profile.salary?.toString() ?? '';
    _studyClassOrCourse.text = profile.studyClassOrCourse ?? '';

    for (final s in _siblings) {
      s.name.dispose();
    }
    _siblings = profile.siblings
        .map(
          (s) => _SiblingEdit(
            name: TextEditingController(text: s.name),
            gender: s.gender,
            seniority: s.seniority,
          ),
        )
        .toList();

    for (final c in _children) {
      c.name.dispose();
      c.age.dispose();
    }
    _children = profile.children
        .map(
          (c) => _ChildEdit(
            name: TextEditingController(text: c.name),
            age: TextEditingController(text: c.age.toString()),
          ),
        )
        .toList();

    final spouse = profile.spouse;
    _spouseName.text = spouse?.name ?? '';
    _spouseProfession.text = spouse?.profession ?? '';
    _spouseAge.text = spouse?.age.toString() ?? '';
    _spouseFamily.text = spouse?.familyName ?? '';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _familyName.dispose();
    _dob.dispose();
    _father.dispose();
    _mother.dispose();
    _spouseName.dispose();
    _spouseProfession.dispose();
    _spouseAge.dispose();
    _spouseFamily.dispose();
    _companyName.dispose();
    _salary.dispose();
    _studyClassOrCourse.dispose();
    for (final s in _siblings) {
      s.name.dispose();
    }
    for (final c in _children) {
      c.name.dispose();
      c.age.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await showPhotoSourceSheet(context);
      if (path != null && mounted) setState(() => _photoPath = path);
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
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dob.text = DateFormat.yMMMMd().format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final current = ref.read(onboardingNotifierProvider);
      final siblings = _siblings
          .map(
            (s) => Sibling(
              name: s.name.text.trim(),
              gender: s.gender,
              seniority: s.seniority,
            ),
          )
          .toList();

      final children = _children
          .map(
            (c) => Child(
              name: c.name.text.trim(),
              age: int.parse(c.age.text.trim()),
            ),
          )
          .toList();

      Spouse? spouse;
      if (_isMarried) {
        spouse = Spouse(
          name: _spouseName.text.trim(),
          profession: _spouseProfession.text.trim(),
          age: int.parse(_spouseAge.text.trim()),
          familyName: _spouseFamily.text.trim(),
        );
      }

      final updated = current.copyWith(
        fullName: _fullName.text.trim(),
        dateOfBirth: _dateOfBirth,
        familyName: _familyName.text.trim(),
        photoPath: _photoPath,
        fatherName: _father.text.trim(),
        motherName: _mother.text.trim(),
        siblings: siblings,
        isMarried: _isMarried,
        clearSpouse: !_isMarried,
        spouse: spouse,
        hasChildren: children.isNotEmpty,
        children: children,
        onboardingComplete: true,
        occupationStatus: _occupationStatus,
        clearOccupationStatus: _occupationStatus == null,
        companyName: _occupationStatus == OccupationStatus.working
            ? _companyName.text.trim()
            : null,
        clearCompanyName: _occupationStatus != OccupationStatus.working,
        salary: _occupationStatus == OccupationStatus.working &&
                _salary.text.trim().isNotEmpty
            ? num.tryParse(_salary.text.trim().replaceAll(',', ''))
            : null,
        clearSalary: _occupationStatus != OccupationStatus.working,
        studyClassOrCourse: _occupationStatus == OccupationStatus.studying
            ? _studyClassOrCourse.text.trim()
            : null,
        clearStudyClassOrCourse: _occupationStatus != OccupationStatus.studying,
      );

      await ref.read(onboardingNotifierProvider.notifier).updateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Center(
              child: ProfileAvatar(
                photoPath: _photoPath,
                onTap: _pickPhoto,
                radius: 52,
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'About'),
            AppTextField(
              label: 'Full name',
              controller: _fullName,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Date of birth',
              controller: _dob,
              readOnly: true,
              onTap: _pickDob,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              validator: (_) => _dateOfBirth == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Family name',
              controller: _familyName,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            if (auth.user != null) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Email'),
                child: Text(auth.user!.email),
              ),
            ],
            const SizedBox(height: 24),
            _sectionTitle(context, 'Occupation'),
            DropdownButtonFormField<OccupationStatus>(
              // ignore: deprecated_member_use
              value: _occupationStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: OccupationStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_occupationLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _occupationStatus = value);
              },
            ),
            if (_occupationStatus == OccupationStatus.working) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Company name',
                controller: _companyName,
                validator: (v) {
                  if (_occupationStatus != OccupationStatus.working) {
                    return null;
                  }
                  return (v == null || v.trim().isEmpty) ? 'Required' : null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Salary (optional)',
                controller: _salary,
                keyboardType: TextInputType.number,
              ),
            ],
            if (_occupationStatus == OccupationStatus.studying) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Class or course',
                controller: _studyClassOrCourse,
                validator: (v) {
                  if (_occupationStatus != OccupationStatus.studying) {
                    return null;
                  }
                  return (v == null || v.trim().isEmpty) ? 'Required' : null;
                },
              ),
            ],
            const SizedBox(height: 24),
            _sectionTitle(context, 'Parents'),
            AppTextField(
              label: "Father's name",
              controller: _father,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Mother's name",
              controller: _mother,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _sectionTitle(context, 'Siblings')),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _siblings.add(
                        _SiblingEdit(
                          name: TextEditingController(),
                          gender: SiblingGender.male,
                          seniority: SiblingSeniority.elder,
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_siblings.isEmpty)
              Text(
                'No siblings',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ...List.generate(_siblings.length, (i) {
              final s = _siblings[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Sibling ${i + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                s.name.dispose();
                                _siblings.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      AppTextField(
                        label: 'Name',
                        controller: s.name,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<SiblingGender>(
                        segments: const [
                          ButtonSegment(
                            value: SiblingGender.male,
                            label: Text('He'),
                          ),
                          ButtonSegment(
                            value: SiblingGender.female,
                            label: Text('She'),
                          ),
                        ],
                        selected: {s.gender},
                        onSelectionChanged: (v) {
                          setState(() => s.gender = v.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<SiblingSeniority>(
                        segments: const [
                          ButtonSegment(
                            value: SiblingSeniority.elder,
                            label: Text('Elder'),
                          ),
                          ButtonSegment(
                            value: SiblingSeniority.younger,
                            label: Text('Younger'),
                          ),
                        ],
                        selected: {s.seniority},
                        onSelectionChanged: (v) {
                          setState(() => s.seniority = v.first);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Marriage'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Married')),
                ButtonSegment(value: false, label: Text('Not married')),
              ],
              selected: {_isMarried},
              onSelectionChanged: (v) {
                setState(() => _isMarried = v.first);
              },
            ),
            if (_isMarried) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Spouse name',
                controller: _spouseName,
                validator: (v) => !_isMarried
                    ? null
                    : (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Profession',
                controller: _spouseProfession,
                validator: (v) => !_isMarried
                    ? null
                    : (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Age',
                controller: _spouseAge,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_isMarried) return null;
                  final age = int.tryParse(v?.trim() ?? '');
                  if (age == null || age < 1 || age > 120) {
                    return 'Enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Family name',
                controller: _spouseFamily,
                validator: (v) => !_isMarried
                    ? null
                    : (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _sectionTitle(context, 'Children')),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _children.add(
                        _ChildEdit(
                          name: TextEditingController(),
                          age: TextEditingController(),
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_children.isEmpty)
              Text(
                'No children',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ...List.generate(_children.length, (i) {
              final c = _children[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Child ${i + 1}'),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                c.name.dispose();
                                c.age.dispose();
                                _children.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      AppTextField(
                        label: 'Name',
                        controller: c.name,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        label: 'Age',
                        controller: c.age,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final age = int.tryParse(v?.trim() ?? '');
                          if (age == null || age < 0 || age > 120) {
                            return 'Enter a valid age';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _card({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FalimyTheme.muted.withValues(alpha: 0.2)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  String _occupationLabel(OccupationStatus status) {
    switch (status) {
      case OccupationStatus.working:
        return 'Working';
      case OccupationStatus.studying:
        return 'Studying';
      case OccupationStatus.unemployed:
        return 'Unemployed';
      case OccupationStatus.retired:
        return 'Retired';
    }
  }
}

class _SiblingEdit {
  _SiblingEdit({
    required this.name,
    required this.gender,
    required this.seniority,
  });

  final TextEditingController name;
  SiblingGender gender;
  SiblingSeniority seniority;
}

class _ChildEdit {
  _ChildEdit({
    required this.name,
    required this.age,
  });

  final TextEditingController name;
  final TextEditingController age;
}
