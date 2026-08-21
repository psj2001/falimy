import 'package:equatable/equatable.dart';

import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/domain/insurance_remaining.dart';

class FamilyAsset extends Equatable {
  const FamilyAsset({
    required this.id,
    required this.category,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.value,
    this.fields = const {},
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AssetCategory category;
  final String name;
  final String ownerId;
  final String ownerName;
  final double value;
  final Map<String, String> fields;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get typeLabel => fields['type']?.trim() ?? '';

  String? get typeImagePath {
    final typed = vehicleTypeImagePath(typeLabel);
    if (typed != null) return typed;
    if (category == AssetCategory.vehicles) return 'assets/car.png';
    return null;
  }

  String get displayEmoji {
    switch (typeLabel.toLowerCase()) {
      case 'bike':
        return '🏍️';
      case 'scooter':
        return '🛵';
      case 'car':
        return '🚗';
      default:
        return category.emoji;
    }
  }

  String get listSubtitle {
    if (typeLabel.isEmpty) return ownerName;
    return '$typeLabel · $ownerName';
  }

  DateTime? get insuranceStart => parseAssetDate(fields['insuranceStart']);

  DateTime? get insuranceEnd => parseAssetDate(fields['insuranceEnd']);

  bool get hasInsurance => insuranceEnd != null;

  InsuranceRemaining? get insuranceRemaining {
    final end = insuranceEnd;
    if (end == null) return null;
    return InsuranceRemaining.fromEnd(end);
  }

  FamilyAsset copyWith({
    String? id,
    AssetCategory? category,
    String? name,
    String? ownerId,
    String? ownerName,
    double? value,
    Map<String, String>? fields,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyAsset(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      value: value ?? this.value,
      fields: fields ?? this.fields,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.id,
    'name': name,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'value': value,
    'fields': fields,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FamilyAsset.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      for (final entry in rawFields.entries) {
        fields[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    return FamilyAsset(
      id: json['id'] as String,
      category: AssetCategoryX.fromId(json['category'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? 'self',
      ownerName: json['ownerName'] as String? ?? 'You',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      fields: fields,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    category,
    name,
    ownerId,
    ownerName,
    value,
    fields,
    notes,
    createdAt,
    updatedAt,
  ];
}
