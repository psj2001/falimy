import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/core/services/cloudinary_service.dart';
import 'package:falimy/features/auth/data/api_auth_repository.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';
import 'package:falimy/features/onboarding/domain/repositories/onboarding_repository.dart';

class ApiOnboardingRepository implements OnboardingRepository {
  ApiOnboardingRepository({
    required ApiClient apiClient,
    CloudinaryService? cloudinary,
  })  : _api = apiClient,
        _cloudinary = cloudinary ?? CloudinaryService();

  final ApiClient _api;
  final CloudinaryService _cloudinary;

  bool _isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Future<FamilyProfile?> getProfile(String userId) async {
    try {
      final json = await _api.getJson('/api/profile');
      final profile = json['profile'];
      if (profile is! Map) return null;
      return FamilyProfileMapper.fromJson(Map<String, dynamic>.from(profile));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> saveProfile(String userId, FamilyProfile profile) async {
    var photoPath = profile.photoPath;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !_isRemoteUrl(photoPath)) {
      photoPath = await _cloudinary.uploadProfilePhoto(
        userId: userId,
        localPath: photoPath,
      );
    }

    final payload = FamilyProfileMapper.toJson(
      profile.copyWith(photoPath: photoPath),
    );
    await _api.putJson('/api/profile', payload);
  }

  @override
  Future<void> clearProfile(String userId) async {
    await _api.delete('/api/profile');
  }
}
