import 'package:falimy/core/services/api_client.dart';
import 'package:falimy/features/notifications/domain/app_notification.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
}

class ApiNotificationRepository {
  ApiNotificationRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<NotificationListResult> list() async {
    final json = await _api.getJson('/api/notifications');
    final notifications = <AppNotification>[];
    final raw = json['notifications'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final dataRaw = map['data'];
        notifications.add(
          AppNotification(
            id: (map['id'] as String?) ?? '',
            type: (map['type'] as String?) ?? '',
            title: (map['title'] as String?) ?? 'Notification',
            message: (map['message'] as String?) ?? '',
            isRead: map['isRead'] == true,
            createdAt: DateTime.tryParse(
                  (map['createdAt'] as String?) ?? '',
                ) ??
                DateTime.now(),
            data: dataRaw is Map
                ? Map<String, dynamic>.from(dataRaw)
                : const {},
          ),
        );
      }
    }
    return NotificationListResult(
      notifications: notifications,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markRead(String id) async {
    await _api.patchJson('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.postJson('/api/notifications/read-all');
  }
}
