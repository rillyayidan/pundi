import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

const fintechBlue = Color(0xFF2563EB);
const fintechNavy = Color(0xFF0B1F3A);
const fintechAccent = Color(0xFF0D9488);
const dangerRed = Color(0xFFDC4C64);
const warningAmber = Color(0xFFF59E0B);
const pundiViolet = fintechBlue;
const pundiVioletDark = fintechNavy;
const pundiLilac = Color(0xFFEAF1FF);
const pundiCoral = dangerRed;
const pundiAmber = warningAmber;
const successTeal = Color(0xFF059669);
const brandGreen = successTeal;
const brandGreenDark = Color(0xFF17695B);
const brandMint = Color(0xFFDDF7F2);
const warmSurface = Color(0xFFF4F7FB);
const inkColor = Color(0xFF0F172A);
const darkCanvas = Color(0xFF07111F);
const darkCard = Color(0xFF111D2F);

Color contrastColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : inkColor;

const predefinedExpenseCategories = <CategoryModel>[
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

const predefinedIncomeCategories = <CategoryModel>[
  CategoryModel(
    name: 'Gaji',
    icon: Icons.account_balance_wallet_rounded,
    color: successTeal,
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

final List<CategoryModel> expenseCategories = [...predefinedExpenseCategories];
final List<CategoryModel> incomeCategories = [...predefinedIncomeCategories];

void registerCustomCategories(List<CategoryModel> categories) {
  expenseCategories
    ..removeWhere((item) => item.isCustom)
    ..addAll(categories.where((item) => item.type == 'expense'));
  incomeCategories
    ..removeWhere((item) => item.isCustom)
    ..addAll(categories.where((item) => item.type == 'income'));
}

List<CategoryModel> categoriesFor(TransactionType type) =>
    type == TransactionType.income ? incomeCategories : expenseCategories;

CategoryModel categoryByName(String name) =>
    [...expenseCategories, ...incomeCategories].firstWhere(
      (category) => category.name == name,
      orElse: () => predefinedExpenseCategories.last,
    );
