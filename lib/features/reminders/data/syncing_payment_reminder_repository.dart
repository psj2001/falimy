import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/core/sync/sync_merge.dart';
import 'package:falimy/features/reminders/data/local_payment_reminder_repository.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/domain/repositories/payment_reminder_repository.dart';

class SyncingPaymentReminderRepository implements PaymentReminderRepository {
  SyncingPaymentReminderRepository({
    required LocalPaymentReminderRepository local,
    required ApiClient apiClient,
  })  : _local = local,
        _api = apiClient;

  final LocalPaymentReminderRepository _local;
  final ApiClient _api;

  @override
  Future<List<PaymentReminder>> load() async {
    final local = await _local.load();
    try {
      final remote = await _fetchAll();
      final merged = mergeByUpdatedAt(
        local: local,
        remote: remote,
        idOf: (item) => item.id,
        updatedAtOf: (item) => item.updatedAt,
      );
      await _local.replaceAll(merged);

      final remoteById = {for (final item in remote) item.id: item};
      for (final reminder in merged) {
        final remoteItem = remoteById[reminder.id];
        if (remoteItem == null || reminder.updatedAt.isAfter(remoteItem.updatedAt)) {
          await _push(reminder);
        }
      }
      return merged;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<PaymentReminder> upsert(PaymentReminder reminder) async {
    final saved = await _local.upsert(reminder);
    try {
      await _push(saved);
    } catch (_) {}
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    try {
      await _api.delete('/api/reminders/$id');
    } catch (_) {}
  }

  Future<List<PaymentReminder>> _fetchAll() async {
    final json = await _api.getJson('/api/reminders');
    final raw = json['reminders'];
    if (raw is! List) return const [];
    return raw
        .map(asJsonMap)
        .whereType<Map<String, dynamic>>()
        .map(PaymentReminder.fromJson)
        .toList();
  }

  Future<void> _push(PaymentReminder reminder) async {
    await _api.putJson('/api/reminders/${reminder.id}', {
      'reminder': reminder.toJson(),
    });
  }
}
