import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/features/auth/presentation/providers/auth_notifier.dart';
import 'package:falimy/features/auth/presentation/providers/repository_providers.dart';
import 'package:falimy/features/reminders/data/local_payment_reminder_repository.dart';
import 'package:falimy/features/reminders/data/payment_reminder_local_store.dart';
import 'package:falimy/features/reminders/data/payment_reminder_notifications.dart';
import 'package:falimy/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:falimy/features/reminders/data/syncing_payment_reminder_repository.dart';
import 'package:falimy/features/reminders/domain/payment_reminder.dart';
import 'package:falimy/features/reminders/domain/repositories/payment_reminder_repository.dart';

class PaymentReminderState extends Equatable {
  const PaymentReminderState({
    this.reminders = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  final List<PaymentReminder> reminders;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  List<PaymentReminder> upcoming() {
    final list = reminders.where((item) => item.isUpcoming).toList()
      ..sort((a, b) => a.displayDueDate().compareTo(b.displayDueDate()));
    return list;
  }

  List<PaymentReminder> dueSoon() {
    return upcoming()
        .where((item) => item.isDueSoon || item.daysUntilDue() < 0)
        .toList();
  }

  PaymentReminder? next() {
    final list = upcoming();
    return list.isEmpty ? null : list.first;
  }

  PaymentReminder? byId(String id) {
    for (final item in reminders) {
      if (item.id == id) return item;
    }
    return null;
  }

  PaymentReminderState copyWith({
    List<PaymentReminder>? reminders,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return PaymentReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [reminders, isLoading, isSaving, error];
}

final paymentReminderRepositoryProvider = Provider<PaymentReminderRepository>((
  ref,
) {
  final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
  return SyncingPaymentReminderRepository(
    local: LocalPaymentReminderRepository(
      store: PaymentReminderLocalStore(userId: userId),
    ),
    apiClient: ref.watch(apiClientProvider),
  );
});

class PaymentReminderNotifier extends Notifier<PaymentReminderState> {
  @override
  PaymentReminderState build() {
    ref.listen(authNotifierProvider.select((s) => s.user?.id), (previous, next) {
      if (previous != next) Future.microtask(load);
    });
    ref.listen(preferredCurrencyProvider, (previous, next) {
      if (previous != next) {
        Future.microtask(() => _syncNotifications(state.reminders));
      }
    });
    Future.microtask(load);
    return const PaymentReminderState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reminders = await ref
          .read(paymentReminderRepositoryProvider)
          .load();
      state = state.copyWith(reminders: reminders, isLoading: false);
      await _syncNotifications(reminders);
      await ref.read(notificationNotifierProvider.notifier).load(silent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<PaymentReminder?> upsert(PaymentReminder reminder) async {
    if (reminder.title.trim().isEmpty) {
      state = state.copyWith(error: 'Enter what this payment is for');
      return null;
    }
    if (reminder.amount <= 0) {
      state = state.copyWith(error: 'Enter the amount to pay');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await ref
          .read(paymentReminderRepositoryProvider)
          .upsert(reminder);
      final index = state.reminders.indexWhere((item) => item.id == saved.id);
      final next = [...state.reminders];
      if (index >= 0) {
        next[index] = saved;
      } else {
        next.add(saved);
      }
      state = state.copyWith(reminders: next, isSaving: false);
      await _syncNotifications(next);
      await ref.read(notificationNotifierProvider.notifier).load(silent: true);
      return saved;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final removed = state.byId(id);
      await ref.read(paymentReminderRepositoryProvider).delete(id);
      final next = state.reminders.where((item) => item.id != id).toList();
      state = state.copyWith(reminders: next, isSaving: false);
      if (removed != null) {
        await PaymentReminderNotifications.instance.cancel(removed);
      }
      await _syncNotifications(next);
      await ref.read(notificationNotifierProvider.notifier).load(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markPaid(PaymentReminder reminder) async {
    final paid = reminder.copyWith(
      lastPaidOccurrence: reminder.occurrenceKeyFor(reminder.periodDueDate()),
      updatedAt: DateTime.now(),
    );
    return await upsert(paid) != null;
  }

  Future<void> _syncNotifications(List<PaymentReminder> reminders) {
    return PaymentReminderNotifications.instance.sync(
      reminders,
      currency: ref.read(preferredCurrencyProvider),
    );
  }
}

final paymentReminderNotifierProvider =
    NotifierProvider<PaymentReminderNotifier, PaymentReminderState>(
      PaymentReminderNotifier.new,
    );
