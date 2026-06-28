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
    final color = Color(account.color);
    
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
          if (account.isCash) {
            context.push('/account-details', extra: account);
          } else {
            context.push('/investment-account', extra: account);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIcon(account.iconData, color),
                  const Gap(16),
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
                          '${ref.watch(currencyProvider)}${account.isCash ? item.balance.toStringAsFixed(2) : item.totalContributionToNetWorth.abs().toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: (account.isCash ? item.balance : item.totalContributionToNetWorth) >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions Row: Edit/Delete + Quick Add
                  Row(
                    children: [
                       IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        color: theme.colorScheme.primary,
                         tooltip: 'Transfer',
                        onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.transfer}),
                      ),
                       if (account.isCash)
                         IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: theme.colorScheme.primary,
                          tooltip: 'Add Transaction',
                          onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.expense}),
                        )
                       else
                         IconButton(
                           icon: const Icon(Icons.trending_up),
                           color: theme.colorScheme.primary,
                           tooltip: 'Update P/L',
                           onPressed: () => _showPLDialog(context, ref, account),
                         ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          if (account.isCash) PopupMenuItem(
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

              if (account.isCash && (account.reservedBalance > 0 || item.balance > item.spendableBalance)) ...[
                 const Gap(12),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reserved / Goals', style: TextStyle(fontSize: 11)),
                            const Gap(4),
                            Text('${ref.watch(currencyProvider)}${(item.balance - item.spendableBalance).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(color: theme.colorScheme.outlineVariant, width: 1, height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Spendable Amount', style: TextStyle(fontSize: 11)),
                            const Gap(4),
                              Text(
                                '${ref.watch(currencyProvider)}${item.spendableBalance.toStringAsFixed(2)}', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14,
                                  color: item.spendableBalance < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                                )
                              ),
                          ],
                        ),
                     ],
                   ),
                 )
              ] else if (!account.isCash) ...[
                 const Gap(12),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.isLiability ? 'Remaining Debt' : 'Fund Wallet', style: const TextStyle(fontSize: 11)),
                            const Gap(4),
                            Text('${ref.watch(currencyProvider)}${item.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(color: theme.colorScheme.outlineVariant, width: 1, height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.isLiability ? 'Borrowed Amount' : 'Invested Amount', style: const TextStyle(fontSize: 11)),
                            const Gap(4),
                            Text('${ref.watch(currencyProvider)}${item.investedBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Container(color: theme.colorScheme.outlineVariant, width: 1, height: 30),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(account.isLiability ? 'Interest / Fees' : 'P/L', style: const TextStyle(fontSize: 11)),
                            const Gap(4),
                              Text(
                                '${item.pl >= 0 ? '+' : '-'}${ref.watch(currencyProvider)}${item.pl.abs().toStringAsFixed(2)}', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14,
                                  color: item.pl < 0 ? theme.colorScheme.error : Colors.green.shade600,
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

  Widget _buildIcon(String iconStr, Color color) {
    if (iconStr.startsWith('emoji:')) {
      final emoji = iconStr.replaceFirst('emoji:', '');
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      );
    } else if (iconStr.startsWith('material:')) {
      final code = int.tryParse(iconStr.replaceFirst('material:', ''));
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: code != null ? Icon(IconData(code, fontFamily: 'MaterialIcons'), color: color) : Icon(Icons.account_balance_wallet, color: color),
      );
    } else if (iconStr.startsWith('asset:')) {
      final assetPath = iconStr.replaceFirst('asset:', '');
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        padding: const EdgeInsets.all(10),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      );
    }
    return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.account_balance_wallet, color: color),
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
                 Text('${ref.watch(currencyProvider)}${amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
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
             await ref.read(accountsRepositoryProvider).updateAccount(account);
             if (context.mounted) Navigator.pop(context);
          }, child: const Text('Save')),
       ],
    ),
  );
}

Future<void> _showPLDialog(BuildContext context, WidgetRef ref, Account account) async {
  final controller = TextEditingController(text: (account.interestRate ?? 0).toString());
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Update Overall P/L Amount'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(
          labelText: 'Profit/Loss Amount',
          hintText: 'e.g. 500.00 or -250.00',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final val = double.tryParse(controller.text);
            if (val != null) {
               account.interestRate = val;
               await ref.read(accountsRepositoryProvider).updateAccount(account);
            }
            if (c.mounted) Navigator.pop(c);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}



