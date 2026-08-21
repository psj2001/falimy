import 'dart:async';
import 'dart:convert';

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

class SignUpPendingResult {
  const SignUpPendingResult({
    required this.email,
    this.devOtp,
    this.emailDelivered = false,
    this.message,
  });

  final String email;
  final String? devOtp;
  final bool emailDelivered;
  final String? message;
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  User? _user;
  final _controller = StreamController<User?>.broadcast();
  bool _initialized = false;
  Future<void>? _restoreFuture;

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

  Future<void> restore() {
    return _restoreFuture ??= _restore();
  }

  Future<void> _restore() async {
    await _api.restoreSession();
    final token = _api.token;
    if (token == null || token.isEmpty) {
      _user = null;
      _initialized = true;
      _controller.add(null);
      return;
    }

    _user = _userFromCache() ?? _userFromToken(token);
    _initialized = true;
    _controller.add(_user);
    unawaited(_validateSession());
  }

  User? _userFromCache() {
    final cached = _api.cachedUser;
    if (cached == null) return null;
    final user = User.fromJson(cached);
    if (user.id.isEmpty) return null;
    return user;
  }

  User? _userFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      if (json is! Map) return null;
      final id = json['sub'] as String?;
      if (id == null || id.isEmpty) return null;
      return User(id: id, email: json['email'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _validateSession() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final json = await _api.getJson(
          '/api/auth/me',
          timeout: Duration(seconds: 20 + (attempt * 15)),
        );
        final userJson = json['user'] as Map<String, dynamic>?;
        if (userJson == null) {
          break;
        }
        final user = User(
          id: userJson['id'] as String,
          email: userJson['email'] as String? ?? '',
        );
        _user = user;
        await _api.cacheUser(user.toJson());
        final refreshed = json['token'] as String?;
        if (refreshed != null && refreshed.isNotEmpty) {
          await _api.setToken(refreshed);
        }
        _controller.add(user);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await _api.clearToken();
          _user = null;
          _controller.add(null);
          return;
        }
      } catch (_) {}
      if (attempt < 2) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }

    // Network / server errors must not log the user out.
    if (_user != null) {
      _controller.add(_user);
    }
  }

  Future<void> _persistSession(String token, User user) async {
    await _api.setToken(token);
    await _api.cacheUser(user.toJson());
    _user = user;
    _controller.add(user);
  }

  Future<AuthSessionResult> _authPost(
    String path, {
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

    await _persistSession(
      token,
      User(
        id: userJson['id'] as String,
        email: userJson['email'] as String? ?? '',
      ),
    );
    final user = _user!;

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
    return _authPost('/api/auth/sign-in', email: email, password: password);
  }

  /// Sign up: sends OTP and returns pending verification (no session yet).
  Future<SignUpPendingResult> signUpWithSession({
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final json = await _api.postJson('/api/auth/sign-up', {
      'email': email.trim(),
      'password': password,
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referralCode': referralCode.trim().toUpperCase(),
    });

    if (json['needsVerification'] == true) {
      return SignUpPendingResult(
        email: (json['email'] as String?) ?? email.trim(),
        devOtp: json['devOtp'] as String?,
        emailDelivered: json['emailDelivered'] == true,
        message: json['message'] as String?,
      );
    }

    // Backward-compatible: if server still returns a token, treat as signed in.
    final token = json['token'] as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    if (token != null && userJson != null) {
      await _persistSession(
        token,
        User(
          id: userJson['id'] as String,
          email: userJson['email'] as String? ?? '',
        ),
      );
      throw ApiException(
        'Account created without email verification. Please update the server.',
      );
    }

    throw ApiException('Sign up failed');
  }

  Future<AuthSessionResult> verifyEmailWithSession({
    required String email,
    required String otp,
  }) async {
    final json = await _api.postJson('/api/auth/verify-email', {
      'email': email.trim(),
      'otp': otp.trim(),
    });

    final token = json['token'] as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    if (token == null || userJson == null) {
      throw ApiException('Verification failed');
    }

    await _persistSession(
      token,
      User(
        id: userJson['id'] as String,
        email: userJson['email'] as String? ?? '',
      ),
    );
    final user = _user!;

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

  Future<SignUpPendingResult> resendOtp({required String email}) async {
    final json = await _api.postJson('/api/auth/resend-otp', {
      'email': email.trim(),
    });
    return SignUpPendingResult(
      email: (json['email'] as String?) ?? email.trim(),
      devOtp: json['devOtp'] as String?,
      emailDelivered: json['emailDelivered'] == true,
      message: json['message'] as String?,
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final session = await signInWithSession(email: email, password: password);
    return session.user;
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    await signUpWithSession(email: email, password: password);
    throw ApiException('Verify your email to finish creating your account');
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

    String? linkedInviterName;
    String? linkedMemberKind;
    String? linkedMemberRole;
    String? spouseSuggestionRole;
    final linkedRaw = data['linkedFromInvites'];
    if (linkedRaw is List && linkedRaw.isNotEmpty) {
      final first = linkedRaw.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        linkedInviterName = map['inviterName'] as String?;
        linkedMemberKind = map['memberKind'] as String?;
        linkedMemberRole = map['memberRole'] as String?;
        spouseSuggestionRole = map['spouseSuggestionRole'] as String?;
        final suggestedName = (map['spouseSuggestionName'] as String?)?.trim();
        if ((spouse == null || spouse.name.trim().isEmpty) &&
            suggestedName != null &&
            suggestedName.isNotEmpty) {
          spouse = Spouse(
            name: suggestedName,
            profession: '',
            age: 0,
            familyName: (map['familyName'] as String?) ?? '',
          );
        }
      }
    }

    // Father invite from a child → spouse is Mother if not already labeled.
    if ((spouseSuggestionRole == null || spouseSuggestionRole.isEmpty) &&
        (linkedMemberKind ?? '').toLowerCase() == 'father' &&
        (spouse?.name.trim().isNotEmpty ?? false)) {
      spouseSuggestionRole = 'Mother';
    }
    if ((spouseSuggestionRole == null || spouseSuggestionRole.isEmpty) &&
        (linkedMemberKind ?? '').toLowerCase() == 'mother' &&
        (spouse?.name.trim().isNotEmpty ?? false)) {
      spouseSuggestionRole = 'Father';
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

    final memberLinks = <String, LinkedFamilyMember>{};
    final memberLinksRaw = data['memberLinks'];
    if (memberLinksRaw is Map) {
      for (final entry in memberLinksRaw.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final map = Map<String, dynamic>.from(value);
        final userId = (map['userId'] as String?)?.trim() ?? '';
        if (userId.isEmpty) continue;
        memberLinks[entry.key.toString()] = LinkedFamilyMember(
          userId: userId,
          name: (map['name'] as String?) ?? '',
          kind: (map['kind'] as String?) ?? '',
          role: (map['role'] as String?) ?? '',
          email: map['email'] as String?,
          photoPath: map['photoPath'] as String?,
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
      occupationStatus: _parseOccupationStatus(data['occupationStatus']),
      companyName: data['companyName'] as String?,
      salary: data['salary'] as num?,
      studyClassOrCourse: data['studyClassOrCourse'] as String?,
      linkedInviterName: linkedInviterName,
      linkedMemberKind: linkedMemberKind,
      linkedMemberRole: linkedMemberRole,
      spouseSuggestionRole: spouseSuggestionRole,
      memberLinks: memberLinks,
    );
  }

  static OccupationStatus? _parseOccupationStatus(dynamic raw) {
    if (raw is! String) return null;
    for (final status in OccupationStatus.values) {
      if (status.name == raw) return status;
    }
    return null;
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
      'occupationStatus': profile.occupationStatus?.name,
      'companyName': profile.companyName,
      'salary': profile.salary,
      'studyClassOrCourse': profile.studyClassOrCourse,
    };
  }
}
