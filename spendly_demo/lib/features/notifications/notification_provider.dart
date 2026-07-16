import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_strings.dart';
import '../../core/locale_provider.dart';
import 'notification_model.dart';

String _cursorKeyFor(String userId) => 'notification_feature_cutoff_$userId';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

final userNotificationsProvider =
    StreamProvider.family<List<AppNotificationModel>, String>((ref, userId) {
      final service = ref.watch(notificationServiceProvider);
      final language = ref.watch(appLanguageProvider);
      return service.watchNotifications(userId, language);
    });

final unreadNotificationCountProvider = Provider.family<int, String>((
  ref,
  userId,
) {
  final notifications = ref.watch(userNotificationsProvider(userId));

  return notifications.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});

Future<DateTime> loadInitialNotificationCursor(String userId) async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _cursorKeyFor(userId));

  if (value != null) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }

  await storage.write(
    key: _cursorKeyFor(userId),
    value: DateTime.now().toUtc().toIso8601String(),
  );

  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

class NotificationCursorStorage {
  static Future<void> clearCursor(String userId) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _cursorKeyFor(userId));
  }
}

Future<List<AppNotificationModel>> _buildNotifications(
  List<Map<String, dynamic>> rows,
  String userId,
  AppLanguage language,
) async {
  final supabase = Supabase.instance.client;

  final expenseIds = rows
      .map((row) => row['expense_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final groupIds = rows
      .map((row) => row['group_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final senderIds = rows
      .map((row) => row['sender_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final expenseResults = await Future.wait(
    expenseIds.map(
      (id) => supabase
          .from('group_transactions')
          .select('id, group_id, payer_id, amount, description, created_at')
          .eq('id', id)
          .maybeSingle(),
    ),
  );

  final groupResults = await Future.wait(
    groupIds.map(
      (id) =>
          supabase.from('groups').select('id, name').eq('id', id).maybeSingle(),
    ),
  );

  final profileResults = await Future.wait(
    senderIds.map(
      (id) => supabase
          .from('profiles')
          .select('id, username')
          .eq('id', id)
          .maybeSingle(),
    ),
  );

  final expenses = <String, Map<String, dynamic>>{};
  for (final row in expenseResults) {
    if (row != null) expenses[row['id'] as String] = row;
  }

  final defaultGroupName = AppStrings.of('notif_default_group', language);
  final defaultUserName = AppStrings.of('notif_default_user', language);

  final groupNames = <String, String>{};
  for (final row in groupResults) {
    if (row != null) {
      groupNames[row['id'] as String] =
          row['name'] as String? ?? defaultGroupName;
    }
  }

  final usernames = <String, String>{};
  for (final row in profileResults) {
    if (row == null) continue;

    final username = (row['username'] as String?)?.trim();
    usernames[row['id'] as String] = username == null || username.isEmpty
        ? defaultUserName
        : username;
  }

  return rows.map((row) {
    final notificationId = row['id'] as String;
    final expenseId = row['expense_id'] as String?;
    final expense = expenseId == null ? null : expenses[expenseId];

    final groupId =
        (row['group_id'] as String?) ?? (expense?['group_id'] as String?);
    final senderId = row['sender_id'] as String;
    final type = (row['type'] as String?) ?? 'debt_request';
    final amount = (expense?['amount'] as num?)?.toDouble() ?? 0;
    final defaultDescription = AppStrings.of(
      'notif_default_expense_desc',
      language,
    );
    final description = expense?['description'] as String? ?? defaultDescription;
    final groupName = groupId == null
        ? defaultGroupName
        : groupNames[groupId] ?? defaultGroupName;
    final senderName = usernames[senderId] ?? defaultUserName;

    String fillTemplate(String key) {
      return AppStrings.of(key, language)
          .replaceAll('{sender}', senderName)
          .replaceAll('{group}', groupName)
          .replaceAll('{desc}', description)
          .replaceAll('{amount}', amount.toStringAsFixed(2));
    }

    var title = AppStrings.of('notif_new_expense_title', language);
    var message = fillTemplate('notif_new_expense_message');

    if (type == 'payment_confirmation') {
      title = AppStrings.of('notif_payment_confirmation_title', language);
      message = fillTemplate('notif_payment_confirmation_message');
    } else if (type == 'debt_approved') {
      title = AppStrings.of('notif_debt_approved_title', language);
      message = fillTemplate('notif_debt_approved_message');
    } else if (type == 'debt_rejected') {
      title = AppStrings.of('notif_debt_rejected_title', language);
      message = fillTemplate('notif_debt_rejected_message');
    } else if (type == 'debt_settled') {
      title = AppStrings.of('notif_debt_settled_title', language);
      message = fillTemplate('notif_debt_settled_message');
    }

    return AppNotificationModel(
      // This must be the real UUID. Do not append userId here.
      id: notificationId,
      recipientId: userId,
      senderId: senderId,
      groupId: groupId,
      expenseId: expenseId,
      type: type,
      title: title,
      message: message,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    );
  }).toList();
}

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  Stream<List<AppNotificationModel>> watchNotifications(
    String userId,
    AppLanguage language,
  ) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .asyncMap(
          (rows) => _buildNotifications(
            rows.map(Map<String, dynamic>.from).toList(),
            userId,
            language,
          ),
        );
  }

  Future<void> markAsRead({
    required String notificationId,
    required String recipientId,
  }) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('recipient_id', recipientId);
  }

  Future<void> markNotificationsAsRead() {
    return _supabase.rpc('mark_notifications_read');
  }
}
