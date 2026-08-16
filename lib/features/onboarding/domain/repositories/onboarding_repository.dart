import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

abstract class OnboardingRepository {
  Future<FamilyProfile?> getProfile(String userId);

  Future<void> saveProfile(String userId, FamilyProfile profile);

  Future<void> clearProfile(String userId);
}
