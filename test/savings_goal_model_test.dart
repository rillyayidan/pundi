import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/savings_goal_model.dart';

void main() {
  test('goal progress and remaining are clamped safely', () {
    final goal = SavingsGoalModel(
      name: 'Laptop',
      targetAmount: 10000000,
      currentAmount: 12500000,
      targetDate: DateTime(2027),
      colorValue: 0xFF6657D9,
    );

    expect(goal.progress, 1);
    expect(goal.remaining, 0);
  });

  test('goal round-trips through SQLite map', () {
    final goal = SavingsGoalModel(
      id: 3,
      name: 'Dana darurat',
      targetAmount: 6000000,
      currentAmount: 1500000,
      targetDate: DateTime(2026, 12, 31),
      colorValue: 0xFF218C7A,
      walletId: 2,
      createdAt: DateTime(2026, 7, 13),
    );

    final decoded = SavingsGoalModel.fromMap(goal.toMap());
    expect(decoded.name, goal.name);
    expect(decoded.currentAmount, goal.currentAmount);
    expect(decoded.targetDate, goal.targetDate);
    expect(decoded.walletId, 2);
  });
}
