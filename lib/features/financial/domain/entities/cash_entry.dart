import 'package:equatable/equatable.dart';

enum EntryType { cashIn, cashOut }

class CashEntry extends Equatable {
  const CashEntry({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.contact,
    this.remark,
    this.categoryId,
    this.paymentMode,
    this.createdByLabel = 'You',
  });

  final String id;
  final String bookId;
  final EntryType type;
  final double amount;
  final DateTime dateTime;
  final String? contact;
  final String? remark;
  final String? categoryId;
  final String? paymentMode;
  final String createdByLabel;

  bool get isCashIn => type == EntryType.cashIn;

  CashEntry copyWith({
    String? id,
    String? bookId,
    EntryType? type,
    double? amount,
    DateTime? dateTime,
    String? contact,
    bool clearContact = false,
    String? remark,
    bool clearRemark = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? paymentMode,
    bool clearPaymentMode = false,
    String? createdByLabel,
  }) {
    return CashEntry(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      contact: clearContact ? null : (contact ?? this.contact),
      remark: clearRemark ? null : (remark ?? this.remark),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      paymentMode:
          clearPaymentMode ? null : (paymentMode ?? this.paymentMode),
      createdByLabel: createdByLabel ?? this.createdByLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'type': type.name,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'contact': contact,
        'remark': remark,
        'categoryId': categoryId,
        'paymentMode': paymentMode,
        'createdByLabel': createdByLabel,
      };

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    return CashEntry(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      type: EntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntryType.cashIn,
      ),
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      contact: json['contact'] as String?,
      remark: json['remark'] as String?,
      categoryId: json['categoryId'] as String?,
      paymentMode: json['paymentMode'] as String?,
      createdByLabel: (json['createdByLabel'] as String?) ?? 'You',
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        type,
        amount,
        dateTime,
        contact,
        remark,
        categoryId,
        paymentMode,
        createdByLabel,
      ];
}
