enum TransactionType {
  income,
  expense;

  String get databaseValue => name;

  static TransactionType fromDatabase(String value) =>
      value == income.name ? income : expense;
}

class TransactionModel {
  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.merchant,
    this.receiptText,
    this.createdAt,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final String? merchant;
  final String? receiptText;
  final DateTime? createdAt;

  bool get isExpense => type == TransactionType.expense;

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? merchant,
    String? receiptText,
    DateTime? createdAt,
  }) => TransactionModel(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
    merchant: merchant ?? this.merchant,
    receiptText: receiptText ?? this.receiptText,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'type': type.databaseValue,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'merchant': merchant,
    'receipt_text': receiptText,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory TransactionModel.fromMap(Map<String, Object?> map) =>
      TransactionModel(
        id: map['id'] as int?,
        type: TransactionType.fromDatabase(map['type']! as String),
        amount: (map['amount']! as num).toDouble(),
        category: map['category']! as String,
        date: DateTime.parse(map['date']! as String),
        note: map['note'] as String? ?? '',
        merchant: map['merchant'] as String?,
        receiptText: map['receipt_text'] as String?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at']! as String),
      );

  Map<String, Object?> toJson() => toMap();

  factory TransactionModel.fromJson(Map<String, Object?> json) =>
      TransactionModel.fromMap(json);
}
