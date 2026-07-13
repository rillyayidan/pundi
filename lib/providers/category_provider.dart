import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._database);

  final DatabaseHelper _database;
  List<CategoryModel> customCategories = [];
  bool loading = false;
  String? error;

  List<CategoryModel> forType(TransactionType type) => categoriesFor(type);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      customCategories = await _database.getCustomCategories();
      registerCustomCategories(customCategories);
      error = null;
    } catch (caught) {
      error = caught.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(CategoryModel category) async {
    final all = [...expenseCategories, ...incomeCategories];
    if (all.any(
      (item) =>
          item.name.toLowerCase() == category.name.trim().toLowerCase() &&
          item.id != category.id,
    )) {
      throw ArgumentError('Nama kategori sudah digunakan.');
    }
    await _database.saveCustomCategory(category);
    await load();
  }

  Future<void> delete(CategoryModel category) async {
    if (category.id == null) return;
    await _database.deleteCustomCategory(category.id!);
    await load();
  }
}
