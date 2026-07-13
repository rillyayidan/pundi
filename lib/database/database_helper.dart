import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBudgetsTable(db);
    }
  }

  Future<void> _createBudgetsTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS ${DbConstants.budgets} (
      category TEXT PRIMARY KEY,
      monthly_limit REAL NOT NULL CHECK(monthly_limit >= 0),
      updated_at TEXT NOT NULL
    )
  ''');

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.insert(
      DbConstants.transactions,
      transaction.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
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

  Future<Map<String, Object?>> createBackup() async {
    final db = await database;
    return {
      'format': 'pundi-backup',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'transactions': await db.query(DbConstants.transactions),
      'budgets': await db.query(DbConstants.budgets),
    };
  }

  Future<void> restoreBackup(Map<String, Object?> backup) async {
    if (backup['format'] != 'pundi-backup' || backup['version'] != 1) {
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
    });
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
