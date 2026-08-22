import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/core/services/device_location.dart';
import 'package:falimy/features/invites/domain/family_invite.dart';

import '../../domain/entities/user.dart';
import 'repository_providers.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.claimedInvites = const [],
    this.pendingVerificationEmail,
    this.pendingDevOtp,
  });

  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final List<FamilyInvite> claimedInvites;
  final String? pendingVerificationEmail;
  final String? pendingDevOtp;

  bool get isAuthenticated => user != null;
  bool get needsEmailVerification =>
      pendingVerificationEmail != null && pendingVerificationEmail!.isNotEmpty;

  AuthState copyWith({
    User? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isInitialized,
    List<FamilyInvite>? claimedInvites,
    bool clearClaimedInvites = false,
    String? pendingVerificationEmail,
    bool clearPendingVerification = false,
    String? pendingDevOtp,
    bool clearPendingDevOtp = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
      claimedInvites: clearClaimedInvites
          ? const []
          : (claimedInvites ?? this.claimedInvites),
      pendingVerificationEmail: clearPendingVerification
          ? null
          : (pendingVerificationEmail ?? this.pendingVerificationEmail),
      pendingDevOtp: clearPendingDevOtp
          ? null
          : (pendingDevOtp ?? this.pendingDevOtp),
    );
  }

  @override
  List<Object?> get props => [
    user,
    isLoading,
    error,
    isInitialized,
    claimedInvites,
    pendingVerificationEmail,
    pendingDevOtp,
  ];
}

List<FamilyInvite> _mapClaimed(List<Map<String, dynamic>> raw) {
  return raw.map((map) {
    return FamilyInvite(
      id: (map['id'] as String?) ?? '',
      inviteeEmail: (map['inviteeEmail'] as String?) ?? '',
      inviterUserId: (map['inviterUserId'] as String?) ?? '',
      inviterName: (map['inviterName'] as String?) ?? '',
      memberKey: (map['memberKey'] as String?) ?? '',
      memberName: (map['memberName'] as String?) ?? '',
      memberKind: (map['memberKind'] as String?) ?? '',
      memberRole: (map['memberRole'] as String?) ?? '',
      familyName: map['familyName'] as String?,
      status: InviteStatus.accepted,
      acceptedUserId: map['acceptedUserId'] as String?,
      spouseSuggestionName: map['spouseSuggestionName'] as String?,
      spouseSuggestionRole: map['spouseSuggestionRole'] as String?,
    );
  }).toList();
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repo = ref.read(apiAuthRepositoryProvider);
    final sub = repo.authStateChanges.listen((user) {
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isInitialized: true,
        clearError: true,
        clearClaimedInvites: user == null,
      );
    });
    ref.onDispose(sub.cancel);

    // Kick off session restore.
    Future.microtask(() => repo.restore());

    return AuthState(user: repo.currentUser, isInitialized: false);
  }

  Future<bool> signIn({
    required String email,
    required String password,
    DeviceLocation? location,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref
          .read(apiAuthRepositoryProvider)
          .signInWithSession(
            email: email,
            password: password,
            location: location,
          );
      state = state.copyWith(
        user: session.user,
        isLoading: false,
        claimedInvites: _mapClaimed(session.claimedInvites),
        clearPendingVerification: true,
        clearPendingDevOtp: true,
      );
      return true;
    } on ApiException catch (e) {
      if (e.needsVerification) {
        final pendingEmail = e.email ?? email.trim();
        state = state.copyWith(
          isLoading: false,
          pendingVerificationEmail: pendingEmail,
          pendingDevOtp: e.body['devOtp'] as String?,
          clearPendingDevOtp: e.body['devOtp'] == null,
          error: e.message,
        );
        return false;
      }
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Starts signup and emails an OTP. Returns true when the client should
  /// navigate to the verify-email screen (account is not created yet).
  Future<bool> signUp({
    required String email,
    required String password,
    String? referralCode,
    DeviceLocation? location,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pending = await ref
          .read(apiAuthRepositoryProvider)
          .signUpWithSession(
            email: email,
            password: password,
            referralCode: referralCode,
            location: location,
          );
      state = state.copyWith(
        isLoading: false,
        pendingVerificationEmail: pending.email,
        pendingDevOtp: pending.devOtp,
        clearPendingDevOtp: pending.devOtp == null,
        clearUser: true,
        clearClaimedInvites: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String otp,
    DeviceLocation? location,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref
          .read(apiAuthRepositoryProvider)
          .verifyEmailWithSession(
            email: email,
            otp: otp,
            location: location,
          );
      state = state.copyWith(
        user: session.user,
        isLoading: false,
        claimedInvites: _mapClaimed(session.claimedInvites),
        clearPendingVerification: true,
        clearPendingDevOtp: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resendOtp({required String email}) async {
    try {
      final pending = await ref
          .read(apiAuthRepositoryProvider)
          .resendOtp(email: email);
      state = state.copyWith(
        pendingVerificationEmail: pending.email,
        pendingDevOtp: pending.devOtp,
        clearPendingDevOtp: pending.devOtp == null,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await ref.read(apiAuthRepositoryProvider).signOut();
    state = state.copyWith(
      clearUser: true,
      clearError: true,
      clearClaimedInvites: true,
      clearPendingVerification: true,
      clearPendingDevOtp: true,
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
