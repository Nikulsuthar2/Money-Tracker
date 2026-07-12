import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80,
        top: MediaQuery.of(context).padding.top + 16,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('More', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Features', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.track_changes, color: Colors.white)),
            title: const Text('Goals & Targets'),
            subtitle: const Text('Track saving goals and debts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/goals'),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
            title: const Text('Budgets'),
            subtitle: const Text('Set spending limits for categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/budgets'),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.people, color: Colors.white)),
            title: const Text('People / Parties'),
            subtitle: const Text('Manage friends, splits, and debts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/parties'),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.category, color: Colors.white)),
            title: const Text('Categories'),
            subtitle: const Text('Manage transaction categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.subscriptions, color: Colors.white)),
            title: const Text('Subscriptions'),
            subtitle: const Text('Manage recurring payments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/subscriptions'), // Placeholder
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.inventory_2, color: Colors.white)),
            title: const Text('Assets'),
            subtitle: const Text('Manage static properties and objects'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/assets'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('System', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.settings, color: Colors.white)),
            title: const Text('Settings'),
            subtitle: const Text('App preferences and data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
        ],
    );
  }
}
