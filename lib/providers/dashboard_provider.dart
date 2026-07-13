import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../utils/date_formatter.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._database);

  final DatabaseHelper _database;
  Map<String, double> expensesByCategory = {};
  Map<String, double> previousExpensesByCategory = {};
  List<Map<String, double>> historicalCategoryMonths = [];
  Map<String, double> budgets = {};
  List<MonthlyTotal> monthlyTotals = [];
  double weekendExpenseShare = 0;
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
        _database.getExpenseByCategory(
          from: DateTime(now.year, now.month - 2),
          toExclusive: DateTime(now.year, now.month - 1),
        ),
        _database.getExpenseByCategory(
          from: DateTime(now.year, now.month - 3),
          toExclusive: DateTime(now.year, now.month - 2),
        ),
        _database.getWeekendExpenseShare(),
      ]);
      expensesByCategory = results[0] as Map<String, double>;
      budgets = results[1] as Map<String, double>;
      monthlyTotals = results[2] as List<MonthlyTotal>;
      previousExpensesByCategory = results[3] as Map<String, double>;
      historicalCategoryMonths = [
        results[3] as Map<String, double>,
        results[4] as Map<String, double>,
        results[5] as Map<String, double>,
      ];
      weekendExpenseShare = results[6] as double;
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
        final baseline = _historicalAverage(entry.key);
        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final projected = entry.value / now.day * lastDay;
        return baseline > 0 && projected >= baseline * 1.5;
      })
      .map((entry) => entry.key)
      .toList(growable: false);

  BudgetForecast? forecastFor(String category) {
    final limit = limitFor(category);
    final spent = spentFor(category);
    if (limit <= 0 || spent <= 0 || spent >= limit) return null;
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final currentDaily = spent / now.day;
    final historical = _historicalAverage(category);
    final historicalDaily = historical <= 0
        ? currentDaily
        : historical / lastDay;
    final averagePerDay = currentDaily * .55 + historicalDaily * .45;
    if (averagePerDay <= 0) return null;
    final daysRemaining = ((limit - spent) / averagePerDay).ceil();
    final estimatedDate = DateTime(
      now.year,
      now.month,
      now.day + daysRemaining,
    );
    if (estimatedDate.month != now.month) return null;
    return BudgetForecast(
      category: category,
      estimatedDate: estimatedDate,
      averagePerDay: averagePerDay,
    );
  }

  double _historicalAverage(String category) {
    if (historicalCategoryMonths.isEmpty) return 0;
    return historicalCategoryMonths
            .map((month) => month[category] ?? 0)
            .fold<double>(0, (sum, value) => sum + value) /
        historicalCategoryMonths.length;
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
