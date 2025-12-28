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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;

        if (useRail) {
           return Scaffold(
             body: Row(
               children: [
                 NavigationRail(
                   leading: Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     child: FloatingActionButton.extended(
                       onPressed: () => context.push('/add-transaction'),
                       icon: const Icon(Icons.add),
                       label: const Text('Add'),
                       elevation: 0,
                     ),
                   ),
                   selectedIndex: navigationShell.currentIndex,
                   onDestinationSelected: (index) => _onTap(index),
                   labelType: NavigationRailLabelType.all,
                   destinations: const [
                       NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
                       NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('History')),
                       NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analysis')),
                       NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
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
          bottomNavigationBar: BottomAppBar(
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarIcon(
                  icon: Icons.dashboard_outlined, 
                  selectedIcon: Icons.dashboard, 
                  label: 'Home', 
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0)
                ),
                _NavBarIcon(
                  icon: Icons.receipt_long_outlined, 
                  selectedIcon: Icons.receipt_long, 
                  label: 'History', 
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1)
                ),
                const Gap(48), // Space for FAB
                _NavBarIcon(
                  icon: Icons.analytics_outlined, 
                  selectedIcon: Icons.analytics, 
                  label: 'Analysis', 
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2)
                ),
                _NavBarIcon(
                  icon: Icons.settings_outlined, 
                  selectedIcon: Icons.settings, 
                  label: 'Settings', 
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => _onTap(3)
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
             onPressed: () => context.push('/add-transaction'),
             child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  void _onTap(int index) {
     navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarIcon({required this.icon, required this.selectedIcon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color),
            const Gap(4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
