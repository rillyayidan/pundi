import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../utils/date_formatter.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._database);

  final DatabaseHelper _database;
  Map<String, double> expensesByCategory = {};
  Map<String, double> previousExpensesByCategory = {};
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
        _database.getExpenseByCategory(
          from: DateTime(now.year, now.month - 1),
          toExclusive: DateTime(now.year, now.month),
        ),
      ]);
      expensesByCategory = results[0] as Map<String, double>;
      budgets = results[1] as Map<String, double>;
      monthlyTotals = results[2] as List<MonthlyTotal>;
      previousExpensesByCategory = results[3] as Map<String, double>;
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

  List<String> get overBudgetCategories => budgets.entries
      .where((entry) => entry.value > 0 && spentFor(entry.key) > entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  double get currentMonthExpense =>
      expensesByCategory.values.fold(0, (sum, value) => sum + value);

  double get previousMonthExpense =>
      previousExpensesByCategory.values.fold(0, (sum, value) => sum + value);

  double? get monthChangePercent => previousMonthExpense <= 0
      ? null
      : ((currentMonthExpense - previousMonthExpense) /
            previousMonthExpense *
            100);

  String? get largestIncreaseCategory {
    String? result;
    var largest = 0.0;
    for (final entry in expensesByCategory.entries) {
      final increase =
          entry.value - (previousExpensesByCategory[entry.key] ?? 0);
      if (increase > largest) {
        largest = increase;
        result = entry.key;
      }
    }
    return result;
  }

  double increaseFor(String category) =>
      (expensesByCategory[category] ?? 0) -
      (previousExpensesByCategory[category] ?? 0);

  List<String> get unusualCategories => expensesByCategory.entries
      .where((entry) {
        final previous = previousExpensesByCategory[entry.key] ?? 0;
        return previous > 0 && entry.value >= previous * 1.5;
      })
      .map((entry) => entry.key)
      .toList(growable: false);

  BudgetForecast? forecastFor(String category) {
    final limit = limitFor(category);
    final spent = spentFor(category);
    if (limit <= 0 || spent <= 0 || spent >= limit) return null;
    final now = DateTime.now();
    final elapsedDays = now.day.toDouble();
    final averagePerDay = spent / elapsedDays;
    if (averagePerDay <= 0) return null;
    final projectedDay = (limit / averagePerDay).ceil();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (projectedDay > lastDay) return null;
    return BudgetForecast(
      category: category,
      estimatedDate: DateTime(now.year, now.month, projectedDay),
      averagePerDay: averagePerDay,
    );
  }

  List<BudgetForecast> get forecasts =>
      budgets.keys
          .map(forecastFor)
          .whereType<BudgetForecast>()
          .toList(growable: false)
        ..sort((a, b) => a.estimatedDate.compareTo(b.estimatedDate));
}

class BudgetForecast {
  const BudgetForecast({
    required this.category,
    required this.estimatedDate,
    required this.averagePerDay,
  });

  final String category;
  final DateTime estimatedDate;
  final double averagePerDay;
}
