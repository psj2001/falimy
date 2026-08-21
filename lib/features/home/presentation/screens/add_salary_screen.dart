import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:falimy/core/widgets/onboarding_scaffold.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/features/home/presentation/screens/salary_cash_book_prompt_screen.dart';

class AddSalaryScreen extends StatefulWidget {
  const AddSalaryScreen({super.key});

  @override
  State<AddSalaryScreen> createState() => _AddSalaryScreenState();
}

class _AddSalaryScreenState extends State<AddSalaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final salary = num.tryParse(
      _salaryController.text.trim().replaceAll(',', ''),
    );
    if (salary == null || salary <= 0) return;

    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SalaryCashBookPromptScreen(salary: salary.toDouble()),
      ),
    );
    if (done == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'How much is your salary?',
      subtitle: 'Enter your monthly take-home amount',
      bottom: PrimaryButton(
        label: 'Continue',
        onPressed: _continue,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _salaryController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onFieldSubmitted: (_) => _continue(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly salary',
                prefixText: 'AED  ',
              ),
              validator: (value) {
                final parsed = num.tryParse(
                  (value ?? '').trim().replaceAll(',', ''),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Enter your salary amount';
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
