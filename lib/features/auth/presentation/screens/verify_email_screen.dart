import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_notifier.dart';
import '../../../onboarding/presentation/providers/onboarding_notifier.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.email.trim().isEmpty && mounted) {
        context.go(AppRoutes.signUp);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authNotifierProvider.notifier)
        .verifyEmail(email: widget.email, otp: _otpController.text.trim());
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(authNotifierProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Verification failed')));
      return;
    }

    final claimed = ref.read(authNotifierProvider).claimedInvites;
    ref.read(onboardingNotifierProvider.notifier).reset();
    await ref.read(onboardingNotifierProvider.notifier).ensureLoaded();
    if (claimed.isNotEmpty) {
      final first = claimed.first;
      ref
          .read(onboardingNotifierProvider.notifier)
          .applyInviteDefaults(
            fullName: first.memberName,
            familyName: first.familyName,
            linkedInviterName: first.inviterName,
            linkedMemberKind: first.memberKind,
            linkedMemberRole: first.memberRole,
            spouseSuggestionName: first.spouseSuggestionName,
            spouseSuggestionRole: first.spouseSuggestionRole,
          );
    }

    if (!mounted) return;
    if (claimed.isNotEmpty) {
      final first = claimed.first;
      final inviter = first.inviterName.isEmpty
          ? 'your family'
          : first.inviterName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Linked as ${first.memberName} (${first.memberRole}) in $inviter\'s tree',
          ),
        ),
      );
    }

    context.go(AppRoutes.basicInfo);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .resendOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _resending = false);

    final auth = ref.read(authNotifierProvider);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not resend code')),
      );
      return;
    }

    final hint = auth.pendingDevOtp != null
        ? 'Code resent (dev: ${auth.pendingDevOtp})'
        : 'A new code was sent to ${widget.email}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hint)));
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
                Text(
                  'Verify email',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code we sent to ${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (auth.pendingDevOtp != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Dev OTP: ${auth.pendingDevOtp}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Verification code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                      return 'Enter the 6-digit code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Verify & continue',
                  isLoading: auth.isLoading,
                  onPressed: _verify,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (auth.isLoading || _resending) ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend code'),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signUp),
                  child: const Text('Back to sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
