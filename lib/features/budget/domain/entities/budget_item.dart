import 'package:equatable/equatable.dart';

class BudgetItem extends Equatable {
  const BudgetItem({
    required this.id,
    required this.name,
    this.planned = 0,
    this.matchKeys = const [],
    this.reminderEnabled = false,
    this.reminderDay,
    this.reminderNote,
  });

  final String id;
  final String name;
  final double planned;
  final List<String> matchKeys;

  /// When true, remind on [reminderDay] each month (1–28).
  final bool reminderEnabled;
  final int? reminderDay;
  final String? reminderNote;

  BudgetItem copyWith({
    String? id,
    String? name,
    double? planned,
    List<String>? matchKeys,
    bool? reminderEnabled,
    int? reminderDay,
    bool clearReminderDay = false,
    String? reminderNote,
    bool clearReminderNote = false,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      planned: planned ?? this.planned,
      matchKeys: matchKeys ?? this.matchKeys,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDay:
          clearReminderDay ? null : (reminderDay ?? this.reminderDay),
      reminderNote:
          clearReminderNote ? null : (reminderNote ?? this.reminderNote),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'planned': planned,
        'matchKeys': matchKeys,
        'reminderEnabled': reminderEnabled,
        'reminderDay': reminderDay,
        'reminderNote': reminderNote,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    final keys = <String>[];
    final raw = json['matchKeys'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) {
          keys.add(item);
        }
      }
    }
    final day = (json['reminderDay'] as num?)?.toInt();
    return BudgetItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      planned: (json['planned'] as num?)?.toDouble() ?? 0,
      matchKeys: keys,
      reminderEnabled: json['reminderEnabled'] == true,
      reminderDay: day != null && day >= 1 && day <= 28 ? day : null,
      reminderNote: json['reminderNote'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        planned,
        matchKeys,
        reminderEnabled,
        reminderDay,
        reminderNote,
      ];
}
