import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/wallet_transfer_model.dart';

void main() {
  test('wallet transfer round-trips without becoming income or expense', () {
    final transfer = WalletTransferModel(
      id: 4,
      fromWalletId: 1,
      toWalletId: 2,
      amount: 150000,
      date: DateTime(2026, 7, 14),
      note: 'Isi e-wallet',
    );

    final decoded = WalletTransferModel.fromMap(transfer.toMap());
    expect(decoded.fromWalletId, 1);
    expect(decoded.toWalletId, 2);
    expect(decoded.amount, 150000);
    expect(decoded.note, 'Isi e-wallet');
  });
}
