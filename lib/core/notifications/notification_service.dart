import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/cards/domain/entities/payment_card.dart';
import '../storage/secure_card_storage.dart';

/// Action ids carried on the reminder notification.
const String kActionPaid = 'cv_paid';
const String kActionSnooze = 'cv_snooze';
const String kActionSkip = 'cv_skip';

/// Entry point Android calls when a notification button is tapped while the app
/// is not running. It executes in a fresh background isolate, so nothing from
/// the running app — BLoCs, DI, the open vault — is reachable here.
///
/// Must stay top-level and keep the `vm:entry-point` pragma, otherwise release
/// builds tree-shake it away and every button silently does nothing.
@pragma('vm:entry-point')
Future<void> notificationActionBackgroundHandler(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.instance.handleAction(response);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'card_due_reminder';
  static const _channelName = 'Card Payment Reminders';
  static const _channelDesc =
      'Reminders before your credit card payment due date';

  /// Reminders arrive in the evening, when people are home and actually able
  /// to pay a bill, rather than mid-morning when the nudge gets dismissed.
  static const _reminderHour = 21; // 9 PM

  /// Emits a card id whenever an action has been applied, so a running app can
  /// refresh instead of showing stale paid state. Only ever has listeners in
  /// the UI isolate; in the background isolate this is a harmless no-op.
  final _actionApplied = StreamController<String>.broadcast();
  Stream<String> get onActionApplied => _actionApplied.stream;

  bool _ready = false;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_ready) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Not const: DarwinNotificationAction.plain is a factory constructor.
    // Permissions are deliberately NOT requested here — see [ensurePermission].
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _channelId,
          actions: [
            DarwinNotificationAction.plain(kActionPaid, 'Paid'),
            DarwinNotificationAction.plain(kActionSnooze, 'Snooze'),
            DarwinNotificationAction.plain(kActionSkip, 'Skip'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackgroundHandler,
    );
    _ready = true;
  }

  // ── Permission ────────────────────────────────────────────────────────────

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Whether the OS currently lets this app show notifications.
  Future<bool> areNotificationsEnabled() async {
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Asks for notification permission unless it is already granted.
  ///
  /// Runs when a reminder is first scheduled, not at app launch: a prompt shown
  /// before the user has seen the app is refused far more often, and on Android
  /// that refusal is effectively permanent.
  Future<bool> ensurePermission() async {
    final android = _android;
    if (android != null) {
      if (await android.areNotificationsEnabled() ?? false) return true;
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
  }

  // ── Schedule reminders for a card ─────────────────────────────────────────

  // Reminder window: from 3 days before through 1 day after the due date.
  // Positive = days before due, negative = days after (overdue).
  static const _reminderOffsets = <int>[3, 2, 1, 0, -1];

  /// Slot reserved for a snoozed reminder, kept clear of the five scheduled
  /// ones so a snooze never overwrites a real reminder.
  static const _snoozeSlot = 5;

  Future<void> scheduleCardReminders(PaymentCard card) async {
    if (card.dueDay == null) return;
    // The user has just asked to be reminded, so this is the moment the
    // permission request makes sense to them.
    await ensurePermission();
    await cancelCardReminders(card.id);
    await _scheduleAround(
      cardId: card.id,
      title: card.displayTitle,
      dueDay: card.dueDay!,
      dueDate: _nextDueDate(card.dueDay!),
      dueDayLabel: card.dueDayLabel,
    );
  }

  /// Adds one extra nudge for tomorrow evening, on top of whatever's already
  /// scheduled — the Reminders list's "Snooze" button on a card that isn't
  /// due soon yet.
  ///
  /// Distinct from [_applySnooze]: that one runs when a reminder that has
  /// already fired gets tapped, and its copy ("you snoozed this yesterday")
  /// assumes that context. This is requested proactively, days or weeks
  /// before the due date, so it needs its own message and must not cancel
  /// any of the real due-date reminders the way [_applySnooze] does.
  Future<void> snoozeFromList(PaymentCard card) async {
    if (card.dueDay == null) return;
    await ensurePermission();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, _reminderHour);
    final label = card.dueDayLabel;

    await _schedule(
      id: _notifId(card.id, _snoozeSlot),
      title: '💳 ${card.displayTitle} payment reminder',
      body: label.isEmpty
          ? 'A quick nudge, as requested.'
          : 'A quick nudge, as requested — due on the $label.',
      scheduledAt: tomorrow,
      payload: jsonEncode({
        'id': card.id,
        'title': card.displayTitle,
        'dueDay': card.dueDay,
        'label': label,
      }),
    );
  }

  /// Cancel current-cycle reminders and reschedule for next month — used when
  /// the user marks a card paid, so they aren't nudged again this cycle.
  Future<void> rescheduleForNextMonth(PaymentCard card) async {
    if (card.dueDay == null) return;
    await _rescheduleNextMonth(
      cardId: card.id,
      title: card.displayTitle,
      dueDay: card.dueDay!,
      dueDayLabel: card.dueDayLabel,
    );
  }

  Future<void> _rescheduleNextMonth({
    required String cardId,
    required String title,
    required int dueDay,
    required String dueDayLabel,
  }) async {
    await cancelCardReminders(cardId);
    final now = DateTime.now();
    final forcedNextDue = DateTime(
      now.year,
      now.month + 1,
      _clampDay(now.year, now.month + 1, dueDay),
    );
    await _scheduleAround(
      cardId: cardId,
      title: title,
      dueDay: dueDay,
      dueDate: forcedNextDue,
      dueDayLabel: dueDayLabel,
    );
  }

  /// Schedules the full reminder window around a concrete [dueDate].
  Future<void> _scheduleAround({
    required String cardId,
    required String title,
    required int dueDay,
    required DateTime dueDate,
    required String dueDayLabel,
  }) async {
    final payload = jsonEncode({
      'id': cardId,
      'title': title,
      'dueDay': dueDay,
      'label': dueDayLabel,
    });

    for (int i = 0; i < _reminderOffsets.length; i++) {
      final offset = _reminderOffsets[i];
      // [offset] days BEFORE the due date (a negative offset ⇒ after it).
      final notifDate = dueDate.subtract(Duration(days: offset));
      final notifAt = DateTime(
        notifDate.year,
        notifDate.month,
        notifDate.day,
        _reminderHour,
      );

      if (notifAt.isAfter(DateTime.now())) {
        await _schedule(
          id: _notifId(cardId, i),
          title: offset < 0
              ? '⚠️ $title payment overdue'
              : '💳 $title payment ${_offsetLabel(offset)}',
          body: _body(title, offset, dueDayLabel),
          scheduledAt: notifAt,
          payload: payload,
        );
      }
    }
  }

  String _offsetLabel(int offset) => switch (offset) {
        3 => 'due in 3 days',
        2 => 'due in 2 days',
        1 => 'due tomorrow',
        0 => 'due TODAY',
        _ => 'overdue',
      };

  String _body(String name, int offset, String dueLabel) {
    if (offset == 0) {
      return 'Your $name bill is due today. Mark it paid, or snooze to tomorrow.';
    }
    if (offset < 0) {
      return 'Your $name bill was due on the $dueLabel and is now overdue.';
    }
    return 'Your $name bill is ${_offsetLabel(offset)}. Due on the $dueLabel.';
  }

  Future<void> cancelCardReminders(String cardId) async {
    // Includes the snooze slot, so a cancelled card leaves nothing behind.
    for (int i = 0; i <= _snoozeSlot; i++) {
      await _plugin.cancel(_notifId(cardId, i));
    }
  }

  // ── Acting on a notification button ───────────────────────────────────────

  /// Applies Paid / Snooze / Skip. Runs in the UI isolate when the app is open
  /// and in a background isolate when it isn't, so it must depend on nothing
  /// but the payload and SharedPreferences.
  Future<void> handleAction(NotificationResponse response) async {
    final action = response.actionId;
    final raw = response.payload;
    if (action == null || raw == null || raw.isEmpty) return;

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // Malformed payload — nothing safe to do.
    }

    final cardId = data['id'] as String?;
    final title = data['title'] as String? ?? 'Card';
    final dueDay = data['dueDay'] as int?;
    final label = data['label'] as String? ?? '';
    if (cardId == null || dueDay == null) return;

    // The background isolate starts with an uninitialised plugin.
    await initialize();

    switch (action) {
      case kActionPaid:
        await _applyPaid(cardId, title, dueDay, label);
      case kActionSnooze:
        await _applySnooze(cardId, title, dueDay, label);
      case kActionSkip:
        await _applySkip(cardId);
      default:
        return;
    }

    if (!_actionApplied.isClosed) _actionApplied.add(cardId);
  }

  /// Records the payment against the cycle it covers and rolls the reminders
  /// forward a month — the same thing the in-app swipe does, written straight
  /// to storage because no BLoC exists in this isolate.
  Future<void> _applyPaid(
    String cardId,
    String title,
    int dueDay,
    String label,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // reload(): the UI isolate may hold a newer copy than this one was born with.
    await prefs.reload();

    final map = _readPaidMap(prefs);
    map[cardId] = PaymentCard.nextDueDateFor(dueDay);
    await prefs.setString(
      SecureCardStorage.paidMapKey,
      jsonEncode(map.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );

    await _rescheduleNextMonth(
      cardId: cardId,
      title: title,
      dueDay: dueDay,
      dueDayLabel: label,
    );
  }

  /// Pushes the nudge to tomorrow evening, replacing any regular reminder that
  /// would already land then so the user never gets two for one bill.
  Future<void> _applySnooze(
    String cardId,
    String title,
    int dueDay,
    String label,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dueDate = _nextDueDate(dueDay);

    for (int i = 0; i < _reminderOffsets.length; i++) {
      final fires = dueDate.subtract(Duration(days: _reminderOffsets[i]));
      if (fires.year == tomorrow.year &&
          fires.month == tomorrow.month &&
          fires.day == tomorrow.day) {
        await _plugin.cancel(_notifId(cardId, i));
      }
    }

    await _schedule(
      id: _notifId(cardId, _snoozeSlot),
      title: '💳 $title payment reminder',
      body: label.isEmpty
          ? 'You snoozed this yesterday.'
          : 'You snoozed this yesterday — due on the $label.',
      scheduledAt: DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        _reminderHour,
      ),
      payload: jsonEncode({
        'id': cardId,
        'title': title,
        'dueDay': dueDay,
        'label': label,
      }),
    );
  }

  /// Stops the run-up nudges but leaves the due-date and overdue reminders
  /// alone — "stop reminding me early", not "stop reminding me".
  Future<void> _applySkip(String cardId) async {
    for (int i = 0; i < _reminderOffsets.length; i++) {
      if (_reminderOffsets[i] > 0) {
        await _plugin.cancel(_notifId(cardId, i));
      }
    }
    await _plugin.cancel(_notifId(cardId, _snoozeSlot));
  }

  Map<String, DateTime> _readPaidMap(SharedPreferences prefs) {
    final raw = prefs.getString(SecureCardStorage.paidMapKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
    } catch (_) {
      return {};
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
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
          actions: const [
            AndroidNotificationAction(
              kActionPaid,
              'Paid',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              kActionSnooze,
              'Snooze',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              kActionSkip,
              'Skip',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _channelId,
        ),
      ),
      payload: payload,
      // Inexact on purpose. A bill reminder does not need second precision, so
      // Android is free to batch it with other wakeups — kinder to battery, and
      // it avoids the exact-alarm permission Google reserves for alarm clocks
      // and calendars.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  DateTime _nextDueDate(int dueDay) => PaymentCard.nextDueDateFor(dueDay);

  int _notifId(String cardId, int slot) =>
      (cardId.hashCode.abs() % 100000) * 10 + slot;
}
