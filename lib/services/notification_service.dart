import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/recurring_rule_model.dart';
import '../utils/currency_formatter.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static final ValueNotifier<String?> tappedPayload = ValueNotifier(null);
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        tappedPayload.value = response.payload;
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      tappedPayload.value = launch?.notificationResponse?.payload;
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> scheduleRecurring(RecurringRuleModel rule) async {
    if (rule.id == null || !rule.isActive) return;
    await initialize();
    await _plugin.cancel(id: _recurringId(rule.id!));
    var date = rule.nextDate;
    final now = DateTime.now();
    if (!date.isAfter(now)) {
      date = now.add(const Duration(minutes: 1));
    }
    await _plugin.zonedSchedule(
      id: _recurringId(rule.id!),
      title: 'Transaksi rutin menunggu',
      body:
          '${rule.merchant ?? rule.category} ${formatRupiah(rule.amount)} siap dikonfirmasi.',
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pundi_recurring',
          'Transaksi berulang',
          channelDescription:
              'Pengingat transaksi rutin yang perlu dikonfirmasi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'recurring:${rule.id}',
    );
  }

  Future<void> cancelRecurring(int id) => _plugin.cancel(id: _recurringId(id));

  Future<void> scheduleBackup(DateTime date) async {
    await initialize();
    await _plugin.cancel(id: 9001);
    final scheduled = date.isAfter(DateTime.now())
        ? date
        : DateTime.now().add(const Duration(minutes: 2));
    await _plugin.zonedSchedule(
      id: 9001,
      title: 'Saatnya cadangkan Pundi',
      body: 'Simpan cadangan JSON agar data keuanganmu tidak hilang.',
      scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pundi_backup',
          'Pengingat cadangan',
          channelDescription: 'Pengingat berkala untuk membuat cadangan lokal',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'backup',
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  int _recurringId(int id) => 10000 + id;
}
