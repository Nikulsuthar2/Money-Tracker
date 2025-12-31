import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class ScaffoldWithNavbar extends StatefulWidget {
  const ScaffoldWithNavbar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavbar> createState() => _ScaffoldWithNavbarState();
}

class _ScaffoldWithNavbarState extends State<ScaffoldWithNavbar> {
  bool _isRailExtended = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;

        if (useRail) {
           return Scaffold(
             body: Row(
               children: [
                 NavigationRail(
                   extended: _isRailExtended,
                   minWidth: 72,
                   leading: Column(
                     children: [
                        IconButton(
                          icon: Icon(_isRailExtended ? Icons.menu_open : Icons.menu),
                          onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
                        ),
                        const Gap(16),
                        FloatingActionButton(
                          onPressed: () => context.push('/add-transaction'),
                          elevation: 0,
                          tooltip: 'Add Transaction',
                          child: const Icon(Icons.add),
                        ),
                     ],
                   ),
                   selectedIndex: widget.navigationShell.currentIndex,
                   onDestinationSelected: (index) => _onTap(index),
                   labelType: _isRailExtended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                   groupAlignment: -0.9,
                   destinations: const [
                       NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
                       NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('History')),
                       NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('People')),
                       NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analysis')),
                       NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                   ],
                 ),
                 const VerticalDivider(thickness: 1, width: 1),
                 Expanded(child: widget.navigationShell),
               ],
             ),
           );
        }

        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: NavigationBar(
            // Logic for Bottom Bar (Mobile)
            // 0: Home, 1: History, 2: Add (Action), 3: People, 4: Analysis, 5: Settings
            // Need to map Shell Index (0-4) to UI Index (0-5)
            // Shell: Home(0), History(1), People(2), Analysis(3), Settings(4)
            // UI: Home, History, ADD, People, Analysis, Settings (6 items? That's too crowded)
            // Let's keep 5 items + Add in middle? 
            // Home, History, ADD, People, Settings. (Drop Analysis for mobile? Or generic 'Menu'?)
            // User asked for "Standard Bottom Navbar". 
            // Let's put People in place of Analysis for now, or just have 5 items.
            // Items: Home, History, Add, People, Settings.
            // Shell indices mapping:
            // 0 -> 0 (Home)
            // 1 -> 1 (History)
            // 2 (People) -> 3 (UI Index)
            // Mobile Bottom Bar
            // Shell Index Mapping:
            // 0: Home -> 0
            // 1: History -> 1
            // 2: People -> 2
            // 3: Analytics -> 3
            // 4: Settings -> 4
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (index) => _onTap(index),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
               NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
               NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
               NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
               NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
               NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  // No longer needed as mapping is 1:1
  // int _getMobileSelectedIndex(int shellIndex) ...
  // int _getShellIndexFromMobile(int uiIndex) ...

  void _onTap(int index) {
     widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
  }
}
