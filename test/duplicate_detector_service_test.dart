import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/transaction_model.dart';
import 'package:pundi/services/duplicate_detector_service.dart';

void main() {
  const detector = DuplicateDetectorService();
  final base = TransactionModel(
    id: 1,
    type: TransactionType.expense,
    amount: 52500,
    category: 'Makanan',
    walletId: 2,
    merchant: 'Kopi Kenangan',
    date: DateTime(2026, 7, 14, 9),
  );

  test('matches same merchant, amount, wallet, and nearby time', () {
    final candidate = base.copyWith(
      id: 2,
      merchant: 'KOPI-KENANGAN',
      date: DateTime(2026, 7, 14, 20),
    );

    expect(detector.findMatch(candidate, [base]), same(base));
  });

  test('does not match a different wallet or distant date', () {
    expect(
      detector.findMatch(base.copyWith(id: 2, walletId: 3), [base]),
      isNull,
    );
    expect(
      detector.findMatch(base.copyWith(id: 3, date: DateTime(2026, 7, 16, 9)), [
        base,
      ]),
      isNull,
    );
  });

  test('falls back to category for merchant-less nearby entries', () {
    final existing = base.copyWith(id: 5, merchant: null);
    final candidate = existing.copyWith(id: 6, date: DateTime(2026, 7, 14, 10));

    expect(detector.findMatch(candidate, [existing]), same(existing));
  });
}
