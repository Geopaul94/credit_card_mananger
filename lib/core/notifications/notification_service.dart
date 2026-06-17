import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/cards/domain/entities/payment_card.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'card_due_reminder';
  static const _channelName = 'Card Payment Reminders';
  static const _channelDesc =
      'Reminders before your credit card payment due date';

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule reminders for a card ─────────────────────────────────────────

  Future<void> scheduleCardReminders(PaymentCard card) async {
    if (card.dueDay == null) return;
    await cancelCardReminders(card.id); // clear any stale ones first

    final nextDue = _nextDueDate(card.dueDay!);
    final name = card.bankName ?? '${card.typeLabel} Card';

    // Schedule for 3, 2, 1 days before and on the due date
    final schedule = {
      3: 'due in 3 days',
      2: 'due in 2 days',
      1: 'due tomorrow',
      0: 'due TODAY',
    };

    for (final entry in schedule.entries) {
      final notifDate = nextDue.subtract(Duration(days: entry.key));
      final notifAt = DateTime(
          notifDate.year, notifDate.month, notifDate.day, 9, 0);

      if (notifAt.isAfter(DateTime.now())) {
        await _schedule(
          id: _notifId(card.id, entry.key),
          title: '💳 $name payment ${entry.value}',
          body: entry.key == 0
              ? 'Your $name bill is due today. Tap to mark as paid.'
              : 'Your $name bill is ${entry.value}. Due on ${card.dueDayLabel} of this month.',
          scheduledAt: notifAt,
        );
      }
    }
  }

  /// Cancel current-month reminders and reschedule for next month.
  Future<void> rescheduleForNextMonth(PaymentCard card) async {
    if (card.dueDay == null) return;
    await cancelCardReminders(card.id);

    // Force next month by pushing dueDay past current month
    final now = DateTime.now();
    final forcedNextDue = DateTime(
        now.year, now.month + 1, _clampDay(now.year, now.month + 1, card.dueDay!));
    final name = card.bankName ?? '${card.typeLabel} Card';

    final schedule = {3: 'due in 3 days', 2: 'due in 2 days', 1: 'due tomorrow', 0: 'due TODAY'};

    for (final entry in schedule.entries) {
      final notifDate = forcedNextDue.subtract(Duration(days: entry.key));
      final notifAt = DateTime(
          notifDate.year, notifDate.month, notifDate.day, 9, 0);

      if (notifAt.isAfter(DateTime.now())) {
        await _schedule(
          id: _notifId(card.id, entry.key),
          title: '💳 $name payment ${entry.value}',
          body: entry.key == 0
              ? 'Your $name bill is due today. Tap to mark as paid.'
              : 'Your $name bill is ${entry.value}. Due on ${card.dueDayLabel}.',
          scheduledAt: notifAt,
        );
      }
    }
  }

  Future<void> cancelCardReminders(String cardId) async {
    for (int i = 0; i <= 3; i++) {
      await _plugin.cancel(_notifId(cardId, i));
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Clamps [dueDay] to the last valid day of the given month so a due day of
  /// 31 maps to Feb 28/29 (or the 30th of a 30-day month) instead of silently
  /// rolling into the following month.
  int _clampDay(int year, int month, int dueDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return dueDay > lastDay ? lastDay : dueDay;
  }

  DateTime _nextDueDate(int dueDay) {
    final now = DateTime.now();
    final thisMonth =
        DateTime(now.year, now.month, _clampDay(now.year, now.month, dueDay));
    if (thisMonth.isBefore(DateTime(now.year, now.month, now.day))) {
      return DateTime(
          now.year, now.month + 1, _clampDay(now.year, now.month + 1, dueDay));
    }
    return thisMonth;
  }

  int _notifId(String cardId, int daysBefore) =>
      (cardId.hashCode.abs() % 100000) * 10 + daysBefore;
}
