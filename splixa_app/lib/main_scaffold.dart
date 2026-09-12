import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_strings.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location) {
    if (location.startsWith('/social')) return 1;
    if (location.startsWith('/debts')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  bool _showsPrimaryNavigation(String location) {
    return location == '/dashboard' ||
        location == '/social' ||
        location == '/debts' ||
        location == '/profile';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: _showsPrimaryNavigation(location)
          ? NavigationBar(
              height: 72,
              selectedIndex: _selectedIndex(location),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                  case 1:
                    context.go('/social');
                  case 2:
                    context.go('/debts');
                  case 3:
                    context.go('/profile');
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: tr(ref, 'nav_dashboard'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline_rounded),
                  selectedIcon: const Icon(Icons.people_rounded),
                  label: tr(ref, 'nav_social'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(
                    Icons.account_balance_wallet_rounded,
                  ),
                  label: tr(ref, 'nav_debts'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: tr(ref, 'nav_profile'),
                ),
              ],
            )
          : null,
    );
  }
}
