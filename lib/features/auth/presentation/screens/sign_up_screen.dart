import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../invites/domain/invite_repository.dart';
import '../../../invites/presentation/providers/invite_repository_provider.dart';
import '../providers/auth_notifier.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _referralController = TextEditingController();

  bool _joinWithReferral = false;
  bool _lookingUp = false;
  ReferralPreview? _referral;
  String? _referralError;
  Timer? _lookupDebounce;

  @override
  void dispose() {
    _lookupDebounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  String _normalizeCode(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  void _onReferralChanged(String value) {
    final normalized = _normalizeCode(value);
    if (value != normalized) {
      _referralController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    _lookupDebounce?.cancel();
    setState(() {
      _referral = null;
      _referralError = null;
    });

    if (normalized.length >= 8) {
      _lookupDebounce = Timer(const Duration(milliseconds: 400), () {
        _lookupReferral();
      });
    }
  }

  Future<void> _lookupReferral() async {
    final code = _normalizeCode(_referralController.text);
    if (code.length < 6) {
      setState(() {
        _referral = null;
        _referralError = 'Enter the 8-character code from your invite email';
      });
      return;
    }

    setState(() {
      _lookingUp = true;
      _referralError = null;
    });

    try {
      final preview = await ref
          .read(inviteRepositoryProvider)
          .resolveReferral(code);
      if (!mounted) return;
      if (_normalizeCode(_referralController.text) != code) return;
      setState(() {
        _referral = preview;
        _referralError = null;
        _lookingUp = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_normalizeCode(_referralController.text) != code) return;
      setState(() {
        _referral = null;
        _referralError = e.message;
        _lookingUp = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _referral = null;
        _referralError = 'Could not look up this referral code';
        _lookingUp = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final referralCode = _joinWithReferral
        ? _normalizeCode(_referralController.text)
        : '';

    if (_joinWithReferral) {
      if (referralCode.isEmpty) {
        setState(() {
          _referralError = 'Enter the referral code from your invite email';
        });
        return;
      }
      if (_referral == null) {
        await _lookupReferral();
        if (!mounted || _referral == null) return;
      }
    }

    final ok = await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          email: _emailController.text,
          password: _passwordController.text,
          referralCode: referralCode.isEmpty ? null : referralCode,
        );
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(authNotifierProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Sign up failed')));
      return;
    }

    final auth = ref.read(authNotifierProvider);
    final email = auth.pendingVerificationEmail ?? _emailController.text.trim();
    if (auth.pendingDevOtp != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dev OTP: ${auth.pendingDevOtp}')));
    }
    context.go('${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}');
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
                  'Create account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Falimy and build your family tree',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirmController,
                  obscureText: true,
                  textInputAction: _joinWithReferral
                      ? TextInputAction.next
                      : TextInputAction.done,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _joinWithReferral,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Join with a referral code'),
                  onChanged: (value) {
                    setState(() {
                      _joinWithReferral = value ?? false;
                      if (!_joinWithReferral) {
                        _referral = null;
                        _referralError = null;
                        _referralController.clear();
                      }
                    });
                  },
                ),
                if (_joinWithReferral) ...[
                  AppTextField(
                    label: 'Referral code',
                    controller: _referralController,
                    textInputAction: TextInputAction.done,
                    onChanged: _onReferralChanged,
                    suffixIcon: _lookingUp
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Look up',
                            onPressed: _lookupReferral,
                            icon: const Icon(Icons.search_rounded),
                          ),
                    validator: (v) {
                      if (!_joinWithReferral) return null;
                      final code = _normalizeCode(v ?? '');
                      if (code.isEmpty) {
                        return 'Enter the referral code from your invite';
                      }
                      if (code.length < 6) {
                        return 'Enter a valid referral code';
                      }
                      return null;
                    },
                  ),
                  if (_referralError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _referralError!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_referral != null) ...[
                    const SizedBox(height: 16),
                    _ReferralPreviewCard(preview: _referral!),
                  ],
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Sign Up',
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signIn),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralPreviewCard extends StatelessWidget {
  const _ReferralPreviewCard({required this.preview});

  final ReferralPreview preview;

  @override
  Widget build(BuildContext context) {
    final invitedBy = preview.inviterName.trim().isEmpty
        ? 'A family member'
        : preview.inviterName.trim();
    final hint = preview.inviteeEmailHint?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(label: 'Invited by', value: invitedBy),
          const SizedBox(height: 10),
          _PreviewRow(label: 'Relation', value: preview.memberRole),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Sign up with the email this invite was sent to ($hint).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
