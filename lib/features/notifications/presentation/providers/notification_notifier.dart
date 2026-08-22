import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/notifications/data/api_notification_repository.dart';
import 'package:falimy/features/notifications/domain/app_notification.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/reminders/data/payment_reminder_local_store.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, isLoading, error];
}

final notificationRepositoryProvider = Provider<ApiNotificationRepository>((
  ref,
) {
  return ApiNotificationRepository(apiClient: ref.watch(apiClientProvider));
});

class NotificationNotifier extends Notifier<NotificationState> {
  String? _loadedUserId;
  Timer? _pollTimer;

  @override
  NotificationState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId == null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _loadedUserId = null;
      return const NotificationState();
    }
    if (_loadedUserId != userId) {
      _loadedUserId = userId;
      Future.microtask(load);
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => load(silent: true),
      );
      ref.onDispose(() => _pollTimer?.cancel());
    }
    return const NotificationState();
  }

  Future<void> load({bool silent = false}) async {
    if (ref.read(authNotifierProvider).user == null) return;
    if (state.isLoading) return;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final result = await ref.read(notificationRepositoryProvider).list();
      final local = await _localReminderNotifications();
      final hadLinkedIds = state.notifications
          .where((item) => item.type == 'family_linked')
          .map((item) => item.id)
          .toSet();
      final hasNewLink = result.notifications.any(
        (item) =>
            item.type == 'family_linked' && !hadLinkedIds.contains(item.id),
      );
      state = state.copyWith(
        notifications: [...local, ...result.notifications],
        unreadCount:
            result.unreadCount + local.where((item) => !item.isRead).length,
        isLoading: false,
        clearError: true,
      );
      if (hasNewLink) {
        await ref.read(onboardingNotifierProvider.notifier).reload();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: silent
            ? state.error
            : e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markRead(String id) async {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index < 0 || state.notifications[index].isRead) return;
    if (id.startsWith('payrem_')) {
      await PaymentReminderLocalStore().markInboxRead(id);
    } else {
      await ref.read(notificationRepositoryProvider).markRead(id);
    }
    final updated = state.notifications.toList();
    updated[index] = updated[index].copyWith(isRead: true);
    state = state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    final localIds = state.notifications
        .where((item) => item.type == 'payment_reminder' && !item.isRead)
        .map((item) => item.id);
    if (localIds.isNotEmpty) {
      await PaymentReminderLocalStore().markInboxReadAll(localIds);
    }
    final hasRemoteUnread = state.notifications.any(
      (item) => item.type != 'payment_reminder' && !item.isRead,
    );
    if (hasRemoteUnread) {
      await ref.read(notificationRepositoryProvider).markAllRead();
    }
    state = state.copyWith(
      notifications: state.notifications
          .map((item) => item.copyWith(isRead: true))
          .toList(),
      unreadCount: 0,
    );
  }

  Future<List<AppNotification>> _localReminderNotifications() async {
    try {
      final store = PaymentReminderLocalStore();
      final reminders = await store.load();
      final readIds = await store.loadReadInboxIds();
      final items = <AppNotification>[];
      for (final reminder in reminders) {
        if (!reminder.shouldAppearInInbox()) continue;
        items.add(
          _fromReminder(
            reminder,
            readIds.contains(reminder.inboxId),
            ref.read(preferredCurrencyProvider),
          ),
        );
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return const [];
    }
  }
}

AppNotification _fromReminder(
  PaymentReminder reminder,
  bool isRead,
  String currency,
) {
  final due = reminder.displayDueDate();
  final notifyDay = due.subtract(Duration(days: reminder.remindDaysBefore));
  return AppNotification(
    id: reminder.inboxId,
    type: 'payment_reminder',
    title: 'Pay ${reminder.title}',
    message: reminder.inboxMessage(null, currency),
    isRead: isRead,
    createdAt: DateTime(notifyDay.year, notifyDay.month, notifyDay.day, 9),
    data: {'reminderId': reminder.id},
  );
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
