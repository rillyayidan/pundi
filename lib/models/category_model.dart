import 'package:flutter/material.dart';

class CategoryModel {
  static const supportedIcons = <IconData>[
    Icons.restaurant_rounded,
    Icons.directions_bus_filled_rounded,
    Icons.receipt_long_rounded,
    Icons.shopping_bag_rounded,
    Icons.health_and_safety_rounded,
    Icons.movie_rounded,
    Icons.more_horiz_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.redeem_rounded,
    Icons.savings_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.flight_rounded,
    Icons.sports_esports_rounded,
    Icons.card_giftcard_rounded,
    Icons.work_rounded,
    Icons.volunteer_activism_rounded,
  ];
  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
  });

  final int? id;
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final bool isCustom;

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'icon_code': icon.codePoint,
    'color_value': color.toARGB32(),
    'type': type,
    'created_at': DateTime.now().toIso8601String(),
  };

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    final code = map['icon_code']! as int;
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name']! as String,
      icon: supportedIcons.firstWhere(
        (icon) => icon.codePoint == code,
        orElse: () => Icons.more_horiz_rounded,
      ),
      color: Color(map['color_value']! as int),
      type: map['type']! as String,
      isCustom: true,
    );
  }
}
