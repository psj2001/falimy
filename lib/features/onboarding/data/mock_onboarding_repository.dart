import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/domain/repositories/onboarding_repository.dart';

class MockOnboardingRepository implements OnboardingRepository {
  final Map<String, FamilyProfile> _profiles = {};

  @override
  Future<FamilyProfile?> getProfile(String userId) async => _profiles[userId];

  @override
  Future<void> saveProfile(String userId, FamilyProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _profiles[userId] = profile;
  }

  @override
  Future<void> clearProfile(String userId) async {
    _profiles.remove(userId);
  }
}
