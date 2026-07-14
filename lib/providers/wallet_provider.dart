import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/wallet_model.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider(this._database);

  final DatabaseHelper _database;
  List<WalletModel> wallets = [];
  Map<int, double> balances = {};
  bool loading = false;
  String? error;

  WalletModel walletFor(int id) => wallets.firstWhere(
    (wallet) => wallet.id == id,
    orElse: () => wallets.isEmpty
        ? const WalletModel(
            id: 1,
            name: 'Tunai',
            iconCode: 0xe8cc,
            colorValue: 0xFF6657D9,
          )
        : wallets.first,
  );

  double balanceFor(int id) => balances[id] ?? 0;
  double get totalBalance =>
      balances.values.fold(0, (sum, value) => sum + value);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      wallets = await _database.getWallets();
      balances = await _database.getWalletBalances();
      error = null;
    } catch (caught) {
      error = caught.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(WalletModel wallet) async {
    await _database.saveWallet(wallet);
    await load();
  }

  Future<void> delete(WalletModel wallet) async {
    if (wallet.id == null) return;
    await _database.deleteWallet(wallet.id!);
    await load();
  }
}
