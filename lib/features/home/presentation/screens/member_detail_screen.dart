import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/core/widgets/profile_avatar.dart';
import 'package:falimy/features/home/domain/family_member_detail.dart';
import 'package:falimy/features/invites/presentation/providers/invite_repository_provider.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.member});

  final FamilyMemberDetail member;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  bool _sending = false;

  Future<bool> _openInviteMail({
    required String to,
    required String inviterName,
    required String memberName,
    required String memberRole,
  }) async {
    final subject = Uri.encodeComponent(
      '$inviterName invited you to Falimy as $memberName',
    );
    final body = Uri.encodeComponent(
      'Hi $memberName,\n\n'
      '$inviterName invited you to join their family tree on Falimy as "$memberRole".\n\n'
      '1. Install the Falimy app\n'
      '2. Create an account using this email: $to\n'
      '3. You will automatically be linked to their family tree\n\n'
      '— Falimy',
    );
    final uri = Uri.parse('mailto:$to?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri);
      }
    } catch (_) {
      // Simulator often has no Mail app — invite is still saved in Firestore.
    }
    return false;
  }

  Future<void> _invite() async {
    final member = widget.member;
    if (!member.canInvite) return;

    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FalimyTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FalimyTheme.muted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Invite ${member.name}',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter their Gmail. They will install Falimy and sign up with this email to be linked as ${member.role}.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Enter an email address';
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Send invite',
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop(emailController.text.trim());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    Future<void>.delayed(
      const Duration(milliseconds: 300),
      emailController.dispose,
    );

    if (email == null || !mounted) return;

    setState(() => _sending = true);
    try {
      final result = await ref.read(inviteRepositoryProvider).sendInvite(
            inviteeEmail: email,
            memberKey: member.memberKey,
            memberName: member.name,
            memberKind: member.kind.name,
            memberRole: member.role,
            familyName: member.familyName,
          );
      if (!mounted) return;

      if (!result.emailDelivered) {
        final openedMail = await _openInviteMail(
          to: result.inviteeEmail,
          inviterName: result.inviterName,
          memberName: result.memberName,
          memberRole: result.memberRole,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              openedMail
                  ? 'Invite saved. Finish sending the email to ${result.inviteeEmail}.'
                  : 'Invite saved for ${result.inviteeEmail}. They can join with that email.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite sent to ${result.inviteeEmail}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final rows = <_DetailRow>[
      _DetailRow(label: 'Relationship', value: member.role),
      if (member.familyName != null && member.familyName!.trim().isNotEmpty)
        _DetailRow(label: 'Family name', value: member.familyName!),
      if (member.dateOfBirth != null)
        _DetailRow(
          label: 'Date of birth',
          value: DateFormat.yMMMMd().format(member.dateOfBirth!),
        ),
      if (member.profession != null && member.profession!.trim().isNotEmpty)
        _DetailRow(label: 'Profession', value: member.profession!),
      if (member.age != null) _DetailRow(label: 'Age', value: '${member.age}'),
      if (member.genderLabel != null)
        _DetailRow(label: 'Gender', value: member.genderLabel!),
    ];

    return Scaffold(
      backgroundColor: FalimyTheme.cream,
      appBar: AppBar(
        title: const Text('Member details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
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
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              children: [
                const SizedBox(height: 12),
                ProfileAvatar(
                  photoPath: member.photoPath,
                  radius: 56,
                ),
                const SizedBox(height: 20),
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  member.role,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: FalimyTheme.muted,
                      ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: FalimyTheme.muted.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FalimyTheme.ink.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: FalimyTheme.muted.withValues(alpha: 0.18),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  rows[i].label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: FalimyTheme.muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rows[i].value,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (member.canInvite) ...[
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Invite',
                    isLoading: _sending,
                    onPressed: _invite,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'They will join Falimy with their email and be identified as ${member.name}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;
}
