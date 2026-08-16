import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final List<FamilyInvite> claimedInvites;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isInitialized,
    List<FamilyInvite>? claimedInvites,
    bool clearClaimedInvites = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
      claimedInvites: clearClaimedInvites
          ? const []
          : (claimedInvites ?? this.claimedInvites),
    );
  }

  @override
  List<Object?> get props =>
      [user, isLoading, error, isInitialized, claimedInvites];
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

    return AuthState(
      user: repo.currentUser,
      isInitialized: false,
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref.read(apiAuthRepositoryProvider).signInWithSession(
            email: email,
            password: password,
          );
      state = state.copyWith(
        user: session.user,
        isLoading: false,
        claimedInvites: _mapClaimed(session.claimedInvites),
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

  Future<bool> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await ref.read(apiAuthRepositoryProvider).signUpWithSession(
            email: email,
            password: password,
          );
      state = state.copyWith(
        user: session.user,
        isLoading: false,
        claimedInvites: _mapClaimed(session.claimedInvites),
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

  Future<void> signOut() async {
    await ref.read(apiAuthRepositoryProvider).signOut();
    state = state.copyWith(
      clearUser: true,
      clearError: true,
      clearClaimedInvites: true,
    );
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
