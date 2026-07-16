import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import 'social_provider.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  final Set<String> _sendingTo = <String>{};

  @override
  void initState() {
    super.initState();

    // Force a fresh fetch whenever this screen mounts so a just-switched
    // account never shows the previous account's cached friend list/requests
    // (see GroupDetailScreen/NotificationsScreen for the same pattern).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(friendsStreamProvider);
    });

    // Stale results shouldn't linger once the query changes.
    _searchController.addListener(() {
      if (_hasSearched) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final curUserId = ref.read(currentUserProvider)?.id ?? '';
    try {
      final results = await ref
          .read(socialServiceProvider)
          .searchUsers(query, curUserId);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequestTo(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    if (_sendingTo.contains(userId)) return;

    setState(() => _sendingTo.add(userId));
    final curUserId = ref.read(currentUserProvider)?.id ?? '';

    try {
      await ref
          .read(socialServiceProvider)
          .sendFriendRequest(curUserId, user['username'] as String);
      if (!mounted) return;
      setState(() {
        _searchResults.removeWhere((u) => u['id'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'social_request_sent_snackbar'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _sendingTo.remove(userId));
    }
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasSearched) return const SizedBox.shrink();

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text(tr(ref, 'social_user_not_found'))),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              tr(ref, 'social_search_results_header'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
        ...(_searchResults.map((user) {
          final userId = user['id'] as String;
          final username = user['username'] as String? ?? '';
          final avatarUrl = user['avatar_url'] as String?;
          final isSending = _sendingTo.contains(userId);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text('@$username'),
            trailing: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: tr(ref, 'social_add_friend_tooltip'),
                    onPressed: () => _sendRequestTo(user),
                  ),
          );
        })),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendshipsAsync = ref.watch(friendsStreamProvider);
    final curUserId = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'social_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: tr(ref, 'social_search_hint'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: tr(ref, 'social_search_tooltip'),
                  onPressed: _isSearching ? null : _search,
                ),
              ],
            ),
          ),
          _buildSearchResults(),
          const Divider(),
          Expanded(
            child: friendshipsAsync.when(
              data: (friendships) {
                if (friendships.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(ref, 'social_no_friends_title'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(ref, 'social_no_friends_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: friendships.length,
                  itemBuilder: (context, index) {
                    final f = friendships[index];
                    final isSender = f['user_id1'] == curUserId;
                    final friendId = isSender ? f['user_id2'] : f['user_id1'];

                    if (f['status'] == 'pending') {
                      final username =
                          f['profiles'] != null &&
                              f['profiles']['username'] != null
                          ? '@${f['profiles']['username']}'
                          : friendId;
                      final avatarUrl = f['profiles'] != null
                          ? f['profiles']['avatar_url']
                          : null;

                      Widget getAvatar() {
                        return CircleAvatar(
                          backgroundImage:
                              avatarUrl != null &&
                                  avatarUrl.toString().isNotEmpty
                              ? NetworkImage(avatarUrl.toString())
                              : null,
                          child:
                              avatarUrl == null || avatarUrl.toString().isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        );
                      }

                      if (isSender) {
                        return ListTile(
                          leading: getAvatar(),
                          title: Text(
                            tr(
                              ref,
                              'social_request_sent_prefix',
                            ).replaceFirst('%s', username),
                          ),
                          subtitle: Text(tr(ref, 'social_pending_status')),
                        );
                      } else {
                        return ListTile(
                          leading: getAvatar(),
                          title: Text(
                            tr(
                              ref,
                              'social_incoming_request_prefix',
                            ).replaceFirst('%s', username),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => ref
                                .read(socialServiceProvider)
                                .acceptFriendRequest(f['id']),
                          ),
                        );
                      }
                    }

                    if (f['status'] == 'accepted') {
                      final username =
                          f['profiles'] != null &&
                              f['profiles']['username'] != null
                          ? '@${f['profiles']['username']}'
                          : friendId;
                      final avatarUrl = f['profiles'] != null
                          ? f['profiles']['avatar_url']
                          : null;

                      Widget getAvatar() {
                        return CircleAvatar(
                          backgroundImage:
                              avatarUrl != null &&
                                  avatarUrl.toString().isNotEmpty
                              ? NetworkImage(avatarUrl.toString())
                              : null,
                          child:
                              avatarUrl == null || avatarUrl.toString().isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        );
                      }

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () => context.push('/social/user/$friendId'),
                          child: getAvatar(),
                        ),
                        title: Text(
                          tr(
                            ref,
                            'social_friend_prefix',
                          ).replaceFirst('%s', username),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            context.push(
                              '/social/chat/$friendId',
                              extra: tr(ref, 'social_default_chat_title'),
                            );
                          },
                        ),
                        onTap: () {
                          context.push('/social/user/$friendId');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
              error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
