import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/category_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../models/recurring_rule_model.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transfer_model.dart';
import 'db_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _secureStorage = FlutterSecureStorage();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    final path = p.join(root, DbConstants.databaseName);
    var key = await _secureStorage.read(key: 'pundi_database_key');
    if (key == null) {
      final random = Random.secure();
      key = base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
      await _secureStorage.write(key: 'pundi_database_key', value: key);
    }
    final encrypted =
        await _secureStorage.read(key: 'pundi_database_encrypted') == 'true';
    if (await File(path).exists() && !encrypted) {
      await _encryptExistingDatabase(path, key);
    }
    await _secureStorage.write(key: 'pundi_database_encrypted', value: 'true');
    return openDatabase(
      path,
      password: key,
      version: DbConstants.databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _encryptExistingDatabase(String path, String key) async {
    final tempPath = '$path.encrypted';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) await tempFile.delete();
    final plain = await openDatabase(path, singleInstance: false);
    try {
      final escapedPath = tempPath.replaceAll("'", "''");
      final escapedKey = key.replaceAll("'", "''");
      await plain.execute(
        "ATTACH DATABASE '$escapedPath' AS encrypted KEY '$escapedKey'",
      );
      await plain.rawQuery("SELECT sqlcipher_export('encrypted')");
      final version = await plain.getVersion();
      await plain.execute('PRAGMA encrypted.user_version = $version');
      await plain.execute('DETACH DATABASE encrypted');
    } finally {
      await plain.close();
    }
    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('$path$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
    final backupPath = '$path.plaintext-backup';
    final backupFile = File(backupPath);
    if (await backupFile.exists()) await backupFile.delete();
    await File(path).rename(backupPath);
    try {
      await tempFile.rename(path);
      final check = await openDatabase(
        path,
        password: key,
        singleInstance: false,
      );
      await check.rawQuery('SELECT count(*) FROM sqlite_master');
      await check.close();
      await backupFile.delete();
    } catch (_) {
      if (await File(path).exists()) await File(path).delete();
      await backupFile.rename(path);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.transactions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        amount REAL NOT NULL CHECK(amount > 0),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        wallet_id INTEGER NOT NULL DEFAULT 1,
        note TEXT NOT NULL DEFAULT '',
        merchant TEXT,
        receipt_text TEXT,
        receipt_image_path TEXT,
        deleted_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_date
      ON ${DbConstants.transactions}(date DESC)
    ''');
    await _createBudgetsTable(db);
    await _createFeatureTables(db);
    await _createIterationTables(db);
    await _createWalletTables(db);
    await _createTransferTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBudgetsTable(db);
    }
    if (oldVersion < 3) {
      await _createFeatureTables(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DbConstants.transactions} ADD COLUMN receipt_image_path TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.transactions} ADD COLUMN deleted_at TEXT',
      );
      await _createIterationTables(db);
    }
    if (oldVersion < 5) {
      await _createWalletTables(db);
      await db.execute(
        'ALTER TABLE ${DbConstants.transactions} ADD COLUMN wallet_id INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.recurringRules} ADD COLUMN wallet_id INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 6) {
      await _createTransferTables(db);
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
        wallet_id INTEGER NOT NULL DEFAULT 1,
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

  Future<void> _createIterationTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.customCategories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.savingsGoals} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL CHECK(target_amount > 0),
        current_amount REAL NOT NULL DEFAULT 0 CHECK(current_amount >= 0),
        target_date TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_deleted
      ON ${DbConstants.transactions}(deleted_at, date DESC)
    ''');
  }

  Future<void> _createWalletTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.wallets} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.insert(DbConstants.wallets, {
      'id': 1,
      'name': 'Tunai',
      'icon_code': WalletModel.supportedIcons.first.codePoint,
      'color_value': 0xFF6657D9,
      'initial_balance': 0,
      'is_archived': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _createTransferTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.walletTransfers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_wallet_id INTEGER NOT NULL,
        to_wallet_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        CHECK(from_wallet_id != to_wallet_id),
        FOREIGN KEY(from_wallet_id) REFERENCES ${DbConstants.wallets}(id),
        FOREIGN KEY(to_wallet_id) REFERENCES ${DbConstants.wallets}(id)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_wallet_transfers_date
      ON ${DbConstants.walletTransfers}(date DESC)
    ''');
  }

  Future<List<WalletTransferModel>> getWalletTransfers() async {
    final db = await database;
    final rows = await db.query(
      DbConstants.walletTransfers,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(WalletTransferModel.fromMap).toList(growable: false);
  }

  Future<int> saveWalletTransfer(WalletTransferModel transfer) async {
    if (transfer.fromWalletId == transfer.toWalletId) {
      throw ArgumentError('Wallet asal dan tujuan harus berbeda.');
    }
    final db = await database;
    if (transfer.id == null) {
      return db.insert(
        DbConstants.walletTransfers,
        transfer.toMap(includeId: false),
      );
    }
    await db.update(
      DbConstants.walletTransfers,
      transfer.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [transfer.id],
    );
    return transfer.id!;
  }

  Future<void> deleteWalletTransfer(int id) async {
    final db = await database;
    await db.delete(
      DbConstants.walletTransfers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<WalletModel>> getWallets({bool includeArchived = false}) async {
    final db = await database;
    final rows = await db.query(
      DbConstants.wallets,
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'id ASC',
    );
    return rows.map(WalletModel.fromMap).toList(growable: false);
  }

  Future<int> saveWallet(WalletModel wallet) async {
    final db = await database;
    if (wallet.id == null) {
      return db.insert(DbConstants.wallets, wallet.toMap(includeId: false));
    }
    await db.update(
      DbConstants.wallets,
      wallet.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    return wallet.id!;
  }

  Future<void> deleteWallet(int id) async {
    if (id == 1) throw ArgumentError('Wallet utama tidak dapat dihapus.');
    final db = await database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DbConstants.transactions} WHERE wallet_id = ?',
            [id],
          ),
        ) ??
        0;
    final transferCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DbConstants.walletTransfers} WHERE from_wallet_id = ? OR to_wallet_id = ?',
            [id, id],
          ),
        ) ??
        0;
    if (count > 0 || transferCount > 0) {
      throw StateError(
        'Wallet masih memiliki transaksi atau transfer dan tidak dapat dihapus.',
      );
    }
    await db.delete(DbConstants.wallets, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, double>> getWalletBalances() async {
    final db = await database;
    final wallets = await db.query(
      DbConstants.wallets,
      columns: ['id', 'initial_balance'],
    );
    final totals = await db.rawQuery('''
      SELECT wallet_id,
        SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) AS movement
      FROM ${DbConstants.transactions}
      WHERE deleted_at IS NULL
      GROUP BY wallet_id
    ''');
    final movements = {
      for (final row in totals)
        row['wallet_id']! as int: (row['movement'] as num?)?.toDouble() ?? 0,
    };
    final transfers = await db.rawQuery('''
      SELECT wallet_id, SUM(movement) AS movement FROM (
        SELECT from_wallet_id AS wallet_id, -amount AS movement
        FROM ${DbConstants.walletTransfers}
        UNION ALL
        SELECT to_wallet_id AS wallet_id, amount AS movement
        FROM ${DbConstants.walletTransfers}
      ) GROUP BY wallet_id
    ''');
    for (final row in transfers) {
      final id = row['wallet_id']! as int;
      movements[id] =
          (movements[id] ?? 0) + ((row['movement'] as num?)?.toDouble() ?? 0);
    }
    return {
      for (final row in wallets)
        row['id']! as int:
            (row['initial_balance'] as num).toDouble() +
            (movements[row['id']! as int] ?? 0),
    };
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

  Future<int> softDeleteTransaction(int id) async {
    final db = await database;
    return db.update(
      DbConstants.transactions,
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreTransaction(int id) async {
    final db = await database;
    return db.update(
      DbConstants.transactions,
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDeleteTransaction(int id) async {
    final db = await database;
    return db.delete(
      DbConstants.transactions,
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getTrash() async {
    final db = await database;
    final rows = await db.query(
      DbConstants.transactions,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<int> purgeExpiredTrash() async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return db.delete(
      DbConstants.transactions,
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? from,
    DateTime? toExclusive,
    String? category,
  }) async {
    final db = await database;
    final conditions = <String>['deleted_at IS NULL'];
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
      where: conditions.join(' AND '),
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
      WHERE type = 'expense' AND deleted_at IS NULL AND date >= ? AND date < ?
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
      WHERE deleted_at IS NULL AND date >= ?
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

  Future<double> getWeekendExpenseShare({int days = 90}) async {
    final db = await database;
    final from = DateTime.now().subtract(Duration(days: days));
    final rows = await db.rawQuery(
      '''
      SELECT
        SUM(amount) AS total,
        SUM(CASE WHEN strftime('%w', date) IN ('0', '6') THEN amount ELSE 0 END) AS weekend
      FROM ${DbConstants.transactions}
      WHERE type = 'expense' AND deleted_at IS NULL AND date >= ?
      ''',
      [from.toIso8601String()],
    );
    final total = (rows.first['total'] as num?)?.toDouble() ?? 0;
    final weekend = (rows.first['weekend'] as num?)?.toDouble() ?? 0;
    return total <= 0 ? 0 : weekend / total;
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

  Future<List<CategoryModel>> getCustomCategories() async {
    final db = await database;
    final rows = await db.query(
      DbConstants.customCategories,
      orderBy: 'type, name COLLATE NOCASE',
    );
    return rows.map(CategoryModel.fromMap).toList(growable: false);
  }

  Future<int> saveCustomCategory(CategoryModel category) async {
    final db = await database;
    if (category.id == null) {
      return db.insert(
        DbConstants.customCategories,
        category.toMap(includeId: false),
      );
    }
    await db.update(
      DbConstants.customCategories,
      category.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return category.id!;
  }

  Future<void> deleteCustomCategory(int id) async {
    final db = await database;
    await db.delete(
      DbConstants.customCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    final db = await database;
    final rows = await db.query(
      DbConstants.savingsGoals,
      orderBy: 'target_date ASC',
    );
    return rows.map(SavingsGoalModel.fromMap).toList(growable: false);
  }

  Future<int> saveSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    if (goal.id == null) {
      return db.insert(DbConstants.savingsGoals, goal.toMap(includeId: false));
    }
    await db.update(
      DbConstants.savingsGoals,
      goal.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    return goal.id!;
  }

  Future<void> deleteSavingsGoal(int id) async {
    final db = await database;
    await db.delete(DbConstants.savingsGoals, where: 'id = ?', whereArgs: [id]);
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
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DbConstants.transactions} WHERE deleted_at IS NULL',
      ),
    );
    return result ?? 0;
  }

  Future<int> countTransactionsUsingReceiptImage(String path) async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${DbConstants.transactions} WHERE receipt_image_path = ?',
            [path],
          ),
        ) ??
        0;
  }

  Future<Map<String, Object?>> createBackup() async {
    final db = await database;
    return {
      'format': 'pundi-backup',
      'version': 5,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'transactions': await db.query(DbConstants.transactions),
      'budgets': await db.query(DbConstants.budgets),
      'merchant_rules': await db.query(DbConstants.merchantRules),
      'recurring_rules': await db.query(DbConstants.recurringRules),
      'custom_categories': await db.query(DbConstants.customCategories),
      'savings_goals': await db.query(DbConstants.savingsGoals),
      'wallets': await db.query(DbConstants.wallets),
      'wallet_transfers': await db.query(DbConstants.walletTransfers),
    };
  }

  Future<void> restoreBackup(Map<String, Object?> backup) async {
    final version = backup['version'];
    if (backup['format'] != 'pundi-backup' ||
        (version != 1 &&
            version != 2 &&
            version != 3 &&
            version != 4 &&
            version != 5)) {
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
      if (version == 2 || version == 3) {
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
      if (version == 2 || version == 3) {
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
      if (version == 3) {
        await txn.delete(DbConstants.customCategories);
        await txn.delete(DbConstants.savingsGoals);
        await _restoreRows(
          txn,
          DbConstants.customCategories,
          backup['custom_categories'],
        );
        await _restoreRows(
          txn,
          DbConstants.savingsGoals,
          backup['savings_goals'],
        );
      }
      if (version == 4 || version == 5) {
        await txn.delete(DbConstants.wallets);
        await _restoreRows(txn, DbConstants.wallets, backup['wallets']);
        if (Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM ${DbConstants.wallets}'),
            ) ==
            0) {
          await txn.insert(DbConstants.wallets, {
            'id': 1,
            'name': 'Tunai',
            'icon_code': WalletModel.supportedIcons.first.codePoint,
            'color_value': 0xFF6657D9,
            'initial_balance': 0,
            'is_archived': 0,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
      if (version == 5) {
        await txn.delete(DbConstants.walletTransfers);
        await _restoreRows(
          txn,
          DbConstants.walletTransfers,
          backup['wallet_transfers'],
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
