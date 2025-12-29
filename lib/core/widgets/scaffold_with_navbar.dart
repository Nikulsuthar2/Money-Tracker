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
            // 3 (Analysis) -> Hidden on Mobile? Or accessible via simple way?
            // Let's disable Analysis on Mobile Bottom Bar for clutter reduction as per user's "People" focus, OR just make it 5 items without Add?
            // User wanted "Add" in center.
            // Items: Home, History, Add, People, Settings.
            
            selectedIndex: _getMobileSelectedIndex(widget.navigationShell.currentIndex),
            onDestinationSelected: (index) {
               if (index == 2) {
                 context.push('/add-transaction');
               } else {
                 final realIndex = _getShellIndexFromMobile(index);
                 if (realIndex != -1) _onTap(realIndex);
               }
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
               NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
               NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'History'),
               NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add'),
               NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
               NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
            ],
          ),
        );
      },
    );
  }

  int _getMobileSelectedIndex(int shellIndex) {
    if (shellIndex == 0) return 0; // Home
    if (shellIndex == 1) return 1; // History
    if (shellIndex == 2) return 3; // People (Shell 2) -> UI 3
    if (shellIndex == 3) return 4; // Analysis (Shell 3) -> UI 4
    // Settings (Shell 4) is now hidden from BottomBar, accessible via Home AppBar?
    return 0; 
  }
  
  int _getShellIndexFromMobile(int uiIndex) {
    if (uiIndex == 0) return 0;
    if (uiIndex == 1) return 1;
    if (uiIndex == 3) return 2; // People is index 2 in Shell
    if (uiIndex == 4) return 3; // Analysis is index 3 in Shell
    return -1;
  }

  void _onTap(int index) {
     widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
  }
}
