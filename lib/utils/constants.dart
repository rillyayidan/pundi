import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

const brandGreen = Color(0xFF1F7A3D);
const brandGreenDark = Color(0xFF12562A);
const brandMint = Color(0xFFE7F4EA);
const warmSurface = Color(0xFFF8F8F4);
const inkColor = Color(0xFF18211B);

const expenseCategories = <CategoryModel>[
  CategoryModel(
    name: 'Makanan',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF59E0B),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Transportasi',
    icon: Icons.directions_bus_filled_rounded,
    color: Color(0xFF3B82F6),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Tagihan',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFF8B5CF6),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Belanja',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFEC4899),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Kesehatan',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFFEF4444),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Hiburan',
    icon: Icons.movie_rounded,
    color: Color(0xFF06B6D4),
    type: 'expense',
  ),
  CategoryModel(
    name: 'Lainnya',
    icon: Icons.more_horiz_rounded,
    color: Color(0xFF64748B),
    type: 'expense',
  ),
];

const incomeCategories = <CategoryModel>[
  CategoryModel(
    name: 'Gaji',
    icon: Icons.account_balance_wallet_rounded,
    color: brandGreen,
    type: 'income',
  ),
  CategoryModel(
    name: 'Bonus',
    icon: Icons.redeem_rounded,
    color: Color(0xFF14B8A6),
    type: 'income',
  ),
  CategoryModel(
    name: 'Pendapatan lain',
    icon: Icons.savings_rounded,
    color: Color(0xFF84CC16),
    type: 'income',
  ),
];

List<CategoryModel> categoriesFor(TransactionType type) =>
    type == TransactionType.income ? incomeCategories : expenseCategories;

CategoryModel categoryByName(String name) =>
    [...expenseCategories, ...incomeCategories].firstWhere(
      (category) => category.name == name,
      orElse: () => expenseCategories.last,
    );
