import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/debt_model.dart';

class DebtProvider extends ChangeNotifier {
  DebtProvider(this._database);
  final DatabaseHelper _database;

  List<DebtModel> debts = [];
  bool loading = false;

  double get totalPayable => debts
      .where((debt) => debt.type == DebtType.payable)
      .fold(0, (sum, debt) => sum + debt.remaining);
  double get totalReceivable => debts
      .where((debt) => debt.type == DebtType.receivable)
      .fold(0, (sum, debt) => sum + debt.remaining);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      debts = await _database.getDebts();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(DebtModel debt) async {
    await _database.saveDebt(debt);
    await load();
  }

  Future<void> delete(DebtModel debt) async {
    if (debt.id == null) return;
    await _database.deleteDebt(debt.id!);
    await load();
  }

  Future<void> recordPayment(DebtModel debt, double amount) async {
    await _database.recordDebtPayment(debt, amount);
    await load();
  }
}
