import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavbar extends StatelessWidget {
  const ScaffoldWithNavbar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useRail = width > 800; // Threshold for desktop layout

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              onDestinationSelected: (index) => _onTap(index),
              selectedIndex: navigationShell.currentIndex,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                 NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                 NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Accounts')),
                 NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Transactions')),
                 NavigationRailDestination(icon: Icon(Icons.subscriptions), label: Text('Subs')),
                 NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Analytics')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.subscriptions_outlined),
            selectedIcon: Icon(Icons.subscriptions),
            label: 'Subs',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
     navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
  }
}
