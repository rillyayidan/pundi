import 'transaction_model.dart';

enum RecurrenceFrequency {
  weekly,
  monthly;

  String get label => this == weekly ? 'Mingguan' : 'Bulanan';

  DateTime nextAfter(DateTime current) {
    if (this == weekly) {
      return current.add(const Duration(days: 7));
    }
    final targetMonth = DateTime(current.year, current.month + 2, 0);
    final day = current.day > targetMonth.day ? targetMonth.day : current.day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      day,
      current.hour,
      current.minute,
    );
  }

  static RecurrenceFrequency fromDatabase(String value) =>
      value == weekly.name ? weekly : monthly;
}

class RecurringRuleModel {
  const RecurringRuleModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDate,
    this.merchant,
    this.note = '',
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final RecurrenceFrequency frequency;
  final DateTime nextDate;
  final String? merchant;
  final String note;
  final bool isActive;
  final DateTime? createdAt;

  RecurringRuleModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? category,
    RecurrenceFrequency? frequency,
    DateTime? nextDate,
    String? merchant,
    String? note,
    bool? isActive,
    DateTime? createdAt,
  }) => RecurringRuleModel(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    frequency: frequency ?? this.frequency,
    nextDate: nextDate ?? this.nextDate,
    merchant: merchant ?? this.merchant,
    note: note ?? this.note,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );

  TransactionModel toTransaction({DateTime? date}) => TransactionModel(
    type: type,
    amount: amount,
    category: category,
    date: date ?? nextDate,
    merchant: merchant,
    note: note,
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'type': type.databaseValue,
    'amount': amount,
    'category': category,
    'frequency': frequency.name,
    'next_date': nextDate.toIso8601String(),
    'merchant': merchant,
    'note': note,
    'is_active': isActive ? 1 : 0,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory RecurringRuleModel.fromMap(Map<String, Object?> map) =>
      RecurringRuleModel(
        id: map['id'] as int?,
        type: TransactionType.fromDatabase(map['type']! as String),
        amount: (map['amount']! as num).toDouble(),
        category: map['category']! as String,
        frequency: RecurrenceFrequency.fromDatabase(
          map['frequency']! as String,
        ),
        nextDate: DateTime.parse(map['next_date']! as String),
        merchant: map['merchant'] as String?,
        note: map['note'] as String? ?? '',
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at']! as String),
      );
}
