import 'package:falimy/features/reminders/data/payment_reminder_local_store.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/domain/repositories/payment_reminder_repository.dart';

class LocalPaymentReminderRepository implements PaymentReminderRepository {
  LocalPaymentReminderRepository({PaymentReminderLocalStore? store})
    : _store = store ?? PaymentReminderLocalStore();

  final PaymentReminderLocalStore _store;
  List<PaymentReminder> _cache = const [];

  @override
  Future<List<PaymentReminder>> load() async {
    _cache = await _store.load();
    return _cache;
  }

  @override
  Future<PaymentReminder> upsert(PaymentReminder reminder) async {
    final index = _cache.indexWhere((item) => item.id == reminder.id);
    if (index >= 0) {
      final next = [..._cache];
      next[index] = reminder;
      _cache = next;
    } else {
      _cache = [..._cache, reminder];
    }
    await _store.save(_cache);
    return reminder;
  }

  @override
  Future<void> delete(String id) async {
    _cache = _cache.where((item) => item.id != id).toList();
    await _store.save(_cache);
  }
}
