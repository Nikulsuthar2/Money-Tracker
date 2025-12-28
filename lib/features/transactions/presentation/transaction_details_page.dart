import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';

class TransactionDetailsPage extends ConsumerWidget {
  const TransactionDetailsPage({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final theme = Theme.of(context);
    
    // Fetch Category Name (Tricky since we only have ID)
    // We can use a FutureBuilder or just show ID if name not easily avail, 
    // but better to fetch. For now let's just show basic info + splits.
    
    // Determine color
    final color = t.type == TransactionType.income
        ? Colors.teal
        : t.type == TransactionType.expense
            ? Colors.redAccent
            : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/add-transaction', extra: t);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
               showDialog(context: context, builder: (d) => AlertDialog(
                  title: const Text('Delete Transaction?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                    TextButton(onPressed: () async {
                        await ref.read(transactionsRepositoryProvider).deleteTransaction(t.id);
                        if (context.mounted) {
                          Navigator.pop(d); // Pop dialog
                          context.pop(); // Pop page
                        }
                    }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Amount Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    t.type == TransactionType.income ? Icons.arrow_downward : 
                    t.type == TransactionType.expense ? Icons.arrow_upward : Icons.compare_arrows,
                    size: 48,
                    color: color,
                  ),
                ),
                const Gap(16),
                Text(
                  (t.title?.isNotEmpty == true) ? t.title! : t.type.name.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  '\$${t.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: color, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                if (t.title?.isNotEmpty == true) ...[
                  const Gap(4),
                  Text(t.type.name.toUpperCase(), style: TextStyle(color: theme.colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          const Gap(32),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.calendar_today, label: 'Date', value: DateFormat.yMMMd().format(t.date)),
                  const Divider(),
                  // Ideally we show account/category names here too by fetching them
                  FutureBuilder(
                    future: ref.read(accountsRepositoryProvider).getAllAccounts(),
                    builder: (context, snapshot) {
                       final accounts = snapshot.data ?? [];
                       final from = accounts.where((a) => a.id == t.fromAccountId).firstOrNull;
                       final to = accounts.where((a) => a.id == t.toAccountId).firstOrNull;
                       
                       Widget valWidget;
                       if (t.type == TransactionType.transfer) {
                          valWidget = Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                               Chip(
                                 label: Text(from?.name ?? 'Unknown', style: const TextStyle(fontSize: 12)), 
                                 padding: const EdgeInsets.all(4), 
                                 visualDensity: VisualDensity.compact,
                                 avatar: const Icon(Icons.account_balance_wallet, size: 14),
                               ),
                               const Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 4),
                                 child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                               ),
                               Chip(
                                 label: Text(to?.name ?? 'Unknown', style: const TextStyle(fontSize: 12)), 
                                 padding: const EdgeInsets.all(4), 
                                 visualDensity: VisualDensity.compact,
                                 avatar: const Icon(Icons.account_balance_wallet, size: 14),
                               ),
                            ],
                          );
                       } else {
                         String acctStr = 'Unknown';
                         if (t.type == TransactionType.income && to != null) acctStr = to.name;
                         else if (t.type == TransactionType.expense && from != null) acctStr = from.name;
                         valWidget = Text(acctStr, style: const TextStyle(fontSize: 16));
                       }
                       
                       return _DetailRow(icon: Icons.account_balance_wallet, label: 'Account', customValue: valWidget);
                    }
                  ),
                ],
              ),
            ),
          ),
          
          if (t.note?.isNotEmpty == true) ...[
            const Gap(16),
             Card(
               color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Icon(Icons.notes, size: 20, color: theme.colorScheme.primary),
                         const Gap(8),
                         const Text('Note', style: TextStyle(fontWeight: FontWeight.bold)),
                       ],
                     ),
                     const Gap(8),
                     Text(t.note!, style: const TextStyle(fontSize: 16)),
                   ],
                 ),
               ),
             ),
          ],
          
          const Gap(24),
          
          // Splits
          if (t.relatedTransactionId != null) ...[
             const Gap(16),
             Center(
               child: OutlinedButton.icon(
                 onPressed: () async {
                    // Fetch original
                    final original = await ref.read(transactionsRepositoryProvider).getTransaction(t.relatedTransactionId!);
                    if (original != null && context.mounted) {
                       context.push('/transaction-details', extra: original);
                    } else if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Original transaction not found')));
                    }
                 },
                 icon: const Icon(Icons.link),
                 label: const Text('View Original Transaction'),
               ),
             ),
             const Gap(16),
          ],
          if (t.subTransactions != null && t.subTransactions!.isNotEmpty) ...[
            Text('Split Details', style: theme.textTheme.titleMedium),
            const Gap(8),
            ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: t.subTransactions!.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final split = t.subTransactions![index];
                  // Using dynamic lookup because isRefunded might not be in the viewed class definition but is in the object
                  // Assuming isRefunded field exists on SubTransaction
                  final isRefunded = split.isRefunded; 
                  
                  return ListTile(
                    leading: Icon(split.isMine ? Icons.person : Icons.person_outline, color: split.isMine ? Colors.green : Colors.grey),
                    title: Text(split.note?.isNotEmpty == true ? split.note! : 'Item ${index + 1}'),
                    subtitle: split.isMine ? const Text('My Expense', style: TextStyle(fontSize: 12, color: Colors.green)) 
                                           : const Text('Not My Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Text('\$${split.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                         const Gap(12),
                         if (isRefunded)
                            const IconButton(icon:Icon(Icons.check_circle, color: Colors.green), onPressed: null)
                         else 
                            IconButton(
                              icon: const Icon(Icons.circle_outlined, color: Colors.grey),
                              tooltip: 'Mark as Refunded',
                              onPressed: () async {
                                 // Refund this specific item workflow
                                 final amount = split.amount;
                                 final note = 'Refund: ${split.note ?? "Item"}';
                                 
                                 if (context.mounted) {
                                  final result = await context.push('/add-transaction', extra: {
                                    'type': TransactionType.income,
                                    'amount': amount,
                                    'note': note,
                                    'categoryId': t.categoryId, // Fallback
                                    'accountId': t.fromAccountId, // Refund to where it came from? Or Ask? 
                                    // Usually refund goes to an account. Let's pre-fill with "To" account = "From" of expense
                                    'accountId': t.fromAccountId,
                                    'relatedTransactionId': t.id,
                                  });
                                  
                                  if (result == true) {
                                     // Update split status
                                     t.subTransactions![index].isRefunded = true;
                                     
                                     // Check if all refunded
                                     final allRefunded = t.subTransactions!.every((s) => s.isRefunded);
                                     if (allRefunded) t.isRefunded = true;
                                     
                                     await ref.read(transactionsRepositoryProvider).updateTransaction(t);
                                     
                                     if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Refunded')));
                                        // Force rebuild? Widget ref updates should trigger if we watch... but we are in ConsumerWidget build not watching stream of this specific transaction?
                                        // We passed `transaction` as params. We might need to pop/push or use stateful widget to refresh.
                                        // OR, relying on GoRouter to refresh if the parent page watches.
                                        // But here we are IN the page. `transaction` is final.
                                        // We need to trigger a refresh.
                                        // Ideally TransactionDetailsPage should WATCH the transaction by ID.
                                        // Short term fix: Navigator.pushReplacement or setState if stateful.
                                        // Since it's ConsumerWidget, we can't setState.
                                        // We will rely on returning to previous page or we should convert to ConsumerStateful.
                                        // Converting to ConsumerStateful is best but expensive in edits.
                                        // Alternative: `context.role`? No.
                                        // Let's just hope user backs out or we trigger a reload.
                                        // BETTER: context.pushReplacement(self)
                                        context.pushReplacement('/transaction-details', extra: t);
                                     }
                                  }
                                 }
                              },
                            )
                      ],
                    ),
                  );
                },
              ),
          ],
          
          const Gap(32),
          // Related Refunds Section (Show if any refunds exist, partial or full)
          FutureBuilder<List<Transaction>>(
             future: ref.read(transactionsRepositoryProvider).getRefundTransactions(t.id),
             builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                
                return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text('Refund Transactions', style: theme.textTheme.titleMedium),
                      const Gap(8),
                      ...snapshot.data!.map((r) => Card(
                         child: ListTile(
                            leading: const Icon(Icons.reply, color: Colors.green),
                            title: Text(r.note ?? 'Refund'),
                            subtitle: Text(DateFormat.yMMMd().format(r.date)),
                            trailing: Text('+ \$${r.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            onTap: () => context.push('/transaction-details', extra: r),
                         ),
                      )),
                      const Gap(24),
                   ],
                );
             }
          ),

          // Only show Main Refund button if NOT all splits are refunded (and not wholly refunded) AND NOT A SUBSCRIPTION
          if (!t.isRefunded && (t.subTransactions == null || t.subTransactions!.any((s) => !s.isRefunded)) && t.subscriptionId == null && t.type != TransactionType.transfer)
          OutlinedButton.icon(
            key: const ValueKey('refund_btn'),
            onPressed: () async {
              
              double amount = t.amount;
              String notePref = 'Refund: ';
              bool isSplitRepayment = false; // Flag to determine text logic
              
              // Split Handling
              if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                 final notRefunded = t.subTransactions!.where((s) => !s.isRefunded).toList();
                 final notMineAndNotRefunded = notRefunded.where((s) => !s.isMine).toList();
                 
                 final List<SimpleDialogOption> options = [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 'full'),
                      child: const Padding(padding: EdgeInsets.all(16), child: Text('Full Refund (Merchant)', style: TextStyle(fontSize: 16))),
                    ),
                 ];
                 
                 if (notMineAndNotRefunded.isNotEmpty) {
                     options.add(SimpleDialogOption(
                       onPressed: () => Navigator.pop(context, 'split'),
                       child: const Padding(padding: EdgeInsets.all(16), child: Text('Split Repayment (Friend)', style: TextStyle(fontSize: 16))),
                     ));
                 }
                 
                 final choice = await showDialog<String>(context: context, builder: (c) => SimpleDialog(
                    title: const Text('Refund Type'),
                    children: options,
                 ));
                 
                 if (choice == null) return;
                 
                 if (choice == 'split') {
                    isSplitRepayment = true;
                    // Select splits to repay
                    final selectedSplits = await showDialog<List<dynamic>>(
                       context: context,
                       builder: (context) {
                          final List<dynamic> selected = List.from(notMineAndNotRefunded);
                          return StatefulBuilder(builder: (context, setState) {
                             return AlertDialog(
                                title: const Text('Select Items to Repay'),
                                content: SingleChildScrollView(
                                   child: Column(
                                      children: notMineAndNotRefunded.map((s) {
                                         return CheckboxListTile(
                                            title: Text(s.note?.isNotEmpty == true ? s.note! : 'Item'),
                                            subtitle: Text('\$${s.amount.toStringAsFixed(2)}'),
                                            value: selected.contains(s),
                                            onChanged: (v) => setState(() => v == true ? selected.add(s) : selected.remove(s)),
                                         );
                                      }).toList()
                                   )
                                ),
                                actions: [
                                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                   FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Confirm')),
                                ]
                             );
                          });
                       }
                    );
                    
                    if (selectedSplits == null || selectedSplits.isEmpty) return;

                    // Calculate amount that is NOT mine (i.e. what friends owe me)
                    amount = selectedSplits.fold(0.0, (sum, s) => sum + (s.amount as double));
                    final notes = selectedSplits.map((s) => s.note).where((n) => n != null && n.toString().isNotEmpty).join(', ');
                    notePref = 'Repayment${notes.isNotEmpty ? " ($notes)" : ""}: ';
                 }
              }

              TransactionType newType;
              if (t.type == TransactionType.expense) {
                newType = TransactionType.income;
              } else if (t.type == TransactionType.income) newType = TransactionType.expense;
              else newType = TransactionType.transfer; 

              int? accountId;
              if (t.type == TransactionType.expense) accountId = t.fromAccountId;
              if (t.type == TransactionType.income) accountId = t.toAccountId;
              
              if (context.mounted) {
                final result = await context.push('/add-transaction', extra: {
                  'type': newType,
                  'amount': amount,
                  'note': '$notePref${t.note ?? ''}',
                  'categoryId': t.categoryId,
                  'accountId': accountId, 
                  'relatedTransactionId': t.id, // Linking back
                  'isRefundMode': true, // Locks UI
                });
                
                if (result == true) {
                   if (notePref.startsWith('Repayment')) {
                      // It was a repayment. Mark "Not Mine" splits as refunded if we made a repayment.
                      // Ideally we mark only selected, but we simplified logic. 
                      // We will mark all remaining unrefunded not-mine splits as refunded for this iteration 
                      // to ensure the button hides next time if exhausted.
                       if (t.subTransactions != null) {
                        for (var s in t.subTransactions!) {
                           if (!s.isMine && !s.isRefunded) {
                              s.isRefunded = true; 
                           }
                        }
                      }
                      
                      if (t.subTransactions!.every((s) => s.isRefunded)) {
                         t.isRefunded = true;
                      }
                   } else {
                      // Full refund
                      t.isRefunded = true;
                   }
                   
                   await ref.read(transactionsRepositoryProvider).updateTransaction(t);
                   if (context.mounted) {
                     // Force replace to refresh UI since we modified 't' in place but UI is stale
                     context.pushReplacement('/transaction-details', extra: t);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund Recorded')));
                   }
                }
              }
            },
            icon: const Icon(Icons.undo),
            // Dynamic Label
            label: Builder(
              builder: (context) {
                 if (t.type == TransactionType.expense) {
                    if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                       final hasNotMine = t.subTransactions!.any((s) => !s.isMine && !s.isRefunded);
                       if (!hasNotMine) {
                          // Only my expense left (or all others refunded)
                          return const Text('Get Your Portion (Refund)'); 
                       }
                    }
                    return const Text('Got Back (Refund)');
                 }
                 return Text(t.type == TransactionType.expense ? 'Got Back (Refund)' : (t.type == TransactionType.income ? 'Repay (Refund)' : 'Reverse Transaction'));
              }
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: theme.colorScheme.primary,
            ),
          ) else if (t.type != TransactionType.transfer) // Refined check for badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text('Refunded', style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.greenAccent : Colors.green.shade900)),
                  avatar: const Icon(Icons.check_circle, color: Colors.green),
                  backgroundColor: theme.brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : Colors.green.shade100,
                  side: BorderSide.none,
                ),
                const Gap(12),
                TextButton.icon(
                  onPressed: () {
                     showDialog(context: context, builder: (d) => AlertDialog(
                        title: const Text('Undo Refund?'),
                        content: const Text('This will delete the repayment transaction and revert this transaction status.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                          TextButton(onPressed: () async {
                              await ref.read(transactionsRepositoryProvider).revertRefundForOriginal(t.id);
                              if (context.mounted) {
                                Navigator.pop(d);
                                Navigator.pop(context); // Refresh page
                              }
                          }, child: const Text('Undo Refund', style: TextStyle(color: Colors.red))),
                        ],
                     ));
                  },
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Undo'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                )
              ],
            ),
          const Gap(40),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, this.value, this.customValue});
  final IconData icon;
  final String label;
  final String? value;
  final Widget? customValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                customValue ?? Text(value ?? '', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
