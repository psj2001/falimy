import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/family_profile.dart';
import '../providers/onboarding_notifier.dart';

class ChildrenDetailsScreen extends ConsumerStatefulWidget {
  const ChildrenDetailsScreen({super.key, required this.count});

  final int count;

  @override
  ConsumerState<ChildrenDetailsScreen> createState() =>
      _ChildrenDetailsScreenState();
}

class _ChildrenDetailsScreenState extends ConsumerState<ChildrenDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _ageControllers;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingNotifierProvider).children;
    _nameControllers = List.generate(
      widget.count,
      (i) => TextEditingController(
        text: i < existing.length ? existing[i].name : '',
      ),
    );
    _ageControllers = List.generate(
      widget.count,
      (i) => TextEditingController(
        text: i < existing.length ? existing[i].age.toString() : '',
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _ageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final children = List.generate(
      widget.count,
      (i) => Child(
        name: _nameControllers[i].text.trim(),
        age: int.parse(_ageControllers[i].text.trim()),
      ),
    );

    await ref.read(onboardingNotifierProvider.notifier).setChildren(children);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Children details',
      subtitle: 'Enter name and age for each child',
      bottom: PrimaryButton(label: 'Finish', onPressed: _continue),
      child: Form(
        key: _formKey,
        child: ListView.separated(
          itemCount: widget.count,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Child ${index + 1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Name',
                  controller: _nameControllers[index],
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Age',
                  controller: _ageControllers[index],
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final age = int.tryParse(v?.trim() ?? '');
                    if (age == null || age < 0 || age > 120) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
