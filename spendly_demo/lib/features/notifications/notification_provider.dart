import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_model.dart';

String _cursorKeyFor(String userId) => 'notification_feature_cutoff_$userId';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

final userNotificationsProvider =
    StreamProvider.family<List<AppNotificationModel>, String>((ref, userId) {
      final service = ref.watch(notificationServiceProvider);
      return service.watchNotifications(userId);
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

  final groupNames = <String, String>{};
  for (final row in groupResults) {
    if (row != null) {
      groupNames[row['id'] as String] = row['name'] as String? ?? 'Bir grup';
    }
  }

  final usernames = <String, String>{};
  for (final row in profileResults) {
    if (row == null) continue;

    final username = (row['username'] as String?)?.trim();
    usernames[row['id'] as String] = username == null || username.isEmpty
        ? 'Bir kullanıcı'
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
    final description = expense?['description'] as String? ?? 'harcama';
    final groupName = groupId == null
        ? 'Bir grup'
        : groupNames[groupId] ?? 'Bir grup';
    final senderName = usernames[senderId] ?? 'Bir kullanıcı';

    var title = 'Yeni harcama';
    var message =
        '$senderName sizi $groupName grubundaki "$description" harcamasına ekledi. '
        'Tutar: ${amount.toStringAsFixed(2)} TL. Onayınızı bekliyor.';

    if (type == 'payment_confirmation') {
      title = 'Ödeme bildirildi';
      message =
          '$senderName, $groupName grubundaki "$description" için ödeme '
          'bildirimi gönderdi.';
    } else if (type == 'debt_approved') {
      title = 'Borç onaylandı';
      message =
          '$senderName, $groupName grubundaki "$description" borcunu onayladı.';
    } else if (type == 'debt_rejected') {
      title = 'Borç reddedildi';
      message =
          '$senderName, $groupName grubundaki "$description" borcunu reddetti.';
    } else if (type == 'debt_settled') {
      title = 'Ödeme onaylandı';
      message =
          '$senderName, $groupName grubundaki "$description" için ödemenizi '
          'onayladı. Borç kapandı.';
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

  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .asyncMap(
          (rows) => _buildNotifications(
            rows.map(Map<String, dynamic>.from).toList(),
            userId,
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
