import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Money Tracker',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _DrawerItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: currentPath == '/',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                _DrawerItem(
                  icon: Icons.list_alt,
                  label: 'Transactions',
                  isSelected: currentPath.startsWith('/transactions'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/transactions');
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.account_balance,
                  label: 'Accounts',
                  isSelected: currentPath.startsWith('/accounts'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/accounts');
                  },
                ),
                _DrawerItem(
                  icon: Icons.category,
                  label: 'Categories',
                  isSelected: currentPath.startsWith('/categories'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/categories');
                  },
                ),
                _DrawerItem(
                  icon: Icons.group,
                  label: 'People & Debts',
                  isSelected: currentPath.startsWith('/parties'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/parties');
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.track_changes,
                  label: 'Goals',
                  isSelected: currentPath.startsWith('/goals'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/goals');
                  },
                ),
                _DrawerItem(
                  icon: Icons.pie_chart_outline,
                  label: 'Budget',
                  isSelected: currentPath.startsWith('/budgets'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/budgets');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: _DrawerItem(
                icon: Icons.settings,
                label: 'Settings',
                isSelected: currentPath.startsWith('/settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        onTap: onTap,
      ),
    );
  }
}
