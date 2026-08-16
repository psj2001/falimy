import 'dart:async';

import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/auth/domain/entities/user.dart';
import 'package:falimy/features/auth/domain/repositories/auth_repository.dart';
import 'package:falimy/features/onboarding/domain/entities/family_profile.dart';

class AuthSessionResult {
  const AuthSessionResult({
    required this.user,
    this.profile,
    this.claimedInvites = const [],
  });

  final User user;
  final FamilyProfile? profile;
  final List<Map<String, dynamic>> claimedInvites;
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  User? _user;
  final _controller = StreamController<User?>.broadcast();
  bool _initialized = false;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> get authStateChanges async* {
    if (!_initialized) {
      await restore();
    }
    yield _user;
    yield* _controller.stream;
  }

  Future<void> restore() async {
    await _api.restoreSession();
    if (_api.token == null || _api.token!.isEmpty) {
      _user = null;
      _initialized = true;
      _controller.add(null);
      return;
    }

    try {
      final json = await _api.getJson('/api/auth/me');
      final userJson = json['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        await _api.clearToken();
        _user = null;
      } else {
        _user = User(
          id: userJson['id'] as String,
          email: userJson['email'] as String? ?? '',
        );
      }
    } catch (_) {
      await _api.clearToken();
      _user = null;
    }
    _initialized = true;
    _controller.add(_user);
  }

  Future<AuthSessionResult> _authPost(String path, {
    required String email,
    required String password,
  }) async {
    final json = await _api.postJson(path, {
      'email': email.trim(),
      'password': password,
    });

    final token = json['token'] as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw ApiException('Authentication failed');
    }

    await _api.setToken(token);
    final user = User(
      id: userJson['id'] as String,
      email: userJson['email'] as String? ?? '',
    );
    _user = user;
    _controller.add(user);

    final profileJson = json['profile'];
    FamilyProfile? profile;
    if (profileJson is Map<String, dynamic>) {
      profile = FamilyProfileMapper.fromJson(profileJson);
    }

    final claimed = <Map<String, dynamic>>[];
    final rawClaimed = json['claimedInvites'];
    if (rawClaimed is List) {
      for (final item in rawClaimed) {
        if (item is Map<String, dynamic>) {
          claimed.add(item);
        } else if (item is Map) {
          claimed.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return AuthSessionResult(
      user: user,
      profile: profile,
      claimedInvites: claimed,
    );
  }

  /// Sign in and return session extras (profile + claimed invites).
  Future<AuthSessionResult> signInWithSession({
    required String email,
    required String password,
  }) {
    return _authPost(
      '/api/auth/sign-in',
      email: email,
      password: password,
    );
  }

  /// Sign up and return session extras (profile + claimed invites).
  Future<AuthSessionResult> signUpWithSession({
    required String email,
    required String password,
  }) {
    return _authPost(
      '/api/auth/sign-up',
      email: email,
      password: password,
    );
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final session = await signInWithSession(email: email, password: password);
    return session.user;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final session = await signUpWithSession(email: email, password: password);
    return session.user;
  }

  @override
  Future<void> signOut() async {
    await _api.clearToken();
    _user = null;
    _controller.add(null);
  }
}

/// JSON ↔ [FamilyProfile] mapping shared by auth + profile APIs.
class FamilyProfileMapper {
  static FamilyProfile fromJson(Map<String, dynamic> data) {
    DateTime? dob;
    final rawDob = data['dateOfBirth'];
    if (rawDob is String && rawDob.isNotEmpty) {
      dob = DateTime.tryParse(rawDob);
    }

    final siblings = <Sibling>[];
    final siblingsRaw = data['siblings'];
    if (siblingsRaw is List) {
      for (final item in siblingsRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        siblings.add(
          Sibling(
            name: (map['name'] as String?) ?? '',
            gender: SiblingGender.values.firstWhere(
              (e) => e.name == map['gender'],
              orElse: () => SiblingGender.male,
            ),
            seniority: SiblingSeniority.values.firstWhere(
              (e) => e.name == map['seniority'],
              orElse: () => SiblingSeniority.younger,
            ),
          ),
        );
      }
    }

    Spouse? spouse;
    final spouseRaw = data['spouse'];
    if (spouseRaw is Map) {
      final map = Map<String, dynamic>.from(spouseRaw);
      spouse = Spouse(
        name: (map['name'] as String?) ?? '',
        profession: (map['profession'] as String?) ?? '',
        age: (map['age'] as num?)?.toInt() ?? 0,
        familyName: (map['familyName'] as String?) ?? '',
      );
    }

    final children = <Child>[];
    final childrenRaw = data['children'];
    if (childrenRaw is List) {
      for (final item in childrenRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        children.add(
          Child(
            name: (map['name'] as String?) ?? '',
            age: (map['age'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }

    return FamilyProfile(
      fullName: data['fullName'] as String?,
      dateOfBirth: dob,
      familyName: data['familyName'] as String?,
      photoPath: data['photoPath'] as String?,
      fatherName: data['fatherName'] as String?,
      motherName: data['motherName'] as String?,
      siblings: siblings,
      isMarried: data['isMarried'] as bool?,
      spouse: spouse,
      hasChildren: data['hasChildren'] as bool?,
      children: children,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> toJson(FamilyProfile profile) {
    return {
      'fullName': profile.fullName,
      'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
      'familyName': profile.familyName,
      'photoPath': profile.photoPath,
      'fatherName': profile.fatherName,
      'motherName': profile.motherName,
      'siblings': profile.siblings
          .map(
            (s) => {
              'name': s.name,
              'gender': s.gender.name,
              'seniority': s.seniority.name,
            },
          )
          .toList(),
      'isMarried': profile.isMarried,
      'spouse': profile.spouse == null
          ? null
          : {
              'name': profile.spouse!.name,
              'profession': profile.spouse!.profession,
              'age': profile.spouse!.age,
              'familyName': profile.spouse!.familyName,
            },
      'hasChildren': profile.hasChildren,
      'children': profile.children
          .map((c) => {'name': c.name, 'age': c.age})
          .toList(),
      'onboardingComplete': profile.onboardingComplete,
    };
  }
}
