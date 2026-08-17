import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_notifier.dart';
import '../../../onboarding/presentation/providers/onboarding_notifier.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (!ok) {
      final auth = ref.read(authNotifierProvider);
      final error = auth.error;
      if (auth.needsEmailVerification) {
        final email =
            auth.pendingVerificationEmail ?? _emailController.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Verify your email to continue')),
        );
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Sign in failed')),
      );
      return;
    }

    final claimed = ref.read(authNotifierProvider).claimedInvites;
    if (claimed.isNotEmpty) {
      await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
      if (!mounted) return;
      final first = claimed.first;
      ref.read(onboardingNotifierProvider.notifier).applyInviteDefaults(
            fullName: first.memberName,
            familyName: first.familyName,
            linkedInviterName: first.inviterName,
            linkedMemberKind: first.memberKind,
            linkedMemberRole: first.memberRole,
            spouseSuggestionName: first.spouseSuggestionName,
            spouseSuggestionRole: first.spouseSuggestionRole,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Linked as ${first.memberName} (${first.memberRole})',
          ),
        ),
      );
    }

    final profile = ref.read(onboardingNotifierProvider);
    if (profile.onboardingComplete) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.basicInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to Falimy',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signUp),
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
