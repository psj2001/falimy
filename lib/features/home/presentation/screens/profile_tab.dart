import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/constants/app_routes.dart';
import 'package:falimy/core/services/photo_picker_service.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/photo_source_sheet.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
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
    if (!_editing) return;
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
    if (!_editing) return;
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

  void _toggleEdit() {
    if (_editing) {
      _loadFromProfile(ref.read(onboardingNotifierProvider));
      setState(() => _editing = false);
    } else {
      setState(() => _editing = true);
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
      setState(() {
        _saving = false;
        _editing = false;
        _loadFromProfile(ref.read(onboardingNotifierProvider));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    ref.read(onboardingNotifierProvider.notifier).reset();
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final profile = ref.watch(onboardingNotifierProvider);

    // Keep view mode in sync when profile changes externally.
    if (!_editing) {
      // Controllers already loaded; show live photo/name from provider in avatar
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD8F3DC),
            Color(0xFFF7F3EB),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    if (_editing)
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          _loadFromProfile(profile);
                          setState(() => _editing = true);
                        },
                        child: const Text('Edit'),
                      ),
                    if (_editing)
                      TextButton(
                        onPressed: _toggleEdit,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    Center(
                      child: ProfileAvatar(
                        photoPath: _editing ? _photoPath : profile.photoPath,
                        onTap: _editing ? _pickPhoto : null,
                        radius: 52,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'About'),
                    AppTextField(
                      label: 'Full name',
                      controller: _fullName,
                      readOnly: !_editing,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Date of birth',
                      controller: _dob,
                      readOnly: true,
                      onTap: _editing ? _pickDob : null,
                      suffixIcon: _editing
                          ? const Icon(Icons.calendar_today_outlined)
                          : null,
                      validator: (_) =>
                          _dateOfBirth == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Family name',
                      controller: _familyName,
                      readOnly: !_editing,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
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
                    if (_editing)
                      DropdownButtonFormField<OccupationStatus>(
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
                      )
                    else
                      Text(
                        _occupationStatus == null
                            ? 'Not set'
                            : _occupationLabel(_occupationStatus!),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (_occupationStatus == OccupationStatus.working) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Company name',
                        controller: _companyName,
                        readOnly: !_editing,
                        validator: (v) {
                          if (_occupationStatus != OccupationStatus.working) {
                            return null;
                          }
                          return (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Salary (optional)',
                        controller: _salary,
                        readOnly: !_editing,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (_occupationStatus == OccupationStatus.studying) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Class or course',
                        controller: _studyClassOrCourse,
                        readOnly: !_editing,
                        validator: (v) {
                          if (_occupationStatus != OccupationStatus.studying) {
                            return null;
                          }
                          return (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'Parents'),
                    AppTextField(
                      label: 'Father\'s name',
                      controller: _father,
                      readOnly: !_editing,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Mother\'s name',
                      controller: _mother,
                      readOnly: !_editing,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _sectionTitle(context, 'Siblings')),
                        if (_editing)
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
                                  if (_editing)
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
                                readOnly: !_editing,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              if (_editing) ...[
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
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${s.gender == SiblingGender.male ? 'He' : 'She'} · '
                                  '${s.seniority == SiblingSeniority.elder ? 'Elder' : 'Younger'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _sectionTitle(context, 'Marriage'),
                    if (_editing)
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Married')),
                          ButtonSegment(value: false, label: Text('Not married')),
                        ],
                        selected: {_isMarried},
                        onSelectionChanged: (v) {
                          setState(() => _isMarried = v.first);
                        },
                      )
                    else
                      Text(
                        _isMarried ? 'Married' : 'Not married',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (_isMarried) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Spouse name',
                        controller: _spouseName,
                        readOnly: !_editing,
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
                        readOnly: !_editing,
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
                        readOnly: !_editing,
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
                        readOnly: !_editing,
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
                        if (_editing)
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
                                  if (_editing)
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
                                readOnly: !_editing,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 8),
                              AppTextField(
                                label: 'Age',
                                controller: c.age,
                                readOnly: !_editing,
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
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Logout'),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
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
