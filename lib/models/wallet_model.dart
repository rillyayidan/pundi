import 'package:flutter/material.dart';

class WalletModel {
  const WalletModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.initialBalance = 0,
    this.isArchived = false,
    this.createdAt,
  });

  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final double initialBalance;
  final bool isArchived;
  final DateTime? createdAt;

  Color get color => Color(colorValue);
  IconData get icon => supportedIcons.firstWhere(
    (item) => item.codePoint == iconCode,
    orElse: () => Icons.account_balance_wallet_rounded,
  );

  static const supportedIcons = <IconData>[
    Icons.account_balance_wallet_rounded,
    Icons.payments_rounded,
    Icons.account_balance_rounded,
    Icons.credit_card_rounded,
    Icons.phone_android_rounded,
    Icons.savings_rounded,
  ];

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'icon_code': iconCode,
    'color_value': colorValue,
    'initial_balance': initialBalance,
    'is_archived': isArchived ? 1 : 0,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory WalletModel.fromMap(Map<String, Object?> map) => WalletModel(
    id: map['id'] as int?,
    name: map['name']! as String,
    iconCode: map['icon_code']! as int,
    colorValue: map['color_value']! as int,
    initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0,
    isArchived: (map['is_archived'] as int? ?? 0) == 1,
    createdAt: map['created_at'] == null
        ? null
        : DateTime.parse(map['created_at']! as String),
  );
}
