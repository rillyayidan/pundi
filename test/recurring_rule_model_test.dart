import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/recurring_rule_model.dart';
import 'package:pundi/models/transaction_model.dart';

void main() {
  test('weekly recurrence advances exactly seven days', () {
    final current = DateTime(2026, 7, 13, 9);
    expect(
      RecurrenceFrequency.weekly.nextAfter(current),
      DateTime(2026, 7, 20, 9),
    );
  });

  test('monthly recurrence clamps to the last valid day', () {
    final current = DateTime(2026, 1, 31, 9);
    expect(
      RecurrenceFrequency.monthly.nextAfter(current),
      DateTime(2026, 2, 28, 9),
    );
  });

  test('recurring rule creates a transaction without auto-saving it', () {
    final rule = RecurringRuleModel(
      type: TransactionType.expense,
      amount: 1500000,
      category: 'Tagihan',
      frequency: RecurrenceFrequency.monthly,
      nextDate: DateTime(2026, 8, 1, 9),
      merchant: 'Kos',
      note: 'Kamar bulanan',
    );

    final transaction = rule.toTransaction(date: DateTime(2026, 8, 1, 10));
    expect(transaction.amount, 1500000);
    expect(transaction.category, 'Tagihan');
    expect(transaction.merchant, 'Kos');
    expect(transaction.date, DateTime(2026, 8, 1, 10));
  });
}
