import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
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
                  '\$${t.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: color, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Gap(8),
                Text(
                  t.type.name.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold
                  ),
                ),
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
                  if (t.note?.isNotEmpty == true) ...[
                     _DetailRow(icon: Icons.notes, label: 'Note', value: t.note!),
                     const Divider(),
                  ],
                  // Ideally we show account/category names here too by fetching them
                  FutureBuilder(
                    future: ref.read(accountsRepositoryProvider).getAllAccounts(),
                    builder: (context, snapshot) {
                       final accounts = snapshot.data ?? [];
                       final from = accounts.where((a) => a.id == t.fromAccountId).firstOrNull?.name;
                       final to = accounts.where((a) => a.id == t.toAccountId).firstOrNull?.name;
                       
                       String acctStr = 'Unknown';
                       if (t.type == TransactionType.income && to != null) acctStr = to;
                       if (t.type == TransactionType.expense && from != null) acctStr = from;
                       if (t.type == TransactionType.transfer) acctStr = '$from -> $to';
                       
                       return _DetailRow(icon: Icons.account_balance_wallet, label: 'Account', value: acctStr);
                    }
                  ),
                ],
              ),
            ),
          ),
          
          const Gap(24),
          
          // Splits
          if (t.subTransactions != null && t.subTransactions!.isNotEmpty) ...[
            Text('Split Details', style: theme.textTheme.titleMedium),
            const Gap(8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: t.subTransactions!.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final split = t.subTransactions![index];
                  return ListTile(
                    title: Text(split.note?.isNotEmpty == true ? split.note! : 'Item ${index + 1}'),
                    subtitle: split.isMine ? const Text('My Expense', style: TextStyle(fontSize: 12, color: Colors.green)) 
                                           : const Text('Not My Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: Text('\$${split.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

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
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
