import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authClientProvider).currentUser?.id;
    final notificationsAsync = userId == null
        ? const AsyncValue<List<dynamic>>.data([])
        : ref.watch(userNotificationsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: userId == null
          ? const Center(child: Text('Bildirimleri görmek için giriş yapın.'))
          : notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('Henüz bildiriminiz yok.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notification.isRead
                              ? Colors.grey.shade300
                              : Colors.deepPurple.shade100,
                          child: Icon(
                            notification.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: notification.isRead
                                ? Colors.grey.shade700
                                : Colors.deepPurple,
                          ),
                        ),
                        title: Text(notification.message),
                        subtitle: Text(_formatDate(notification.createdAt)),
                        trailing: const Icon(Icons.fiber_manual_record, size: 10),
                        onTap: null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Hata: $error')),
            ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}