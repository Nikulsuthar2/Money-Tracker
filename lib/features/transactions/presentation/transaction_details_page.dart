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
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/ledger/presentation/widgets/ledger_entry_compact_tile.dart';

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
                Consumer(
                  builder: (context, ref, _) {
                     final symbol = ref.watch(currencyProvider);
                     return Text(
                       CurrencyFormatter.format(t.amount, symbol: symbol),
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                       // Always show Account Chip logic
                       if (t.type == TransactionType.transfer) {
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
                         // Income/Expense
                         final account = t.type == TransactionType.income ? to : from;
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
                              customValue: _Chip(icon: Icons.compare_arrows, label: 'Self Transfer', color: theme.colorScheme.outline),
                           )
                        else if (t.subTransactions != null && t.subTransactions!.isNotEmpty)
                           FutureBuilder<List<Category>>(
                              future: ref.read(categoriesRepositoryProvider).getAllCategories(),
                              builder: (context, snapshot) {
                                 final allCats = snapshot.data ?? [];
                                 // Get unique category IDs from splits
                                 final splitCatIds = t.subTransactions!
                                    .map((s) => s.categoryId)
                                    .whereType<int>()
                                    .toSet();
                                 
                                 if (splitCatIds.isEmpty) return const SizedBox.shrink();

                                 return Padding(
                                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                        Row(
                                          children: [
                                            Icon(Icons.category, size: 20, color: theme.colorScheme.secondary),
                                            const Gap(16),
                                            Text('Categories', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                                          ],
                                        ),
                                        const Gap(8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: splitCatIds.map((id) {
                                             final cat = allCats.where((c) => c.id == id).firstOrNull;
                                             if (cat == null) return const SizedBox.shrink();
                                             return _Chip(
                                                icon: IconData(cat.icon, fontFamily: 'MaterialIcons'), 
                                                label: cat.name,
                                                color: theme.colorScheme.primary.withOpacity(0.7)
                                             );
                                          }).toList(),
                                        ),
                                     ],
                                   ),
                                 );
                              }
                           )
                        else
                           // Single Category
                           FutureBuilder<Category?>(
                             future: t.categoryId != null 
                                ? ref.read(categoriesRepositoryProvider).getCategory(t.categoryId!) 
                                : Future.value(null),
                             builder: (context, snapshot) {
                                final cat = snapshot.data;
                                // If Category is null, check if it's a Settlement
                                if (cat == null) {
                                   if (t.mode == TransactionMode.settlement) {
                                      return _DetailRow(
                                         icon: Icons.handshake,
                                         label: 'Category',
                                         customValue: _Chip(
                                            icon: Icons.handshake,
                                            label: 'Settlement',
                                            color: Colors.blue,
                                         )
                                      );
                                   }
                                   return const SizedBox.shrink();
                                }
                                
                                return _DetailRow(
                                  icon: Icons.category, 
                                  label: 'Category', 
                                  customValue: _Chip(
                                     icon: IconData(cat.icon, fontFamily: 'MaterialIcons'), 
                                     label: cat.name,
                                     color: theme.colorScheme.primary, 
                                  )
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
            Card(
              clipBehavior: Clip.hardEdge,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: t.subTransactions!.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final split = t.subTransactions![index];
                    final isRefunded = split.isRefunded; 
                    
                      return FutureBuilder<Category?>(
                        future: split.categoryId != null 
                           ? ref.read(categoriesRepositoryProvider).getCategory(split.categoryId!)
                           : Future.value(null),
                        builder: (context, catSnapshot) {
                           final category = catSnapshot.data;

                           // Determine Icon / Label
                           // If Category is null, check if it's settlement or just "No Category"
                           // We generally treat party-splits without category as "Settlement" or "Split"
                           // User asked: "in split details it should display settlement icon not any general category icon" if settlement.
                           
                           final isSettlement = split.categoryId == null; // Simple heuristic if no other flag
                           final displayIcon = category != null 
                               ? IconData(category.icon, fontFamily: 'MaterialIcons') 
                               : (isSettlement ? Icons.handshake : Icons.category);
                           
                           final iconColor = category != null ? theme.colorScheme.primary : (isSettlement ? Colors.blue : Colors.grey);
                           final title = category?.name ?? (isSettlement ? 'Settlement' : 'Uncategorized');

                           return FutureBuilder<Party?>(
                             future: split.partyId != null 
                                 ? ref.read(partyRepositoryProvider).getAllParties().then((list) => list.where((p) => p.id == split.partyId).firstOrNull)
                                 : Future.value(null),
                             builder: (context, snapshot) {
                                 final partyName = snapshot.data?.name;
                                 
                                 return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                         // Leading Icon (Category or Settlement)
                                         Container(
                                           width: 40, height: 40,
                                           decoration: BoxDecoration(
                                             color: iconColor.withOpacity(0.1),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: Icon(displayIcon, color: iconColor, size: 20),
                                         ),
                                         const Gap(16),
                                         
                                         // Content
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                
                                                // Subtitle: Person Name + Note (bullet separated)
                                                if (partyName != null || (split.note?.isNotEmpty == true))
                                                  Row(
                                                    children: [
                                                       if (partyName != null) ...[
                                                          Icon(Icons.person, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                                          const Gap(4),
                                                          Text(partyName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                                       ],
                                                       
                                                       if (partyName != null && (split.note?.isNotEmpty == true)) ...[
                                                          const Gap(6),
                                                          Text('•', style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                                                          const Gap(6),
                                                       ],

                                                       if (split.note?.isNotEmpty == true)
                                                          Expanded(child: Text(split.note!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                                                    ],
                                                  )
                                                else 
                                                  Text(split.isMine ? 'My Share' : 'Their Share', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                             ],
                                           ),
                                         ),
                                         
                                         // Amount (Formatted)
                                         Consumer(
                                           builder: (context, ref, _) {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                     CurrencyFormatter.format(split.amount, symbol: ref.read(currencyProvider)), 
                                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                                  ),
                                                  if (isRefunded)
                                                    const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle, size: 12, color: Colors.green))
                                                ],
                                              );
                                           }
                                         )
                                      ],
                                    ),
                                 );
                             }
                           );
                        }
                      );
                  },
                ),
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
                     children: entries.map((e) => Card(
                       elevation: 0,
                       color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
                       margin: const EdgeInsets.only(bottom: 8),
                       child: ListTile(
                         leading: const Icon(Icons.book, color: Colors.purple),
                         title: FutureBuilder<Party?>(
                            future: ref.read(partyRepositoryProvider).getAllParties().then((l) => l.where((p) => p.id == e.partyId).firstOrNull),
                            builder: (c, s) => Text(s.data?.name ?? 'Party #${e.partyId}'),
                         ),
                         subtitle: Text(e.note ?? e.nature.name.toUpperCase()),
                         trailing: Text(
                            // OWE = Positive (They Owe Me). PAID = Negative (I paid them) or Positive (They paid me)?
                            // Ledger Entry amount logic:
                            // OWE: Always + (if I paid expense).
                            // PAID: Logic in Repo says: Expense(I paid) -> Negative Amount. Income(They paid) -> Positive Amount.
                            // So we can just trust the signed amount.
                            // Positive = Green (Receivable / Received). Negative = Red (Payable / Paid out).
                            '\$${e.amount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: e.amount > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold
                            )
                         ),
                       ),
                     )).toList(),
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
        children: [
          const Icon(Icons.account_balance_wallet, size: 14),
          const Gap(8),
          Text(account.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

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
        children: [
          Icon(icon, size: 16, color: color ?? Theme.of(context).iconTheme.color),
          const Gap(8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
