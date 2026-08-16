import 'package:equatable/equatable.dart';

enum BookAccess { justMe, team }

class CashBook extends Equatable {
  const CashBook({
    required this.id,
    required this.name,
    required this.access,
    required this.createdAt,
    required this.updatedAt,
    this.syncedToCloud = false,
  });

  final String id;
  final String name;
  final BookAccess access;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool syncedToCloud;

  CashBook copyWith({
    String? id,
    String? name,
    BookAccess? access,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? syncedToCloud,
  }) {
    return CashBook(
      id: id ?? this.id,
      name: name ?? this.name,
      access: access ?? this.access,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'access': access.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'syncedToCloud': syncedToCloud,
      };

  /// Payload for cloud (omit local-only sync flag noise is fine either way).
  Map<String, dynamic> toCloudJson() => {
        'id': id,
        'name': name,
        'access': access.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CashBook.fromJson(Map<String, dynamic> json) {
    return CashBook(
      id: json['id'] as String,
      name: json['name'] as String,
      access: BookAccess.values.firstWhere(
        (e) => e.name == json['access'],
        orElse: () => BookAccess.justMe,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncedToCloud: json['syncedToCloud'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, access, createdAt, updatedAt, syncedToCloud];
}
