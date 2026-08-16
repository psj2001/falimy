import 'package:falimy/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  User? get currentUser;

  Stream<User?> get authStateChanges;

  Future<User> signIn({required String email, required String password});

  Future<User> signUp({required String email, required String password});

  Future<void> signOut();
}
