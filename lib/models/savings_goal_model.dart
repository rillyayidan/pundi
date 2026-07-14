class SavingsGoalModel {
  const SavingsGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.colorValue,
    this.walletId = 1,
    this.createdAt,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final int colorValue;
  final int walletId;
  final DateTime? createdAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  SavingsGoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    int? colorValue,
    int? walletId,
    DateTime? createdAt,
  }) => SavingsGoalModel(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    targetDate: targetDate ?? this.targetDate,
    colorValue: colorValue ?? this.colorValue,
    walletId: walletId ?? this.walletId,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'target_date': targetDate.toIso8601String(),
    'color_value': colorValue,
    'wallet_id': walletId,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory SavingsGoalModel.fromMap(Map<String, Object?> map) =>
      SavingsGoalModel(
        id: map['id'] as int?,
        name: map['name']! as String,
        targetAmount: (map['target_amount']! as num).toDouble(),
        currentAmount: (map['current_amount']! as num).toDouble(),
        targetDate: DateTime.parse(map['target_date']! as String),
        colorValue: map['color_value']! as int,
        walletId: map['wallet_id'] as int? ?? 1,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.parse(map['created_at']! as String),
      );
}
