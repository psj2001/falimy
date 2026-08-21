import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/reminders/data/payment_reminder_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PaymentReminderNotifications.instance.init();
  runApp(const ProviderScope(child: FalimyApp()));
}
