import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

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

    // Map branch index (0,1,2,3) to visual index (0,1,3,4)
    // 0 -> 0 (Home)
    // 1 -> 1 (Transactions)
    // 2 -> 3 (Analytics)
    // 3 -> 4 (Settings)
    int visualIndex = navigationShell.currentIndex;
    if (visualIndex >= 2) {
       visualIndex += 1; 
    }

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              onDestinationSelected: (index) {
                  if (index == 2) {
                     context.push('/add-transaction');
                  } else {
                     _onTap(index);
                  }
              },
              selectedIndex: visualIndex,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('History')),
                  NavigationRailDestination(icon: Icon(Icons.add_circle, size: 32), label: Text('Add')),
                  NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Analytics')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
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
        selectedIndex: visualIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
             context.push('/add-transaction');
          } else {
             _onTap(index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
             icon: Icon(Icons.add_circle_outline, size: 32),
             selectedIcon: Icon(Icons.add_circle, size: 32),
             label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(int visualIndex) {
     // Map visual index (0,1,3,4) back to branch index (0,1,2,3)
     int branchIndex = visualIndex;
     if (visualIndex > 2) branchIndex -= 1;

     navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
  }
}
