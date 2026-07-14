import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/debt_model.dart';

void main() {
  test('debt progress and remaining reflect payments', () {
    final debt = DebtModel(
      id: 1,
      type: DebtType.payable,
      person: 'Koperasi',
      totalAmount: 1000000,
      paidAmount: 250000,
      dueDate: DateTime(2026, 12, 1),
      walletId: 2,
    );

    expect(debt.remaining, 750000);
    expect(debt.progress, .25);
    expect(debt.isPaid, isFalse);
    expect(DebtModel.fromMap(debt.toMap()).walletId, 2);
  });
}
