import 'package:falimy/features/reminders/domain/payment_reminder.dart';

abstract class PaymentReminderRepository {
  Future<List<PaymentReminder>> load();

  Future<PaymentReminder> upsert(PaymentReminder reminder);

  Future<void> delete(String id);
}
