import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final totalBalance = accounts.fold(0.0, (sum, item) => sum + item.balance);

          if (accounts.isEmpty) {
            return const Center(
              child: Text('No accounts yet. Add one!'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total Balance Header
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Total Wallet Balance', style: Theme.of(context).textTheme.titleMedium),
                      const Gap(8),
                      Text('\$${totalBalance.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              
              // Accounts List
              ...accounts.map((item) => AccountCard(item: item)).toList(),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-account'); 
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AccountCard extends ConsumerWidget {
  const AccountCard({super.key, required this.item});

  final AccountStats item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = item.account;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Edit/Delete Menu
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(children: [Icon(Icons.edit, size: 20), Gap(8), Text('Edit')]),
                      onTap: () => context.push('/add-account', extra: account),
                    ),
                    PopupMenuItem(
                      child: const Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), Gap(8), Text('Delete')]),
                      onTap: () {
                         // Post-frame callback to show dialog
                         Future.delayed(Duration.zero, () {
                           if (context.mounted) {
                             showDialog(context: context, builder: (d) => AlertDialog(
                                title: const Text('Delete Account?'),
                                content: const Text('This will delete the account AND all associated transactions.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                                  TextButton(onPressed: () async {
                                      await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
                                      if (context.mounted) Navigator.pop(d);
                                  }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ));
                           }
                         });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Gap(8),
            Text(
              '\$${item.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            
            // Stats Row
            Row(
              children: [
                _StatPill(
                  label: 'Income',
                  amount: item.totalIncome, 
                  color: Colors.teal, 
                  icon: Icons.arrow_downward
                ),
                const Gap(8),
                _StatPill(
                  label: 'Expense',
                  amount: item.totalExpense, 
                  color: Colors.redAccent, 
                  icon: Icons.arrow_upward
                ),
              ],
            ),
            const Gap(20),
            
            // Action Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to add transaction with this account pre-selected
                      // We can pass the account as an extra, but AddTransactionPage expects Transaction?
                      // Ideally we'd have a way to pass initialAccount.
                      // For now, let's just go to add transaction.
                      context.push('/add-transaction'); // Optimization: pass initialAccountId query param or extra
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.amount, required this.color, required this.icon});
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(4),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
