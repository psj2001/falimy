import 'dart:async';

import 'package:falimy/features/auth/domain/entities/user.dart';
import 'package:falimy/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  User? _user;
  final _controller = StreamController<User?>.broadcast();

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    _user = User(id: email.hashCode.toString(), email: email.trim());
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (email.trim().isEmpty || password.length < 6) {
      throw Exception('Enter a valid email and password (min 6 chars)');
    }
    _user = User(id: email.hashCode.toString(), email: email.trim());
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
