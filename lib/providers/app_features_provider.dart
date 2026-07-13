import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/recurring_rule_model.dart';
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
  bool initialized = false;
  bool lockEnabled = false;
  bool locked = false;
  bool notificationsEnabled = false;
  bool securitySupported = false;
  DateTime? lastBackupAt;
  int transactionCountAtBackup = 0;
  int currentTransactionCount = 0;
  String? error;

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
      locked = lockEnabled;
      await refresh();
    } catch (caught) {
      error = caught.toString();
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    recurringRules = await _database.getRecurringRules();
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
