import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/ledger/data/party_repository.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/ledger/presentation/widgets/ledger_entry_compact_tile.dart';

import 'package:money_manager/core/widgets/icon_utils.dart';

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
                FutureBuilder<Category?>(
                  future: t.categoryId != null ? ref.read(categoriesRepositoryProvider).getCategory(t.categoryId!) : Future.value(null),
                  builder: (context, snapshot) {
                     final cat = snapshot.data;
                     if (cat != null) {
                         return buildIconWidget(cat.iconData, Color(cat.color), size: 84);
                     } else {
                         IconData iconData = t.type == TransactionType.income ? Icons.arrow_downward : 
                                             t.type == TransactionType.expense ? Icons.arrow_upward : Icons.compare_arrows;
                         if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                            iconData = Icons.call_split;
                         }
                         return Container(
                           width: 84,
                           height: 84,
                           decoration: BoxDecoration(
                             color: color.withValues(alpha: 0.15),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             iconData,
                             size: 84 * 0.6,
                             color: color,
                           ),
                         );
                     }
                  }
                ),
                const Gap(16),
                Text(
                  (t.title?.isNotEmpty == true) ? t.title! : t.type.name.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Consumer(
                  builder: (context, ref, _) {
                     final symbol = ref.watch(currencyProvider);
                     return Text(
                       '$symbol${formatAmount(t.amount)}',
                       style: theme.textTheme.displayMedium?.copyWith(
                         color: color, 
                         fontWeight: FontWeight.w900,
                         letterSpacing: -1,
                       ),
                     );
                  }
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.calendar_today, label: 'Date', value: t.hasTime ? DateFormat.yMMMd().add_jm().format(t.date) : DateFormat.yMMMd().format(t.date)),
                  const Divider(),
                  // Ideally we show account/category names here too by fetching them
                  FutureBuilder(
                    future: ref.read(accountsRepositoryProvider).getAllAccounts(),
                    builder: (context, snapshot) {
                       final accounts = snapshot.data ?? [];
                       final from = accounts.where((a) => a.id == t.fromAccountId).firstOrNull;
                       final to = accounts.where((a) => a.id == t.toAccountId).firstOrNull;
                       
                       Widget valWidget;
                       // Always show Account Chip logic
                       if (t.type == TransactionType.transfer && !t.isSettlement) {
                          valWidget = Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                               _AccountChip(account: from),
                               const Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 4),
                                 child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                               ),
                               _AccountChip(account: to),
                               const Gap(8),
                            ],
                          );
                       } else {
                         // Income/Expense or Legacy Settlement
                         final account = (t.type == TransactionType.income || (t.isSettlement && t.toAccountId != null)) ? to : from;
                         valWidget = _AccountChip(account: account);
                       }
                       
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        _DetailRow(icon: Icons.account_balance_wallet, label: 'Account', customValue: valWidget),
                        
                        const Divider(),

                        // Category / Transfer / Split Chips
                         if (t.type == TransactionType.transfer)
                            _DetailRow(
                               icon: Icons.swap_horiz,
                               label: 'Category',
                               customValue: _Chip(iconWidget: const Icon(Icons.compare_arrows, size: 16), label: 'Self Transfer'),
                            )
                        else
                           FutureBuilder<List<Expense>>(
                             future: ref.read(expensesRepositoryProvider).getAllExpenses(),
                             builder: (context, expSnapshot) {
                               final expenses = expSnapshot.data?.where((e) => e.transactionId == t.id).toList() ?? [];
                               if (expenses.isNotEmpty) {
                                  return FutureBuilder<List<Category>>(
                                     future: ref.read(categoriesRepositoryProvider).getAllCategories(),
                                     builder: (context, catSnapshot) {
                                        final allCats = catSnapshot.data ?? [];
                                        final splitCatIds = expenses.map((s) => s.categoryId).whereType<int>().toSet();
                                        
                                        if (splitCatIds.isEmpty) {
                                            if (t.isSettlement) {
                                                return _DetailRow(
                                                   icon: Icons.handshake,
                                                   label: 'Category',
                                                   customValue: _Chip(
                                                       iconWidget: const Icon(Icons.handshake, size: 16, color: Colors.blue),
                                                       label: 'Settlement',
                                                   )
                                                );
                                            }
                                            return _DetailRow(
                                              icon: Icons.category,
                                              label: 'Category',
                                              customValue: _Chip(
                                                  iconWidget: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                                                  label: 'Uncategorized',
                                              )
                                            );
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Row(
                                               children: [
                                                 Icon(Icons.category, size: 20, color: theme.colorScheme.secondary),
                                                 const Gap(16),
                                                 Expanded(
                                                   child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       Text('Categories', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                                                       const Gap(8),
                                                       Wrap(
                                                         spacing: 8,
                                                         runSpacing: 8,
                                                         children: splitCatIds.map((id) {
                                                           final cat = allCats.where((c) => c.id == id).firstOrNull;
                                                           if (cat == null) return const SizedBox.shrink();
                                                           return _Chip(
                                                               iconWidget: buildIconWidget(cat.iconData, Color(cat.color), size: 20, circle: false), 
                                                               label: cat.name,
                                                           );
                                                         }).toList(),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ],
                                             ),
                                        );
                                     }
                                  );
                               }

                               // Single Category
                               return FutureBuilder<Category?>(
                                 future: t.categoryId != null 
                                    ? ref.read(categoriesRepositoryProvider).getCategory(t.categoryId!) 
                                    : Future.value(null),
                                 builder: (context, snapshot) {
                                    final cat = snapshot.data;
                                    if (cat == null) {
                                       if (t.isSettlement || t.mode == TransactionMode.settlement || t.hasLedgerEntries) {
                                          return _DetailRow(
                                             icon: Icons.handshake,
                                             label: 'Category',
                                             customValue: _Chip(
                                                iconWidget: const Icon(Icons.handshake, size: 16, color: Colors.blue),
                                                label: 'Settlement',
                                             )
                                          );
                                       }
                                       return _DetailRow(
                                          icon: Icons.category,
                                          label: 'Category',
                                          customValue: _Chip(
                                              iconWidget: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                                              label: 'Uncategorized',
                                          )
                                       );
                                    }
                                    
                                   return _DetailRow(
                                      icon: Icons.category, 
                                      label: 'Category', 
                                      customValue: _Chip(
                                         iconWidget: buildIconWidget(cat.iconData, Color(cat.color), size: 20, circle: false), 
                                         label: cat.name,
                                      )
                                    );
                                 }
                               );
                             }
                           ),
                     ],
                  );
               }
            ),
          ],
        ),
      ),
    ),
          
          if (t.note?.isNotEmpty == true) ...[
            const Gap(16),
             Card(
               color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
          FutureBuilder<List<Expense>>(
            future: ref.read(expensesRepositoryProvider).getAllExpenses(),
            builder: (context, expSnapshot) {
               if (!expSnapshot.hasData) return const SizedBox.shrink();
               final expenses = expSnapshot.data!.where((e) => e.transactionId == t.id).toList();
               if (expenses.isEmpty) return const SizedBox.shrink();
               
               return FutureBuilder<List<ExpenseSplit>>(
                  future: ref.read(expensesRepositoryProvider).getAllExpenseSplits(),
                  builder: (context, splitSnapshot) {
                     if (!splitSnapshot.hasData) return const SizedBox.shrink();
                     final allSplits = splitSnapshot.data!;
                     
                     final peopleMap = ref.watch(peopleStreamProvider).value?.fold<Map<int, String>>({}, (map, p) {
                        map[p.id] = p.name;
                        return map;
                     }) ?? {};

                     return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Split Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                           const Gap(8),
                            Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: expenses.length,
                                separatorBuilder: (c, i) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                   final e = expenses[index];
                                   final splits = allSplits.where((s) => s.expenseId == e.id).toList();
                                   
                                   return FutureBuilder<Category?>(
                                      future: e.categoryId != null ? ref.read(categoriesRepositoryProvider).getCategory(e.categoryId!) : Future.value(null),
                                      builder: (context, catSnap) {
                                         final c = catSnap.data;
                                         final title = e.note?.isNotEmpty == true ? e.note! : (c?.name ?? 'Item');
                                         final iconWidget = c != null 
                                            ? buildIconWidget(c.iconData, Color(c.color), size: 36, circle: true)
                                            : const CircleAvatar(radius: 18, child: Icon(Icons.receipt_long, size: 20));
                                            
                                         return Padding(
                                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                           child: Row(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               iconWidget,
                                               const Gap(16),
                                               Expanded(
                                                 child: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                     const Gap(8),
                                                     Wrap(
                                                       spacing: 6,
                                                       runSpacing: 6,
                                                       children: splits.map((s) {
                                                         final personName = s.personId == 0 ? 'Me' : (peopleMap[s.personId] ?? 'Person ${s.personId}');
                                                         // If there's only one split and it matches the total, the chip is redundant unless we want to show who paid it
                                                         // But chips look nice anyway, so we show it.
                                                         return Container(
                                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                           decoration: BoxDecoration(
                                                             color: theme.colorScheme.surface,
                                                             borderRadius: BorderRadius.circular(6),
                                                             border: Border.all(color: theme.colorScheme.outlineVariant),
                                                           ),
                                                           child: Row(
                                                             mainAxisSize: MainAxisSize.min,
                                                             children: [
                                                               Icon(s.personId == 0 ? Icons.person : Icons.person_outline, size: 12, color: theme.colorScheme.primary),
                                                               const Gap(4),
                                                               Text(personName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                                               const Gap(4),
                                                               Consumer(builder: (ctx, r, _) => Text(
                                                                 '${r.read(currencyProvider)}${formatAmount(s.amount)}', 
                                                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
                                                               )),
                                                             ],
                                                           ),
                                                         );
                                                       }).toList(),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                               const Gap(16),
                                               Consumer(builder: (ctx, r, _) => Text('${r.read(currencyProvider)}${formatAmount(e.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                             ],
                                           ),
                                         );
                                      }
                                   );
                                },
                              ),
                            ),
                        ],
                     );
                  }
               );
            }
          ),
          
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

          // Mode Badge
          if (t.mode == TransactionMode.settlement)
             Center(
               child: Chip(
                 label: const Text('Settlement Transaction'),
                 avatar: const Icon(Icons.handshake, size: 16),
                 backgroundColor: theme.colorScheme.primaryContainer,
               ),
             ),
             
          // Refund/Skip Badge (New Toggle)
          if (t.skipFromStats && t.type == TransactionType.income)
             Center(
               child: Chip(
                 label: const Text('Refund (Skipped from Stats)'),
                 avatar: const Icon(Icons.replay, size: 16),
               ),
             ),
          // Ledger Entries Section
          if (t.hasLedgerEntries) ...[
             const Gap(24),
             Text('Ledger Entries', style: theme.textTheme.titleMedium),
             const Gap(8),
             FutureBuilder<List<LedgerEntry>>(
                future: ref.read(transactionsRepositoryProvider).getLedgerEntries(t.id),
                builder: (context, snapshot) {
                   if (!snapshot.hasData) return const SizedBox.shrink();
                   final entries = snapshot.data!;
                   if (entries.isEmpty) return const Text('No entries found (Sync error?)');
                   
                   return Column(
                     children: entries.map((e) => LedgerEntryCompactTile(
                        entry: e, 
                     )).toList().cast<Widget>(),
                   );
                }
             ),
          ],

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
                if (customValue != null) const Gap(8),
                customValue ?? Text(value ?? '', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.account});
  final dynamic account; // Account?

  @override
  Widget build(BuildContext context) {
    if (account == null) return const Text('Unknown');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildIconWidget(account.iconData, Color(account.color), size: 24),
          const Gap(8),
          Text(account.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.iconWidget, required this.label});
  final Widget iconWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const Gap(8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


