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

  Future<void> reload() async {
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId == null) return;
    _loadFuture = _hydrate(userId);
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
      // Leave unloaded so the next tree/home refresh retries.
      _loadFuture = null;
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

  void applyInviteDefaults({
    required String fullName,
    String? familyName,
    String? linkedInviterName,
    String? linkedMemberKind,
    String? linkedMemberRole,
    String? spouseSuggestionName,
    String? spouseSuggestionRole,
  }) {
    final invitedName = fullName.trim();
    final invitedFamilyName = familyName?.trim() ?? '';
    final suggestedSpouseName = spouseSuggestionName?.trim() ?? '';
    final existingSpouseName = state.spouse?.name.trim() ?? '';

    Spouse? spouse = state.spouse;
    if (existingSpouseName.isEmpty && suggestedSpouseName.isNotEmpty) {
      spouse = Spouse(
        name: suggestedSpouseName,
        profession: state.spouse?.profession ?? '',
        age: state.spouse?.age ?? 0,
        familyName: invitedFamilyName.isNotEmpty
            ? invitedFamilyName
            : (state.spouse?.familyName ?? state.familyName ?? ''),
      );
    }

    _set(
      state.copyWith(
        fullName: (state.fullName?.trim().isNotEmpty ?? false)
            ? state.fullName
            : invitedName,
        familyName: (state.familyName?.trim().isNotEmpty ?? false)
            ? state.familyName
            : (invitedFamilyName.isEmpty ? null : invitedFamilyName),
        spouse: spouse,
        linkedInviterName: linkedInviterName ?? state.linkedInviterName,
        linkedMemberKind: linkedMemberKind ?? state.linkedMemberKind,
        linkedMemberRole: linkedMemberRole ?? state.linkedMemberRole,
        spouseSuggestionRole: spouseSuggestionRole ?? state.spouseSuggestionRole,
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

  void setWorking(bool isWorking) {
    if (isWorking) {
      _set(
        state.copyWith(
          occupationStatus: OccupationStatus.working,
          clearStudyClassOrCourse: true,
        ),
      );
    } else {
      _set(
        state.copyWith(
          clearOccupationStatus: true,
          clearCompanyName: true,
          clearSalary: true,
          clearStudyClassOrCourse: true,
        ),
      );
    }
  }

  void setOccupationStatus(OccupationStatus status) {
    _set(
      state.copyWith(
        occupationStatus: status,
        clearCompanyName: true,
        clearSalary: true,
        clearStudyClassOrCourse: true,
      ),
    );
  }

  void setWorkDetails({
    required String companyName,
    num? salary,
  }) {
    _set(
      state.copyWith(
        occupationStatus: OccupationStatus.working,
        companyName: companyName.trim(),
        salary: salary,
        clearStudyClassOrCourse: true,
      ),
    );
  }

  void setStudyDetails(String studyClassOrCourse) {
    _set(
      state.copyWith(
        occupationStatus: OccupationStatus.studying,
        studyClassOrCourse: studyClassOrCourse.trim(),
        clearCompanyName: true,
        clearSalary: true,
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

  Future<void> setSalary(num salary) async {
    _set(state.copyWith(salary: salary));
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
