import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import '../models/recurring_rule_model.dart';
import 'db_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      p.join(root, DbConstants.databaseName),
      version: DbConstants.databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.transactions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        amount REAL NOT NULL CHECK(amount > 0),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        merchant TEXT,
        receipt_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_date
      ON ${DbConstants.transactions}(date DESC)
    ''');
    await _createBudgetsTable(db);
    await _createFeatureTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBudgetsTable(db);
    }
    if (oldVersion < 3) {
      await _createFeatureTables(db);
    }
  }

  Future<void> _createBudgetsTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS ${DbConstants.budgets} (
      category TEXT PRIMARY KEY,
      monthly_limit REAL NOT NULL CHECK(monthly_limit >= 0),
      updated_at TEXT NOT NULL
    )
  ''');

  Future<void> _createFeatureTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.merchantRules} (
        merchant_key TEXT PRIMARY KEY,
        merchant_name TEXT NOT NULL,
        category TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.recurringRules} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        amount REAL NOT NULL CHECK(amount > 0),
        category TEXT NOT NULL,
        frequency TEXT NOT NULL CHECK(frequency IN ('weekly', 'monthly')),
        next_date TEXT NOT NULL,
        merchant TEXT,
        note TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recurring_next_date
      ON ${DbConstants.recurringRules}(is_active, next_date)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.appSettings} (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.insert(
      DbConstants.transactions,
      transaction.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> insertTransactions(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final transaction in transactions) {
        await txn.insert(
          DbConstants.transactions,
          transaction.toMap(includeId: false),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaksi yang diperbarui harus memiliki id.');
    }
    final db = await database;
    return db.update(
      DbConstants.transactions,
      transaction.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(
      DbConstants.transactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? from,
    DateTime? toExclusive,
    String? category,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (from != null) {
      conditions.add('date >= ?');
      arguments.add(from.toIso8601String());
    }
    if (toExclusive != null) {
      conditions.add('date < ?');
      arguments.add(toExclusive.toIso8601String());
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      arguments.add(category);
    }
    final rows = await db.query(
      DbConstants.transactions,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<Map<String, double>> getExpenseByCategory({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM ${DbConstants.transactions}
      WHERE type = 'expense' AND date >= ? AND date < ?
      GROUP BY category
      ORDER BY total DESC
    ''',
      [from.toIso8601String(), toExclusive.toIso8601String()],
    );
    return {
      for (final row in rows)
        row['category']! as String: (row['total']! as num).toDouble(),
    };
  }

  Future<List<MonthlyTotal>> getMonthlyTotals({int months = 6}) async {
    final db = await database;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - months + 1);
    final rows = await db.rawQuery(
      '''
      SELECT substr(date, 1, 7) AS month,
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense
      FROM ${DbConstants.transactions}
      WHERE date >= ?
      GROUP BY substr(date, 1, 7)
      ORDER BY month ASC
    ''',
      [from.toIso8601String()],
    );

    final indexed = {for (final row in rows) row['month']! as String: row};
    return List.generate(months, (index) {
      final month = DateTime(from.year, from.month + index);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final row = indexed[key];
      return MonthlyTotal(
        month: month,
        income: (row?['income'] as num?)?.toDouble() ?? 0,
        expense: (row?['expense'] as num?)?.toDouble() ?? 0,
      );
    });
  }

  Future<Map<String, double>> getBudgets() async {
    final db = await database;
    final rows = await db.query(DbConstants.budgets);
    return {
      for (final row in rows)
        row['category']! as String: (row['monthly_limit']! as num).toDouble(),
    };
  }

  Future<void> setBudget(String category, double monthlyLimit) async {
    final db = await database;
    await db.insert(DbConstants.budgets, {
      'category': category,
      'monthly_limit': monthlyLimit,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _merchantKey(String merchant) => merchant
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  Future<String?> getRememberedCategory(String merchant) async {
    final key = _merchantKey(merchant);
    if (key.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      DbConstants.merchantRules,
      columns: ['category'],
      where: 'merchant_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['category'] as String;
  }

  Future<void> rememberMerchantCategory(
    String merchant,
    String category,
  ) async {
    final key = _merchantKey(merchant);
    if (key.isEmpty) return;
    final db = await database;
    await db.rawInsert(
      '''
      INSERT INTO ${DbConstants.merchantRules}
        (merchant_key, merchant_name, category, usage_count, updated_at)
      VALUES (?, ?, ?, 1, ?)
      ON CONFLICT(merchant_key) DO UPDATE SET
        merchant_name = excluded.merchant_name,
        category = excluded.category,
        usage_count = usage_count + 1,
        updated_at = excluded.updated_at
      ''',
      [key, merchant.trim(), category, DateTime.now().toIso8601String()],
    );
  }

  Future<List<RecurringRuleModel>> getRecurringRules() async {
    final db = await database;
    final rows = await db.query(
      DbConstants.recurringRules,
      orderBy: 'is_active DESC, next_date ASC',
    );
    return rows.map(RecurringRuleModel.fromMap).toList(growable: false);
  }

  Future<int> saveRecurringRule(RecurringRuleModel rule) async {
    final db = await database;
    if (rule.id == null) {
      return db.insert(
        DbConstants.recurringRules,
        rule.toMap(includeId: false),
      );
    }
    await db.update(
      DbConstants.recurringRules,
      rule.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    return rule.id!;
  }

  Future<void> deleteRecurringRule(int id) async {
    final db = await database;
    await db.delete(
      DbConstants.recurringRules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      DbConstants.appSettings,
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['setting_value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(DbConstants.appSettings, {
      'setting_key': key,
      'setting_value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getTransactionCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbConstants.transactions}'),
    );
    return result ?? 0;
  }

  Future<Map<String, Object?>> createBackup() async {
    final db = await database;
    return {
      'format': 'pundi-backup',
      'version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'transactions': await db.query(DbConstants.transactions),
      'budgets': await db.query(DbConstants.budgets),
      'merchant_rules': await db.query(DbConstants.merchantRules),
      'recurring_rules': await db.query(DbConstants.recurringRules),
    };
  }

  Future<void> restoreBackup(Map<String, Object?> backup) async {
    final version = backup['version'];
    if (backup['format'] != 'pundi-backup' || (version != 1 && version != 2)) {
      throw const FormatException('Format cadangan Pundi tidak dikenali.');
    }
    final transactions = backup['transactions'];
    final budgets = backup['budgets'];
    if (transactions is! List || budgets is! List) {
      throw const FormatException('Isi cadangan tidak lengkap.');
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DbConstants.transactions);
      await txn.delete(DbConstants.budgets);
      if (version == 2) {
        await txn.delete(DbConstants.merchantRules);
        await txn.delete(DbConstants.recurringRules);
      }
      for (final item in transactions) {
        if (item is! Map) {
          throw const FormatException('Data transaksi tidak valid.');
        }
        final map = jsonDecode(jsonEncode(item)) as Map<String, Object?>;
        TransactionModel.fromMap(map);
        await txn.insert(DbConstants.transactions, map);
      }
      for (final item in budgets) {
        if (item is! Map) {
          throw const FormatException('Data anggaran tidak valid.');
        }
        final map = jsonDecode(jsonEncode(item)) as Map<String, Object?>;
        await txn.insert(DbConstants.budgets, map);
      }
      if (version == 2) {
        await _restoreRows(
          txn,
          DbConstants.merchantRules,
          backup['merchant_rules'],
        );
        await _restoreRows(
          txn,
          DbConstants.recurringRules,
          backup['recurring_rules'],
        );
      }
    });
  }

  Future<void> _restoreRows(Transaction txn, String table, Object? data) async {
    if (data is! List) return;
    for (final item in data) {
      if (item is! Map) {
        throw const FormatException('Isi cadangan tidak valid.');
      }
      final map = jsonDecode(jsonEncode(item)) as Map<String, Object?>;
      await txn.insert(table, map);
    }
  }
}

class MonthlyTotal {
  const MonthlyTotal({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}
