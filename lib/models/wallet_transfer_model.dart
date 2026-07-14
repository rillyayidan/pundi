class WalletTransferModel {
  const WalletTransferModel({
    this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note = '',
    this.createdAt,
  });

  final int? id;
  final int fromWalletId;
  final int toWalletId;
  final double amount;
  final DateTime date;
  final String note;
  final DateTime? createdAt;

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'from_wallet_id': fromWalletId,
    'to_wallet_id': toWalletId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory WalletTransferModel.fromMap(Map<String, Object?> map) =>
      WalletTransferModel(
        id: map['id'] as int?,
        fromWalletId: map['from_wallet_id']! as int,
        toWalletId: map['to_wallet_id']! as int,
        amount: (map['amount']! as num).toDouble(),
        date: DateTime.parse(map['date']! as String),
        note: map['note'] as String? ?? '',
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at']! as String),
      );
}
