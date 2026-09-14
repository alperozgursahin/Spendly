import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/analytics_service.dart';
import '../../core/app_theme_provider.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_loading.dart';
import '../../core/language_selector.dart';
import '../../core/locale_provider.dart';
import '../../core/media_upload_service.dart';
import '../../core/splixa_design.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import '../subscriptions/premium_provider.dart';
import '../transactions/transaction_provider.dart';
import 'currency_provider.dart';
import 'exchange_rate_provider.dart';
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
      appBar: AppBar(title: Text(tr(ref, 'profile_title'))),
      body: profile.when(
        data: (data) => _ProfileContent(profile: data),
        loading: () => const SplixaSkeletonView(
          type: SplixaSkeletonType.profile,
          padding: EdgeInsets.all(20),
        ),
        error: (error, _) => SplixaErrorState(
          message: friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
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
        : tr(ref, 'profile_email_missing');

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
                                            : tr(ref, 'profile_user_fallback')),
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
          const SizedBox(height: 26),

          // Grouped sections instead of one long undifferentiated menu: the
          // user scans for a category first ("where do I change my password?")
          // and destructive actions stay visually separated from routine ones.
          _SectionHeader(label: tr(ref, 'profile_section_subscription')),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuRow(
                  icon: isPremium
                      ? Icons.manage_accounts_rounded
                      : Icons.workspace_premium_rounded,
                  label: isPremium
                      ? tr(ref, 'profile_manage_subscription')
                      : tr(ref, 'profile_upgrade_pro'),
                  onTap: isPremium
                      ? () => _manageSubscription(context, ref)
                      : () => context.push(
                          '/paywall?source=${PaywallSource.profile.analyticsValue}',
                        ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: isPremium
                      ? Icons.auto_awesome_rounded
                      : Icons.lock_rounded,
                  label: tr(ref, 'pro_tools_title'),
                  onTap: isPremium
                      ? () => context.push('/pro-tools')
                      : () => context.push(
                          '/paywall?source=${PaywallSource.profile.analyticsValue}',
                        ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: isPremium
                      ? Icons.picture_as_pdf_outlined
                      : Icons.lock_rounded,
                  label: isPremium
                      ? tr(ref, 'profile_download_monthly_report')
                      : tr(ref, 'profile_download_monthly_report_pro'),
                  onTap: isPremium
                      ? () => _downloadReport(context, ref)
                      : () => context.push(
                          '/paywall?source=${PaywallSource.advancedReports.analyticsValue}',
                        ),
                ),
              ],
            ),
          ),

          _SectionHeader(label: tr(ref, 'profile_section_account')),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.edit_outlined,
                  label: tr(ref, 'profile_edit_tile'),
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
                  icon: Icons.lock_outline_rounded,
                  label: tr(ref, 'profile_change_password_tile'),
                  onTap: () => context.push('/update-password'),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.person_add_alt_rounded,
                  label: tr(ref, 'profile_invite_friends'),
                  onTap: () => context.go('/social'),
                ),
              ],
            ),
          ),

          // Preferences are inline rather than behind a bottom sheet: the
          // language row is the one a user who picked the wrong language needs
          // to find without reading anything.
          _SectionHeader(label: tr(ref, 'profile_section_preferences')),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    tr(ref, 'profile_dark_mode'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: ref.watch(appThemeModeProvider) == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(appThemeModeProvider.notifier).toggle(),
                ),
                const _MenuDivider(),
                const AppLanguageTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                const _MenuDivider(),
                ListTile(
                  minTileHeight: 60,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    tr(ref, 'profile_currency_tile'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: DropdownButton<String>(
                    value: ref.watch(currencyProvider),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: '₺', child: Text('₺ (TRY)')),
                      DropdownMenuItem(value: r'$', child: Text(r'$ (USD)')),
                      DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(currencyProvider.notifier).setCurrency(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          _SectionHeader(label: tr(ref, 'profile_section_support')),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: _MenuRow(
              icon: Icons.support_agent_rounded,
              label: tr(ref, 'profile_contact_us'),
              onTap: () =>
                  _message(context, tr(ref, 'profile_support_placeholder')),
            ),
          ),

          _SectionHeader(label: tr(ref, 'profile_section_legal')),
          SplixaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.description_outlined,
                  label: tr(ref, 'profile_terms'),
                  onTap: () => _openLegalPage(
                    context,
                    Uri.parse('https://splixa.net/terms'),
                    ref,
                  ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.shield_outlined,
                  label: tr(ref, 'profile_privacy'),
                  onTap: () => _openLegalPage(
                    context,
                    Uri.parse('https://splixa.net/privacy'),
                    ref,
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
              label: Text(tr(ref, 'profile_logout')),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            tr(ref, 'profile_danger_zone').toUpperCase(),
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
              label: Text(tr(ref, 'profile_delete_account_data')),
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
          title: Text(tr(ref, 'profile_edit_tile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: tr(ref, 'profile_choose_picture'),
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
                        PositionedDirectional(
                          end: -2,
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
                  tr(ref, 'profile_tap_choose_photo'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'profile_username_label'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'profile_email_label'),
                  ),
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
              child: Text(tr(ref, 'common_cancel')),
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
                  : Text(tr(ref, 'common_save')),
            ),
          ],
        ),
      ),
    );
    usernameController.dispose();
    emailController.dispose();
    bioController.dispose();
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
        DateTime(now.year, now.month),
        language: ref.read(appLanguageProvider),
        currencySymbol: ref.read(currencyProvider),
        displayAmount: (amount) => ref
            .read(exchangeRateProvider)
            .convertFromTRY(amount, ref.read(currencyProvider)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmationController = TextEditingController();
    var confirmation = '';
    var isDeleting = false;
    String? errorMessage;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canDelete = confirmation.trim() == 'DELETE' && !isDeleting;
          return PopScope(
            canPop: !isDeleting,
            child: AlertDialog(
              title: Text(tr(ref, 'profile_delete_dialog_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(ref, 'profile_delete_dialog_body')),
                    const SizedBox(height: 12),
                    Text(tr(ref, 'profile_delete_group_warning')),
                    const SizedBox(height: 16),
                    Text(
                      tr(ref, 'profile_delete_type_confirm'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmationController,
                      enabled: !isDeleting,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'DELETE'),
                      onChanged: (value) {
                        setDialogState(() => confirmation = value);
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(tr(ref, 'common_cancel')),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onError,
                  ),
                  onPressed: canDelete
                      ? () async {
                          setDialogState(() {
                            isDeleting = true;
                            errorMessage = null;
                          });
                          try {
                            await ref
                                .read(authControllerProvider)
                                .deleteAccount();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) context.go('/onboarding');
                          } on AccountDeletionException catch (error) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isDeleting = false;
                              if (error.code == 'GROUP_OWNERSHIP_REQUIRED') {
                                final groups = error.groupNames.isEmpty
                                    ? ''
                                    : '\n${error.groupNames.join(', ')}';
                                errorMessage =
                                    '${tr(ref, 'profile_delete_transfer_first')}$groups';
                              } else {
                                errorMessage = error.message;
                              }
                            });
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isDeleting = false;
                              errorMessage = tr(ref, 'profile_delete_failed');
                            });
                          }
                        }
                      : null,
                  icon: isDeleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever_outlined),
                  label: Text(
                    isDeleting
                        ? tr(ref, 'profile_deleting')
                        : tr(ref, 'profile_delete_permanently'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    confirmationController.dispose();
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

  Future<void> _openLegalPage(
    BuildContext context,
    Uri uri,
    WidgetRef ref,
  ) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(ref, 'profile_link_failed'))));
    }
  }

  Future<void> _manageSubscription(BuildContext context, WidgetRef ref) async {
    final uri = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse('https://play.google.com/store/account/subscriptions')
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    await _openLegalPage(context, uri, ref);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 22, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
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
