import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme_provider.dart';
import '../../core/friendly_error.dart';
import '../../core/locale_provider.dart';
import '../../core/media_upload_service.dart';
import '../../core/splixa_design.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import '../subscriptions/premium_provider.dart';
import '../transactions/transaction_provider.dart';
import 'currency_provider.dart';
import 'services/pdf_export_service.dart';

class SplixaProfileScreen extends ConsumerStatefulWidget {
  const SplixaProfileScreen({super.key});

  @override
  ConsumerState<SplixaProfileScreen> createState() =>
      _SplixaProfileScreenState();
}

class _SplixaProfileScreenState extends ConsumerState<SplixaProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(currentUserProfileProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        data: (data) => _ProfileContent(profile: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(friendlyErrorMessage(error))),
      ),
    );
  }
}

class _MembershipBadge extends ConsumerWidget {
  const _MembershipBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isPremium
        ? const Color(0xFFFFE08A)
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isPremium
        ? const Color(0xFF6D4800)
        : colorScheme.onSurfaceVariant;
    final label = tr(
      ref,
      isPremium ? 'profile_membership_pro' : 'profile_membership_standard',
    );

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: foregroundColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.person_outline_rounded,
              size: 14,
              color: foregroundColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(premiumProvider);
    final username = (profile['username'] as String?)?.trim();
    final displayName = (profile['full_name'] as String?)?.trim();
    final avatarUrl = (profile['avatar_url'] as String?)?.trim();
    final bio = (profile['bio'] as String?)?.trim() ?? '';
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : 'Email not added';

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SplixaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundImage: avatarUrl?.isNotEmpty == true
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person_rounded, size: 38),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName?.isNotEmpty == true
                                      ? displayName!
                                      : (username?.isNotEmpty == true
                                            ? username!
                                            : 'Splixa user'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _MembershipBadge(isPremium: isPremium),
                            ],
                          ),
                          const SizedBox(height: 7),
                          if (username?.isNotEmpty == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '@$username',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  tr(ref, 'profile_bio_label'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  bio.isEmpty ? tr(ref, 'profile_bio_empty') : bio,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => _editProfile(
                    context,
                    ref,
                    username ?? '',
                    email,
                    avatarUrl ?? '',
                    bio,
                  ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _showSettings(context, ref),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.person_add_alt_rounded,
                  label: 'Invite Friends',
                  onTap: () => context.go('/social'),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  onTap: () => context.push('/update-password'),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Download Monthly Report',
                  onTap: () => _downloadReport(context, ref),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.support_agent_rounded,
                  label: 'Contact Us',
                  onTap: () => _message(
                    context,
                    'Support contact will be available here.',
                  ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.description_outlined,
                  label: 'Terms',
                  onTap: () => _openLegalPage(
                    context,
                    Uri.parse('https://splixa.net/terms'),
                  ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.shield_outlined,
                  label: 'Privacy',
                  onTap: () => _openLegalPage(
                    context,
                    Uri.parse('https://splixa.net/privacy'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: .55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _logOut(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'DANGER ZONE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () => _showDeleteAccountDialog(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete Account and Data'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String username,
    String email,
    String avatarUrl,
    String bio,
  ) async {
    final usernameController = TextEditingController(text: username);
    final emailController = TextEditingController(text: email);
    final bioController = TextEditingController(text: bio);
    XFile? selectedAvatar;
    Uint8List? selectedAvatarBytes;
    var isSaving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Choose profile picture',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isSaving
                        ? null
                        : () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1600,
                              maxHeight: 1600,
                              imageQuality: 86,
                              requestFullMetadata: false,
                            );
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              selectedAvatar = picked;
                              selectedAvatarBytes = bytes;
                            });
                          },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: selectedAvatarBytes != null
                              ? MemoryImage(selectedAvatarBytes!)
                              : (avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null)
                                    as ImageProvider<Object>?,
                          child:
                              selectedAvatarBytes == null && avatarUrl.isEmpty
                              ? const Icon(Icons.person_rounded, size: 42)
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to choose a photo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  enabled: !isSaving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 240,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'profile_bio_label'),
                    hintText: tr(ref, 'profile_bio_hint'),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        var savedAvatarUrl = avatarUrl;
                        final userId = ref.read(currentUserIdProvider);
                        if (selectedAvatar != null && userId != null) {
                          savedAvatarUrl = await ref
                              .read(mediaUploadServiceProvider)
                              .uploadProfileAvatar(
                                userId: userId,
                                image: selectedAvatar!,
                              );
                        }
                        await ref
                            .read(socialServiceProvider)
                            .updateProfile(
                              currentUsername: username,
                              newUsername: usernameController.text.trim(),
                              newEmail: emailController.text.trim(),
                              avatarUrl: savedAvatarUrl,
                              bio: bioController.text.trim(),
                            );
                        ref.invalidate(currentUserProfileProvider);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(friendlyErrorMessage(error))),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    usernameController.dispose();
    emailController.dispose();
    bioController.dispose();
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (context, sheetRef, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: sheetRef.watch(appThemeModeProvider) == ThemeMode.dark,
                  onChanged: (_) =>
                      sheetRef.read(appThemeModeProvider.notifier).toggle(),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_money_rounded),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: sheetRef.watch(currencyProvider),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: '₺', child: Text('₺ (TRY)')),
                      DropdownMenuItem(value: r'$', child: Text(r'$ (USD)')),
                      DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        sheetRef
                            .read(currencyProvider.notifier)
                            .setCurrency(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context, WidgetRef ref) async {
    try {
      final transactions = await ref.read(transactionsProvider.future);
      final now = DateTime.now();
      final currentMonth = transactions
          .where(
            (item) =>
                item.date.year == now.year && item.date.month == now.month,
          )
          .toList();
      await PdfExportService.generateAndShareMonthlyReport(
        currentMonth,
        '${now.month}/${now.year}',
        language: ref.read(appLanguageProvider),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account and Data?'),
        content: const Text(
          'This will sign you out and begin the account deletion flow. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLegalPage(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this page.')),
      );
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, endIndent: 16);
  }
}
