import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/core/widgets/global_app_bar.dart';
import 'package:money_manager/core/widgets/main_drawer.dart';
import 'dart:ui';

class ScaffoldWithNavbar extends StatefulWidget {
  const ScaffoldWithNavbar({required this.navigationShell, super.key});

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
            appBar: const GlobalAppBar(),
            body: Row(
              children: [
                NavigationRail(
                  extended: _isRailExtended,
                  minWidth: 72,
                  leading: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isRailExtended ? Icons.menu_open : Icons.menu,
                        ),
                        onPressed: () =>
                            setState(() => _isRailExtended = !_isRailExtended),
                      ),
                      const Gap(16),
                      FloatingActionButton(
                        heroTag: null,
                        onPressed: () => context.push('/add-transaction'),
                        elevation: 0,
                        tooltip: 'Add Transaction',
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTap(index),
                  labelType: _isRailExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  groupAlignment: -0.9,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('History'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text('Analysis'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.apps),
                      selectedIcon: Icon(Icons.apps),
                      label: Text('More'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: widget.navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: const GlobalAppBar(),
          drawer: const MainDrawer(),
          body: widget.navigationShell,
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: (Theme.of(context).navigationBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface).withOpacity(0.7),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _getUIIndex(widget.navigationShell.currentIndex),
                  onDestinationSelected: (index) => _onTap(index),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  label: 'Add',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Insights',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.apps),
                  selectedIcon: Icon(Icons.apps),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }



  int _getUIIndex(int branchIndex) {
    if (branchIndex >= 2) {
      return branchIndex + 1;
    }
    return branchIndex;
  }

  void _onTap(int index) {
    int branchIndex = index;
    if (index == 2) {
      _showAddBottomSheet(context);
      return;
    }
    if (index > 2) {
      branchIndex = index - 1;
    }

    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(24),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 12,
                  children: [
                    _buildQuickActionButton(
                      ctx,
                      Icons.arrow_downward,
                      'Income',
                      Colors.teal,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-transaction', extra: {'type': TransactionType.income});
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.arrow_upward,
                      'Expense',
                      Colors.red,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-transaction', extra: {'type': TransactionType.expense});
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.sync_alt,
                      'Transfer',
                      Colors.blue,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-transaction', extra: {'type': TransactionType.transfer});
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.handshake,
                      'Settlement',
                      Colors.indigo,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-transaction', extra: {'type': 'settlement'});
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.wallet,
                      'Account',
                      Colors.orange,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-account');
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.category,
                      'Category',
                      Colors.purple,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-category');
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.flag,
                      'Goal',
                      Colors.pink,
                      () {
                        Navigator.pop(ctx);
                        context.push('/add-goal');
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.people,
                      'Person',
                      Colors.brown,
                      () {
                        Navigator.pop(ctx);
                        context.push('/parties'); // Or push to a specific add-person if available, but /parties is the list. Let's push to parties for now since there's no direct add-person route, wait, Add Person is a bottom sheet in Parties. So going to /parties is best.
                      },
                    ),
                    _buildQuickActionButton(
                      ctx,
                      Icons.account_balance_wallet,
                      'Budget',
                      Colors.cyan,
                      () {
                        Navigator.pop(ctx);
                        context.push('/budgets/add');
                      },
                    ),
                  ],
                ),
                const Gap(16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(
            ctx,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Gap(4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
