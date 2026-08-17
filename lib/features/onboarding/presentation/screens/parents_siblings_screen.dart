import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/family_profile.dart';
import '../providers/onboarding_notifier.dart';

class ParentsSiblingsScreen extends ConsumerStatefulWidget {
  const ParentsSiblingsScreen({super.key});

  @override
  ConsumerState<ParentsSiblingsScreen> createState() =>
      _ParentsSiblingsScreenState();
}

class _ParentsSiblingsScreenState extends ConsumerState<ParentsSiblingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  late List<_SiblingDraft> _siblings;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingNotifierProvider);
    _fatherController.text = profile.fatherName ?? '';
    _motherController.text = profile.motherName ?? '';
    _siblings = profile.siblings
        .map(
          (s) => _SiblingDraft(
            name: TextEditingController(text: s.name),
            gender: s.gender,
            seniority: s.seniority,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _fatherController.dispose();
    _motherController.dispose();
    for (final s in _siblings) {
      s.name.dispose();
    }
    super.dispose();
  }

  void _addSibling() {
    if (_siblings.length >= 10) return;
    setState(() {
      _siblings.add(
        _SiblingDraft(
          name: TextEditingController(),
          gender: SiblingGender.male,
          seniority: SiblingSeniority.elder,
        ),
      );
    });
  }

  void _removeSibling(int index) {
    setState(() {
      _siblings[index].name.dispose();
      _siblings.removeAt(index);
    });
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final siblings = _siblings
        .map(
          (s) => Sibling(
            name: s.name.text.trim(),
            gender: s.gender,
            seniority: s.seniority,
          ),
        )
        .toList();

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setParents(
      fatherName: _fatherController.text,
      motherName: _motherController.text,
      siblings: siblings,
    );

    if (ref.read(onboardingNotifierProvider).hasInviteSpouseSuggestion) {
      await notifier.setMarried(true);
      if (!mounted) return;
      context.push(AppRoutes.spouse);
      return;
    }

    context.push(AppRoutes.married);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Your parents',
      subtitle: 'Add mother, father, and any siblings',
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              label: 'Father\'s name',
              controller: _fatherController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter father\'s name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Mother\'s name',
              controller: _motherController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter mother\'s name' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Siblings', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSibling,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_siblings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No siblings added yet (optional)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ...List.generate(_siblings.length, (index) {
              final sibling = _siblings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: FalimyTheme.muted.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Sibling ${index + 1}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeSibling(index),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        AppTextField(
                          label: 'Name',
                          controller: sibling.name,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter sibling name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Gender',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
                          selected: {sibling.gender},
                          onSelectionChanged: (s) {
                            setState(() => sibling.gender = s.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Relation',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
                          selected: {sibling.seniority},
                          onSelectionChanged: (s) {
                            setState(() => sibling.seniority = s.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SiblingDraft {
  _SiblingDraft({
    required this.name,
    required this.gender,
    required this.seniority,
  });

  final TextEditingController name;
  SiblingGender gender;
  SiblingSeniority seniority;
}
