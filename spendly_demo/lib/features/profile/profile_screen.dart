import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import 'currency_provider.dart';
import '../transactions/transaction_provider.dart';
import 'services/pdf_export_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authClientProvider).currentUser;
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        data: (profile) {
          final avatarUrl = profile['avatar_url'] as String?;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile['username'] != null &&
                          profile['username'].toString().isNotEmpty
                      ? '@${profile['username']}'
                      : '@bilinmiyor',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Profili Düzenle'),
                  onTap: () {
                    _showEditProfileDialog(
                      context,
                      ref,
                      profile['username'] ?? '',
                      user?.email ?? '',
                      avatarUrl ?? '',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Para Birimi'),
                  trailing: DropdownButton<String>(
                    value: currency,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '₺', child: Text('₺ (TRY)')),
                      DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                      DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                    ],
                    onChanged: (newCurrency) {
                      if (newCurrency != null) {
                        ref
                            .read(currencyProvider.notifier)
                            .setCurrency(newCurrency);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Şifre Değiştir'),
                  onTap: () {
                    context.push('/update-password');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Aylık Raporu İndir (PDF)'),
                  onTap: () async {
                    try {
                      // Import transactions provider
                      final transactionsAsync = ref.read(
                        transactionsProvider.future,
                      );
                      final transactions = await transactionsAsync;

                      // Filter by current month
                      final now = DateTime.now();
                      final currentMonthTransactions = transactions.where((t) {
                        return t.date.year == now.year &&
                            t.date.month == now.month;
                      }).toList();

                      // Call service
                      await PdfExportService.generateAndShareMonthlyReport(
                        currentMonthTransactions,
                        '${now.month}/${now.year}',
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF Oluşturulamadı: $e')),
                      );
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    _showDeleteAccountDialog(context, ref);
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Hesabı ve Verileri Sil'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut(ref);
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: ')),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı ve tüm verilerini kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut(ref);
              if (!context.mounted) return;
              context.go('/login');
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUsername,
    String currentEmail,
    String currentAvatarUrl,
  ) {
    final usernameController = TextEditingController(text: currentUsername);
    final emailController = TextEditingController(text: currentEmail);
    final avatarController = TextEditingController(text: currentAvatarUrl);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Profili Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı (@username)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: avatarController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL (Opsiyonel)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            await ref
                                .read(socialServiceProvider)
                                .updateProfile(
                                  currentUsername: currentUsername,
                                  newUsername: usernameController.text.trim(),
                                  newEmail: emailController.text.trim(),
                                  avatarUrl: avatarController.text.trim(),
                                );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(currentUserProfileProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profil başarıyla güncellendi.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(
                                ctx,
                              ).showSnackBar(SnackBar(content: Text('Hata: ')));
                            }
                          } finally {
                            if (ctx.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
