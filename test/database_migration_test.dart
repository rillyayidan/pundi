import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/database/database_helper.dart';
import 'package:pundi/database/db_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  });

  tearDown(() => database.close());

  test(
    'fresh schema contains every current table and default wallet',
    () async {
      await DatabaseHelper.instance.createSchemaForTest(database);

      final rows = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tables = rows.map((item) => item['name']).toSet();
      expect(
        tables,
        containsAll([
          DbConstants.transactions,
          DbConstants.budgets,
          DbConstants.recurringRules,
          DbConstants.customCategories,
          DbConstants.savingsGoals,
          DbConstants.wallets,
          DbConstants.walletTransfers,
          DbConstants.debts,
        ]),
      );
      final wallets = await database.query(DbConstants.wallets);
      expect(wallets, hasLength(1));
      expect(wallets.single['name'], 'Tunai');
    },
  );

  test(
    'version 3 data migrates through version 8 without duplicate columns',
    () async {
      await database.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        merchant TEXT,
        receipt_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');
      await database.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        next_date TEXT NOT NULL,
        merchant TEXT,
        note TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
      await database.insert(DbConstants.transactions, {
        'type': 'expense',
        'amount': 15000,
        'category': 'Makanan',
        'date': '2026-07-14T12:00:00.000',
        'note': 'data lama',
        'created_at': '2026-07-14T12:00:00.000',
      });

      await DatabaseHelper.instance.migrateForTest(database, 3);

      expect(
        await _columnNames(database, DbConstants.transactions),
        containsAll(['receipt_image_path', 'deleted_at', 'wallet_id']),
      );
      expect(
        await _columnNames(database, DbConstants.recurringRules),
        contains('wallet_id'),
      );
      expect(
        await _columnNames(database, DbConstants.savingsGoals),
        contains('wallet_id'),
      );
      final migrated = await database.query(DbConstants.transactions);
      expect(migrated.single['note'], 'data lama');
      expect(migrated.single['wallet_id'], 1);
    },
  );
}

Future<Set<Object?>> _columnNames(Database database, String table) async =>
    (await database.rawQuery(
      'PRAGMA table_info($table)',
    )).map((item) => item['name']).toSet();
