import 'package:equatable/equatable.dart';

class EntryCategory extends Equatable {
  const EntryCategory({
    required this.id,
    required this.bookId,
    required this.name,
  });

  final String id;
  final String bookId;
  final String name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'name': name,
      };

  factory EntryCategory.fromJson(Map<String, dynamic> json) {
    return EntryCategory(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, bookId, name];
}
