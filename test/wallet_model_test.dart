import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pundi/models/wallet_model.dart';

void main() {
  test('wallet round-trips through SQLite map', () {
    final wallet = WalletModel(
      id: 2,
      name: 'Bank',
      iconCode: Icons.account_balance_rounded.codePoint,
      colorValue: 0xFF3B82F6,
      initialBalance: 250000,
      createdAt: DateTime(2026, 7, 14),
    );

    final decoded = WalletModel.fromMap(wallet.toMap());
    expect(decoded.id, 2);
    expect(decoded.name, 'Bank');
    expect(decoded.initialBalance, 250000);
    expect(decoded.icon, Icons.account_balance_rounded);
  });
}
