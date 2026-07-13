import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/transaction_model.dart';

void main() {
  test('round-trips through the SQLite map shape', () {
    final original = TransactionModel(
      id: 9,
      type: TransactionType.expense,
      amount: 42500,
      category: 'Makanan',
      date: DateTime(2026, 7, 13),
      note: 'Makan siang',
      merchant: 'Warung Ibu',
      createdAt: DateTime(2026, 7, 13, 12),
    );

    final restored = TransactionModel.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.type, original.type);
    expect(restored.amount, original.amount);
    expect(restored.category, original.category);
    expect(restored.merchant, original.merchant);
  });
}
