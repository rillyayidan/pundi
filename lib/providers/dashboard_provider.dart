import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../utils/date_formatter.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._database);

  final DatabaseHelper _database;
  Map<String, double> expensesByCategory = {};
  Map<String, double> budgets = {};
  List<MonthlyTotal> monthlyTotals = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final results = await Future.wait<Object>([
        _database.getExpenseByCategory(
          from: startOfMonth(now),
          toExclusive: endOfMonth(now),
        ),
        _database.getBudgets(),
        _database.getMonthlyTotals(),
      ]);
      expensesByCategory = results[0] as Map<String, double>;
      budgets = results[1] as Map<String, double>;
      monthlyTotals = results[2] as List<MonthlyTotal>;
    } catch (caught) {
      error = caught.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setBudget(String category, double value) async {
    await _database.setBudget(category, value);
    await load();
  }

  double spentFor(String category) => expensesByCategory[category] ?? 0;
  double limitFor(String category) => budgets[category] ?? 0;
}
