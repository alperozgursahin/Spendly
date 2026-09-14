import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_formatting.dart';
import '../../core/app_strings.dart';
import '../../core/analytics_service.dart';
import '../../core/app_theme_provider.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
import '../../core/splixa_loading.dart';
import '../../widgets/informative_feature_sheet.dart';
import '../auth/auth_provider.dart';
import '../groups/group_model.dart';
import '../groups/group_provider.dart';
import '../notifications/notification_provider.dart';
import '../social/social_provider.dart';
import '../subscriptions/premium_provider.dart';
import '../transactions/transaction_provider.dart';
import 'activity_provider.dart';
import 'dashboard_screen.dart' show DashboardScreen, QuickAddWidget;

class SplixaHomeScreen extends ConsumerWidget {
  const SplixaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(userGroupsProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final userId = ref.watch(currentUserIdProvider);
    final unread = userId == null
        ? 0
        : ref.watch(unreadNotificationCountProvider(userId));
    final rawUsername = profile?['username']?.toString().trim();
    final displayName = rawUsername?.isNotEmpty == true
        ? rawUsername!
        : tr(ref, 'home_default_name');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refreshHome(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                sliver: SliverList.list(
                  children: [
                    _Header(unreadCount: unread),
                    const SizedBox(height: 28),
                    Text(
                      trp(ref, 'home_welcome', {'name': displayName}),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(ref, 'home_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const DashboardScreen(
                      embedded: true,
                      includeQuickAdd: false,
                      showEmbeddedTools: false,
                      showActivity: false,
                      showRecentTransactions: false,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(ref, 'groups_title'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: tr(ref, 'home_minimize_title'),
                          onPressed: () =>
                              _showMinimizeTransactions(context, ref),
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                        TextButton.icon(
                          onPressed: () => _createGroup(context, ref, groups),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: Text(tr(ref, 'home_new_group')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    groups.when(
                      data: (items) => _GroupsList(groups: items),
                      loading: () => const SplixaSkeletonView(
                        type: SplixaSkeletonType.cards,
                        itemCount: 2,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      error: (error, _) => SplixaErrorState(
                        message: friendlyErrorMessage(error),
                        compact: true,
                        onRetry: () => ref.invalidate(userGroupsProvider),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const DashboardScreen(
                      embedded: true,
                      includeQuickAdd: false,
                      showEmbeddedTools: false,
                      showBalance: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: tr(ref, 'home_quick_add'),
        onPressed: () => _showQuickAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _refreshHome(WidgetRef ref) async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(userGroupsProvider);
    ref.invalidate(groupMembersProvider);
    try {
      await Future.wait<dynamic>([
        ref.read(transactionsProvider.future),
        ref.read(activityProvider.future),
        ref.read(currentUserProfileProvider.future),
        ref.read(userGroupsProvider.future),
      ]);
    } catch (_) {
      // Each provider renders its own error state while refresh still completes.
    }
  }

  Future<void> _createGroup(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GroupModel>> groups,
  ) async {
    if (!ref.read(premiumProvider) && (groups.valueOrNull?.length ?? 0) >= 2) {
      context.push(
        '/paywall?source=${PaywallSource.unlimitedGroups.analyticsValue}',
      );
      return;
    }
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(ref, 'groups_create_new_group')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: tr(ref, 'home_group_name_hint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(ref, 'common_cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              final userId = ref.read(currentUserIdProvider);
              if (name.isEmpty || userId == null) return;
              try {
                await ref.read(groupServiceProvider).createGroup(name, userId);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyErrorMessage(error))),
                );
              }
            },
            child: Text(tr(ref, 'groups_create_button')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (created != true || !context.mounted) return;

    // Let the dialog route and its inherited dependencies finish unmounting
    // before rebuilding the Home provider tree.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;
    ref.invalidate(userGroupsProvider);
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: SingleChildScrollView(child: QuickAddWidget()),
      ),
    );
  }

  void _showMinimizeTransactions(BuildContext context, WidgetRef ref) {
    InformativeFeatureSheet.show<void>(
      context,
      title: tr(ref, 'home_minimize_title'),
      description: tr(ref, 'home_minimize_description'),
      content: const PaymentFlowExample(),
      closeLabel: tr(ref, 'common_close'),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Row(
      children: [
        const SplixaLogo(compact: true),
        const Spacer(),
        IconButton(
          tooltip: tr(ref, 'dashboard_statistics'),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: () {
            if (ref.read(premiumProvider)) {
              context.push('/statistics');
            } else {
              context.push(
                '/paywall?source=${PaywallSource.advancedAnalytics.analyticsValue}',
              );
            }
          },
          icon: const Icon(Icons.insights_outlined),
        ),
        IconButton(
          tooltip: tr(
            ref,
            isDark ? 'home_switch_to_light' : 'home_switch_to_dark',
          ),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: () => ref.read(appThemeModeProvider.notifier).toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
        Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: IconButton.filledTonal(
            tooltip: tr(ref, 'dashboard_notifications'),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            iconSize: 21,
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class _GroupsList extends ConsumerWidget {
  const _GroupsList({required this.groups});

  final List<GroupModel> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groups.isEmpty) {
      return SplixaCard(
        child: Row(
          children: [
            Icon(
              Icons.group_add_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(tr(ref, 'home_groups_empty'))),
          ],
        ),
      );
    }
    return SplixaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < groups.length; index++) ...[
            _GroupTile(group: groups[index]),
            if (index != groups.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 18),
          ],
        ],
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = group.id;
    final members = groupId == null
        ? const AsyncValue<List<GroupMemberModel>>.data([])
        : ref.watch(groupMembersProvider(groupId));
    final count = members.valueOrNull?.length;
    final unread = groupId == null
        ? 0
        : ref.watch(unreadGroupActivityCountProvider(groupId));
    return ListTile(
      minTileHeight: 76,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.primary,
        foregroundImage: group.avatarUrl?.isNotEmpty == true
            ? NetworkImage(group.avatarUrl!)
            : null,
        child: group.avatarUrl?.isNotEmpty == true
            ? null
            : const Icon(Icons.groups_2_rounded),
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        count == null
            ? tr(ref, 'home_members_loading')
            : trp(ref, 'home_members_count', {'count': AppFormat.count(count)}),
      ),
      trailing: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.chevron_right_rounded),
      ),
      onTap: groupId == null
          ? null
          : () => context.push('/groups/$groupId', extra: group.name),
    );
  }
}
