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
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Added bottom padding
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
              ...accounts.map((item) => AccountCard(item: item)),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-account'); 
        },
        icon: const Icon(Icons.add),
        label: const Text('New Wallet'),
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
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      color: theme.cardTheme.color,
      child: InkWell(
        onTap: () {
          context.push('/account-details', extra: account);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '\$${item.balance.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: item.balance >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions Row: Edit/Delete + Quick Add
                  Row(
                    children: [
                       IconButton(
                        icon: const Icon(Icons.swap_horiz_outlined),
                        color: theme.colorScheme.primary,
                        tooltip: 'Transfer',
                        onPressed: () => context.push('/add-transaction', extra: null /* Type=Transfer not passed easily here without modifying AddTransactionPage, user can switch type */),
                      ),
                       IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: theme.colorScheme.primary,
                        tooltip: 'Add Transaction',
                        onPressed: () => context.push('/add-transaction'),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.edit, size: 18), Gap(12), Text('Edit')]),
                            onTap: () => context.push('/add-account', extra: account),
                          ),
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), Gap(12), Text('Delete')]),
                            onTap: () {
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
                  )
                ],
              ),
              if (item.totalIncome > 0 || item.totalExpense > 0) ...[
                const Gap(12),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                const Gap(12),
                Row(
                  children: [
                     Expanded(child: _CompactStat(
                       label: 'Income', 
                       amount: item.totalIncome, 
                       color: Colors.teal,
                       icon: Icons.arrow_downward
                     )),
                     Container(
                       width: 1, height: 24, 
                       color: theme.colorScheme.outlineVariant.withOpacity(0.2)
                     ),
                     Expanded(child: _CompactStat(
                       label: 'Expense', 
                       amount: item.totalExpense, 
                       color: Colors.redAccent,
                       icon: Icons.arrow_upward
                     )),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.label, required this.amount, required this.color, required this.icon});
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.8)),
        const Gap(6),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
             Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
           ],
         )
      ],
    );
  }
}

