import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:falimy/features/reminders/domain/payment_reminder.dart';

class PaymentReminderNotifications {
  PaymentReminderNotifications._();

  static final PaymentReminderNotifications instance =
      PaymentReminderNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const _channelId = 'pay_reminders';
  static const _channelName = 'Payment reminders';
  static const _channelDescription =
      'Alerts before family bills and monthly expenses are due';

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notify'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return granted ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted =
          await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          await macos?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  Future<void> sync(List<PaymentReminder> reminders, {String? currency}) async {
    await init();
    if (!_ready) return;

    for (final reminder in reminders) {
      await _plugin.cancel(reminder.notificationId);
      final when = reminder.scheduleAt();
      if (when == null) continue;
      try {
        await _schedule(reminder, when, currency: currency);
      } catch (_) {}
    }
  }

  Future<void> cancel(PaymentReminder reminder) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(reminder.notificationId);
    } catch (_) {}
  }

  Future<void> _schedule(
    PaymentReminder reminder,
    DateTime when, {
    String? currency,
  }) async {
    final scheduled = tz.TZDateTime(
      tz.local,
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;

    final days = reminder.daysUntilDue();
    final whenDue = days <= 0
        ? 'today'
        : days == 1
        ? 'tomorrow'
        : 'in $days days';

    await _plugin.zonedSchedule(
      reminder.notificationId,
      'Pay ${reminder.title}',
      '${reminder.amountLabel(currency)} is due $whenDue. Open Falimy to log it.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notify',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.id,
    );
  }
}
