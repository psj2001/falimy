import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/notifications/data/api_notification_repository.dart';
import 'package:falimy/features/notifications/domain/app_notification.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

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

final notificationRepositoryProvider =
    Provider<ApiNotificationRepository>((ref) {
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
      final hadLinkedIds = state.notifications
          .where((item) => item.type == 'family_linked')
          .map((item) => item.id)
          .toSet();
      final hasNewLink = result.notifications.any(
        (item) => item.type == 'family_linked' && !hadLinkedIds.contains(item.id),
      );
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
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
    await ref.read(notificationRepositoryProvider).markRead(id);
    final updated = state.notifications.toList();
    updated[index] = updated[index].copyWith(isRead: true);
    state = state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    await ref.read(notificationRepositoryProvider).markAllRead();
    state = state.copyWith(
      notifications:
          state.notifications.map((item) => item.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
