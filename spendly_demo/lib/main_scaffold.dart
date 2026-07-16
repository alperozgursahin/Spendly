import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/app_strings.dart';
import 'features/social/social_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/debts');
        break;
      case 2:
        context.go('/groups');
        break;
      case 3:
        context.go('/social');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) _currentIndex = 0;
    if (location.startsWith('/debts')) _currentIndex = 1;
    if (location.startsWith('/groups')) _currentIndex = 2;
    if (location.startsWith('/social')) _currentIndex = 3;
    if (location.startsWith('/profile')) _currentIndex = 4;

    final pendingRequests = ref.watch(pendingFriendRequestCountProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: tr(ref, 'nav_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: tr(ref, 'nav_debts'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: tr(ref, 'nav_groups'),
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingRequests > 0,
              label: Text('$pendingRequests'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: tr(ref, 'nav_social'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: tr(ref, 'nav_profile'),
          ),
        ],
      ),
    );
  }
}
