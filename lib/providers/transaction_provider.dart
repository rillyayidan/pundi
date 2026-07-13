import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._database);

  final DatabaseHelper _database;
  final List<TransactionModel> _allTransactions = [];
  bool _loading = false;
  String? _error;
  DateTime? _filterFrom;
  DateTime? _filterToExclusive;
  String? _filterCategory;
  String _searchQuery = '';

  List<TransactionModel> get allTransactions =>
      List.unmodifiable(_allTransactions);
  List<TransactionModel> get transactions => List.unmodifiable(
    _allTransactions.where((item) {
      if (_filterFrom != null && item.date.isBefore(_filterFrom!)) return false;
      if (_filterToExclusive != null &&
          !item.date.isBefore(_filterToExclusive!)) {
        return false;
      }
      if (_filterCategory != null && item.category != _filterCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final haystack = [
          item.merchant ?? '',
          item.note,
          item.category,
          item.amount.toStringAsFixed(0),
        ].join(' ').toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }),
  );
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get filterFrom => _filterFrom;
  DateTime? get filterToExclusive => _filterToExclusive;
  String? get filterCategory => _filterCategory;
  String get searchQuery => _searchQuery;

  TransactionModel? findById(int id) {
    for (final transaction in _allTransactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  double get totalIncome => _allTransactions
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _allTransactions
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> load({bool keepFilters = false}) async {
    if (!keepFilters) {
      _filterFrom = null;
      _filterToExclusive = null;
      _filterCategory = null;
      _searchQuery = '';
    }
    await _run(() async {
      final result = await _database.getTransactions();
      _allTransactions
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> applyFilter({
    DateTime? from,
    DateTime? toExclusive,
    String? category,
  }) async {
    _filterFrom = from;
    _filterToExclusive = toExclusive;
    _filterCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  Future<String?> rememberedCategory(String merchant) =>
      _database.getRememberedCategory(merchant);

  Future<void> add(TransactionModel transaction) async {
    if (transaction.amount <= 0) {
      throw ArgumentError.value(
        transaction.amount,
        'amount',
        'Harus lebih dari 0',
      );
    }
    await _database.insertTransaction(transaction);
    await _remember(transaction);
    await load(keepFilters: true);
  }

  Future<void> addAll(List<TransactionModel> transactions) async {
    if (transactions.any((item) => item.amount <= 0)) {
      throw ArgumentError('Semua nominal transaksi harus lebih dari 0.');
    }
    await _database.insertTransactions(transactions);
    final categories = transactions.map((item) => item.category).toSet();
    if (categories.length == 1) {
      await _remember(transactions.first);
    }
    await load(keepFilters: true);
  }

  Future<void> update(TransactionModel transaction) async {
    await _database.updateTransaction(transaction);
    await _remember(transaction);
    await load(keepFilters: true);
  }

  Future<void> delete(int id) async {
    await _database.deleteTransaction(id);
    await load(keepFilters: true);
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _remember(TransactionModel transaction) async {
    final merchant = transaction.merchant?.trim();
    if (merchant == null || merchant.isEmpty) return;
    await _database.rememberMerchantCategory(merchant, transaction.category);
  }
}
