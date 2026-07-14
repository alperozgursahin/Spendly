import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import 'notification_model.dart';

String _cursorKeyFor(String userId) => 'notification_feature_cutoff_$userId';

final userNotificationsProvider =
    StreamProvider.family<List<AppNotificationModel>, String>((ref, userId) {
      final supabase = Supabase.instance.client;
      return Stream.fromFuture(_loadInitialCursor(userId)).asyncExpand((
        cursor,
      ) {
        return supabase
            .from('group_transactions')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .asyncMap((rows) => _buildNotifications(rows, userId, cursor));
      });
    });

Future<DateTime> _loadInitialCursor(String userId) async {
  const storage = FlutterSecureStorage();
  final storedValue = await storage.read(key: _cursorKeyFor(userId));
  if (storedValue != null) {
    final parsed = DateTime.tryParse(storedValue);
    if (parsed != null) return parsed.toUtc();
  }

  // First-ever check for this user (or the cursor was cleared at logout).
  // Persist "now" so *future* checks only show what's new from here on,
  // but this call must still return everything that already happened —
  // otherwise a share added moments before this first check (which is
  // exactly what a brand-new participant is opening this screen to see)
  // would be stamped as "already seen" and silently never shown.
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
  DateTime cursor,
) async {
  final supabase = Supabase.instance.client;

  final relevantRows = rows.where((row) {
    final createdAt = DateTime.parse(row['created_at'] as String).toUtc();
    if (!createdAt.isAfter(cursor)) return false;

    final splitData = Map<String, dynamic>.from(
      row['split_data'] as Map? ?? {},
    );
    return row['payer_id'] != userId && splitData.containsKey(userId);
  }).toList();

  final groupIds = relevantRows
      .map((row) => row['group_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();
  final payerIds = relevantRows
      .map((row) => row['payer_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final groupNames = <String, String>{};
  for (final groupId in groupIds) {
    final groupRow = await supabase
        .from('groups')
        .select('id, name')
        .eq('id', groupId)
        .maybeSingle();
    if (groupRow != null) {
      groupNames[groupId] = groupRow['name'] as String? ?? 'Bir grup';
    }
  }

  final usernames = <String, String>{};
  for (final payerId in payerIds) {
    final profileRow = await supabase
        .from('profiles')
        .select('id, username')
        .eq('id', payerId)
        .maybeSingle();
    if (profileRow != null) {
      final username = (profileRow['username'] as String?)?.trim();
      usernames[payerId] = (username != null && username.isNotEmpty)
          ? username
          : 'Bir kullanıcı';
    }
  }

  return relevantRows.map((row) {
    final groupId = row['group_id'] as String;
    final payerId = row['payer_id'] as String;
    final description = row['description'] as String? ?? 'harcama';
    final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
    final groupName = groupNames[groupId] ?? 'Bir grup';
    final actorUsername = usernames[payerId] ?? 'Bir kullanıcı';
    final createdAt = DateTime.parse(row['created_at'] as String).toUtc();

    return AppNotificationModel(
      id: '${row['id']}_$userId',
      recipientId: userId,
      actorId: payerId,
      groupId: groupId,
      message:
          '$actorUsername kullanıcısı $groupName grubuna $description harcamasına sizi ekledi. Miktar ${amount.toStringAsFixed(2)} TL. Onayınızı bekliyor.',
      isRead: false,
      createdAt: createdAt,
    );
  }).toList();
}
