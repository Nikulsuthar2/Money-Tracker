import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';

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
                        onPressed: () => context.push('/add-transaction', extra: null),
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
