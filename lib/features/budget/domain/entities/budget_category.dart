import 'package:equatable/equatable.dart';

import 'package:falimy/features/budget/domain/entities/budget_item.dart';

enum LimitType { max, min }

class BudgetCategory extends Equatable {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.targetPercent,
    this.limitType = LimitType.max,
    this.items = const [],
  });

  final String id;
  final String name;
  final String iconKey;
  final double targetPercent;
  final LimitType limitType;
  final List<BudgetItem> items;

  bool get isMinLimit => limitType == LimitType.min;

  double get plannedTotal =>
      items.fold(0, (sum, item) => sum + item.planned);

  BudgetCategory copyWith({
    String? id,
    String? name,
    String? iconKey,
    double? targetPercent,
    LimitType? limitType,
    List<BudgetItem>? items,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      targetPercent: targetPercent ?? this.targetPercent,
      limitType: limitType ?? this.limitType,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'targetPercent': targetPercent,
        'limitType': limitType.name,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    final items = <BudgetItem>[];
    final raw = json['items'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(BudgetItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return BudgetCategory(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      iconKey: (json['iconKey'] as String?) ?? 'misc',
      targetPercent: (json['targetPercent'] as num?)?.toDouble() ?? 0,
      limitType: LimitType.values.firstWhere(
        (value) => value.name == json['limitType'],
        orElse: () => LimitType.max,
      ),
      items: items,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, iconKey, targetPercent, limitType, items];
}
