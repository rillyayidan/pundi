enum DebtType {
  payable,
  receivable;

  String get label => this == payable ? 'Utang' : 'Piutang';

  static DebtType fromDatabase(String value) =>
      value == receivable.name ? receivable : payable;
}

class DebtModel {
  const DebtModel({
    this.id,
    required this.type,
    required this.person,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.dueDate,
    this.walletId = 1,
    this.note = '',
    this.createdAt,
  });

  final int? id;
  final DebtType type;
  final String person;
  final double totalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final int walletId;
  final String note;
  final DateTime? createdAt;

  double get remaining => (totalAmount - paidAmount).clamp(0, double.infinity);
  double get progress =>
      totalAmount <= 0 ? 0 : (paidAmount / totalAmount).clamp(0, 1);
  bool get isPaid => remaining <= .5;

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'type': type.name,
    'person': person,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'due_date': dueDate.toIso8601String(),
    'wallet_id': walletId,
    'note': note,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory DebtModel.fromMap(Map<String, Object?> map) => DebtModel(
    id: map['id'] as int?,
    type: DebtType.fromDatabase(map['type']! as String),
    person: map['person']! as String,
    totalAmount: (map['total_amount']! as num).toDouble(),
    paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
    dueDate: DateTime.parse(map['due_date']! as String),
    walletId: map['wallet_id'] as int? ?? 1,
    note: map['note'] as String? ?? '',
    createdAt: map['created_at'] == null
        ? null
        : DateTime.parse(map['created_at']! as String),
  );
}
