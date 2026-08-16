import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/family_profile.dart';
import 'onboarding_repository_provider.dart';

class OnboardingNotifier extends Notifier<FamilyProfile> {
  Future<void>? _loadFuture;
  String? _loadedForUserId;
  FamilyProfile _profile = const FamilyProfile();

  void _set(FamilyProfile profile) {
    _profile = profile;
    state = profile;
  }

  @override
  FamilyProfile build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId == null) {
      _loadFuture = null;
      _loadedForUserId = null;
      _profile = const FamilyProfile();
      return _profile;
    }

    if (_loadedForUserId != userId) {
      _profile = const FamilyProfile();
      _loadFuture = _hydrate(userId);
    }
    return _profile;
  }

  Future<void> ensureLoaded() async {
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId == null) return;
    if (_loadedForUserId == userId) return;
    _loadFuture ??= _hydrate(userId);
    await _loadFuture;
  }

  Future<void> _hydrate(String userId) async {
    try {
      final profile =
          await ref.read(onboardingRepositoryProvider).getProfile(userId);
      final currentId = ref.read(authNotifierProvider).user?.id;
      if (currentId != userId) return;
      _loadedForUserId = userId;
      _set(profile ?? const FamilyProfile());
    } catch (_) {
      final currentId = ref.read(authNotifierProvider).user?.id;
      if (currentId != userId) return;
      _loadedForUserId = userId;
    }
  }

  void setBasicInfo({
    required String fullName,
    required DateTime dateOfBirth,
    required String familyName,
    String? photoPath,
  }) {
    _set(
      state.copyWith(
        fullName: fullName.trim(),
        dateOfBirth: dateOfBirth,
        familyName: familyName.trim(),
        photoPath: photoPath,
      ),
    );
  }

  void setPhoto(String? path) {
    if (path == null) {
      _set(state.copyWith(clearPhoto: true));
    } else {
      _set(state.copyWith(photoPath: path));
    }
  }

  void setParents({
    required String fatherName,
    required String motherName,
    required List<Sibling> siblings,
  }) {
    _set(
      state.copyWith(
        fatherName: fatherName.trim(),
        motherName: motherName.trim(),
        siblings: siblings,
      ),
    );
  }

  Future<void> setMarried(bool isMarried) async {
    if (!isMarried) {
      _set(
        state.copyWith(
          isMarried: false,
          clearSpouse: true,
          hasChildren: false,
          children: const [],
          onboardingComplete: true,
        ),
      );
      await _persist();
    } else {
      _set(state.copyWith(isMarried: true));
    }
  }

  void setSpouse(Spouse spouse) {
    _set(state.copyWith(spouse: spouse, isMarried: true));
  }

  Future<void> setHasChildren(bool hasChildren) async {
    if (!hasChildren) {
      _set(
        state.copyWith(
          hasChildren: false,
          children: const [],
          onboardingComplete: true,
        ),
      );
      await _persist();
    } else {
      _set(state.copyWith(hasChildren: true));
    }
  }

  Future<void> setChildren(List<Child> children) async {
    _set(
      state.copyWith(
        hasChildren: true,
        children: children,
        onboardingComplete: true,
      ),
    );
    await _persist();
  }

  Future<void> updateProfile(FamilyProfile profile) async {
    _set(profile);
    await _persist();
  }

  Future<void> _persist() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    try {
      await ref.read(onboardingRepositoryProvider).saveProfile(user.id, state);
      final saved =
          await ref.read(onboardingRepositoryProvider).getProfile(user.id);
      if (saved != null) {
        _set(saved);
      }
    } catch (e) {
      // Keep local draft state; surface error to caller if needed.
      rethrow;
    }
  }

  void reset() {
    _loadFuture = null;
    _loadedForUserId = null;
    _set(const FamilyProfile());
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, FamilyProfile>(OnboardingNotifier.new);
