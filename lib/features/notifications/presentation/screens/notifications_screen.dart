import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/features/notifications/domain/app_notification.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:falimy/features/reminders/presentation/providers/payment_reminder_notifier.dart';
import 'package:falimy/features/reminders/presentation/screens/payment_reminders_screen.dart';
import 'package:falimy/features/reminders/presentation/widgets/payment_status_prompt.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: FalimyTheme.cream,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => notifier.load(),
            child: _body(context, ref, state, notifier),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    NotificationNotifier notifier,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Center(child: Text(state.error!)),
        ],
      );
    }
    if (state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          const Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: FalimyTheme.muted,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = state.notifications[index];
        return _NotificationCard(
          notification: item,
          onTap: () async {
            await notifier.markRead(item.id);
            if (item.type != 'payment_reminder' || !context.mounted) return;
            final reminderId = item.data['reminderId'] as String?;
            final reminder = reminderId == null
                ? null
                : ref.read(paymentReminderNotifierProvider).byId(reminderId);
            if (reminder != null && reminder.needsPaymentPrompt) {
              await promptPaymentReminderStatus(context, ref, reminder);
              return;
            }
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentRemindersScreen()),
            );
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      'family_invite' => Icons.mail_outline_rounded,
      'payment_reminder' => Icons.notifications_active_outlined,
      'admin' => Icons.campaign_outlined,
      _ => Icons.family_restroom_rounded,
    };

    return Material(
      color: notification.isRead
          ? Colors.white.withValues(alpha: 0.75)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: FalimyTheme.seed.withValues(alpha: 0.14),
                foregroundColor: FalimyTheme.seed,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: FalimyTheme.seed,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        notification.createdAt,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: FalimyTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
