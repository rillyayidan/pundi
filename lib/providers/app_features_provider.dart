import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/recurring_rule_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';

class AppFeaturesProvider extends ChangeNotifier {
  AppFeaturesProvider(
    this._database, {
    NotificationService? notifications,
    SecurityService? security,
  }) : _notifications = notifications ?? NotificationService(),
       _security = security ?? SecurityService();

  final DatabaseHelper _database;
  final NotificationService _notifications;
  final SecurityService _security;

  List<RecurringRuleModel> recurringRules = [];
  List<SavingsGoalModel> savingsGoals = [];
  bool initialized = false;
  bool lockEnabled = false;
  bool locked = false;
  bool notificationsEnabled = false;
  bool securitySupported = false;
  DateTime? lastBackupAt;
  int transactionCountAtBackup = 0;
  int currentTransactionCount = 0;
  String? error;
  bool onboardingSeen = false;

  List<RecurringRuleModel> get dueRules {
    final endToday = DateTime.now().add(const Duration(days: 1));
    return recurringRules
        .where((rule) => rule.isActive && rule.nextDate.isBefore(endToday))
        .toList(growable: false);
  }

  bool get backupReminderNeeded {
    if (currentTransactionCount == 0) return false;
    if (lastBackupAt == null) return currentTransactionCount >= 5;
    return DateTime.now().difference(lastBackupAt!).inDays >= 14 ||
        currentTransactionCount - transactionCountAtBackup >= 10;
  }

  Future<void> initialize() async {
    try {
      await _notifications.initialize();
      securitySupported = await _security.isSupported();
      lockEnabled = await _database.getSetting('app_lock_enabled') == 'true';
      notificationsEnabled =
          await _database.getSetting('notifications_enabled') == 'true';
      onboardingSeen = await _database.getSetting('onboarding_seen') == 'true';
      locked = lockEnabled;
      await refresh();
      if (!onboardingSeen && currentTransactionCount > 0) {
        onboardingSeen = true;
        await _database.setSetting('onboarding_seen', 'true');
      }
    } catch (caught) {
      error = caught.toString();
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    recurringRules = await _database.getRecurringRules();
    savingsGoals = await _database.getSavingsGoals();
    currentTransactionCount = await _database.getTransactionCount();
    final backupValue = await _database.getSetting('last_backup_at');
    lastBackupAt = backupValue == null ? null : DateTime.tryParse(backupValue);
    transactionCountAtBackup =
        int.tryParse(
          await _database.getSetting('backup_transaction_count') ?? '',
        ) ??
        0;
    if (notificationsEnabled) await _rescheduleAll();
    notifyListeners();
  }

  Future<bool> unlock() async {
    if (!lockEnabled) {
      locked = false;
      notifyListeners();
      return true;
    }
    final success = await _security.authenticate();
    if (success) {
      locked = false;
      notifyListeners();
    }
    return success;
  }

  void lock() {
    if (!lockEnabled || locked) return;
    locked = true;
    notifyListeners();
  }

  Future<bool> setLockEnabled(bool value) async {
    if (value == lockEnabled) return true;
    if (!securitySupported) return false;
    if (!await _security.authenticate()) return false;
    lockEnabled = value;
    locked = false;
    await _database.setSetting('app_lock_enabled', value.toString());
    notifyListeners();
    return true;
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    if (value && !await _notifications.requestPermission()) return false;
    notificationsEnabled = value;
    await _database.setSetting('notifications_enabled', value.toString());
    if (value) {
      await _rescheduleAll();
    } else {
      await _notifications.cancelAll();
    }
    notifyListeners();
    return true;
  }

  Future<void> saveRecurringRule(RecurringRuleModel rule) async {
    await _database.saveRecurringRule(rule);
    await refresh();
  }

  Future<void> saveSavingsGoal(SavingsGoalModel goal) async {
    await _database.saveSavingsGoal(goal);
    await refresh();
  }

  Future<void> deleteSavingsGoal(SavingsGoalModel goal) async {
    if (goal.id == null) return;
    await _database.deleteSavingsGoal(goal.id!);
    await refresh();
  }

  Future<void> addGoalContribution(
    SavingsGoalModel goal,
    double amount,
    int fromWalletId,
  ) async {
    if (amount <= 0) return;
    await _database.contributeToSavingsGoal(goal, fromWalletId, amount);
    await refresh();
  }

  Future<void> finishOnboarding({bool addDemoData = false}) async {
    if (addDemoData && await _database.getTransactionCount() == 0) {
      final now = DateTime.now();
      await _database.insertTransactions([
        TransactionModel(
          type: TransactionType.income,
          amount: 5500000,
          category: 'Gaji',
          date: DateTime(now.year, now.month, 1, 9),
          merchant: 'Gaji bulanan',
          note: 'Data contoh — bisa dihapus kapan saja',
        ),
        TransactionModel(
          type: TransactionType.expense,
          amount: 850000,
          category: 'Tagihan',
          date: DateTime(now.year, now.month, 2, 12),
          merchant: 'Kos',
          note: 'Data contoh',
        ),
        TransactionModel(
          type: TransactionType.expense,
          amount: 185000,
          category: 'Makanan',
          date: now.subtract(const Duration(days: 2)),
          merchant: 'Belanja mingguan',
          note: 'Data contoh',
        ),
        TransactionModel(
          type: TransactionType.expense,
          amount: 76000,
          category: 'Transportasi',
          date: now.subtract(const Duration(days: 1)),
          merchant: 'Transport',
          note: 'Data contoh',
        ),
      ]);
    }
    onboardingSeen = true;
    await _database.setSetting('onboarding_seen', 'true');
    await refresh();
    notifyListeners();
  }

  Future<void> deleteRecurringRule(RecurringRuleModel rule) async {
    if (rule.id == null) return;
    await _database.deleteRecurringRule(rule.id!);
    await _notifications.cancelRecurring(rule.id!);
    await refresh();
  }

  Future<void> advanceRecurring(RecurringRuleModel rule) async {
    var next = rule.frequency.nextAfter(rule.nextDate);
    while (!next.isAfter(DateTime.now())) {
      next = rule.frequency.nextAfter(next);
    }
    await _database.saveRecurringRule(rule.copyWith(nextDate: next));
    await refresh();
  }

  Future<void> markBackupCreated() async {
    final now = DateTime.now();
    currentTransactionCount = await _database.getTransactionCount();
    await _database.setSetting('last_backup_at', now.toIso8601String());
    await _database.setSetting(
      'backup_transaction_count',
      currentTransactionCount.toString(),
    );
    lastBackupAt = now;
    transactionCountAtBackup = currentTransactionCount;
    if (notificationsEnabled) {
      await _notifications.scheduleBackup(now.add(const Duration(days: 14)));
    }
    notifyListeners();
  }

  Future<void> _rescheduleAll() async {
    for (final rule in recurringRules) {
      await _notifications.scheduleRecurring(rule);
    }
    final from = lastBackupAt ?? DateTime.now();
    await _notifications.scheduleBackup(from.add(const Duration(days: 14)));
  }
}
