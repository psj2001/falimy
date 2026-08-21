import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({required this.id, required this.email});

  final String id;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'email': email};

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, email];
}
