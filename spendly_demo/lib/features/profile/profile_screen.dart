import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/locale_provider.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import 'currency_provider.dart';
import '../transactions/transaction_provider.dart';
import 'services/pdf_export_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Force a fresh fetch whenever this screen mounts so a just-switched
    // account never shows the previous account's cached profile (see
    // GroupDetailScreen/NotificationsScreen for the same pattern).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(currentUserProfileProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final user = ref.watch(currentUserProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'profile_title'))),
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
                      : tr(ref, 'profile_unknown_username'),
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
                  title: Text(tr(ref, 'profile_edit_tile')),
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
                  title: Text(tr(ref, 'profile_currency_tile')),
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
                  title: Text(tr(ref, 'profile_change_password_tile')),
                  onTap: () {
                    context.push('/update-password');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(tr(ref, 'profile_download_report_tile')),
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
                      final language = ref.read(appLanguageProvider);
                      await PdfExportService.generateAndShareMonthlyReport(
                        currentMonthTransactions,
                        '${now.month}/${now.year}',
                        language: language,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(ref, 'profile_pdf_error').replaceFirst(
                              '%s',
                              e.toString(),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(tr(ref, 'profile_logout')),
                ),
                const SizedBox(height: 32),
                Text(
                  tr(ref, 'profile_danger_zone'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    _showDeleteAccountDialog(context, ref);
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: Text(tr(ref, 'profile_delete_account_data')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ref, 'profile_delete_account_title')),
        content: Text(tr(ref, 'profile_delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(ref, 'common_cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
            child: Text(tr(ref, 'common_delete')),
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
              title: Text(tr(ref, 'profile_edit_tile')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'login_username_label'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'register_email_label'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: avatarController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'profile_avatar_url_label'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(tr(ref, 'common_cancel')),
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
                                SnackBar(
                                  content: Text(
                                    tr(ref, 'profile_update_success'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(e)),
                                ),
                              );
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
                      : Text(tr(ref, 'common_save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
