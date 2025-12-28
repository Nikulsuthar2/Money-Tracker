import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/accounts/domain/account.dart';

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
                          '${ref.watch(currencyProvider)}${item.balance.toStringAsFixed(2)}',
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
                        onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.transfer}),
                      ),
                       IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: theme.colorScheme.primary,
                        tooltip: 'Add Transaction',
                        onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.expense}),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.lock, size: 18, color: Colors.orange), Gap(12), Text('Manage Reserved')]),
                            onTap: () {
                               Future.delayed(Duration.zero, () {
                                 if (context.mounted) _showSavingsDialog(context, ref, account);
                               });
                            },
                          ),
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

              if (account.reservedBalance > 0) ...[
                 const Gap(12),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reserved Amount', style: TextStyle(fontSize: 10)),
                            Text('${ref.watch(currencyProvider)}${account.reservedBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Container(color: theme.colorScheme.outline, width: 1, height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Spendable Amount', style: TextStyle(fontSize: 10)),
                              Text(
                                '${ref.watch(currencyProvider)}${(item.balance - account.reservedBalance - account.buckets.fold(0.0, (sum, b) => sum + b.balance)).toStringAsFixed(2)}', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  color: (item.balance - account.reservedBalance - account.buckets.fold(0.0, (sum, b) => sum + b.balance)) < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                                )
                              ),
                          ],
                        ),
                     ],
                   ),
                 )
              ],
              if (item.totalIncome > 0 || item.totalExpense > 0) ...[
                const Gap(12),
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                const Gap(12),
                Row(
                  children: [
                     Expanded(child: _CompactStat(label: 'Total In', amount: item.totalIncome, color: Colors.teal.withOpacity(0.7), icon: Icons.arrow_downward)),
                     Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                     Expanded(child: _CompactStat(label: 'Total Out', amount: item.totalExpense, color: Colors.redAccent.withOpacity(0.7), icon: Icons.arrow_upward)),
                  ],
                ),

              ],
              
              
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
    // Need ref here? No, pass symbol or use Consumer. 
    // CompactStat is StatelessWidget. Let's make it ConsumerWidget or just pass context read (bad).
    // Better: wrap in Consumer inside build.
    return Consumer(
      builder: (context, ref, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.8)),
            const Gap(6),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                 Text('${ref.watch(currencyProvider)}${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
               ],
             )
          ],
        );
      }
    );
  }
}

Future<void> _showSavingsDialog(BuildContext context, WidgetRef ref, Account account) async {
  final controller = TextEditingController(text: account.reservedBalance > 0 ? account.reservedBalance.toStringAsFixed(2) : '');
  
  await showDialog(
    context: context, 
    builder: (context) => AlertDialog(
       title: const Text('Manage Reserved Funds'),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
             const Text('Balance set aside here is LOCKED from "Spendable" limits. Use this for emergency funds or specific goals.'),
            const Gap(16),
            Consumer(
              builder: (context, ref, _) {
                return TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Reserved Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '${ref.watch(currencyProvider)} ',
                  ),
                );
              }
            ),
         ],
       ),
       actions: [
         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
             final val = double.tryParse(controller.text) ?? 0.0;
             account.reservedBalance = val;
             account.reservedLimit = val; // Also update limit to match
             await ref.read(accountsRepositoryProvider).updateAccount(account);
             if (context.mounted) Navigator.pop(context);
          }, child: const Text('Save')),
       ],
    ),
  );
}

