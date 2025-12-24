import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isCompact = false;

  @override
  Widget build(BuildContext context) {
    // Watch all transactions
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_isCompact ? Icons.view_agenda : Icons.view_headline),
            tooltip: _isCompact ? 'Comfortable View' : 'Concise View',
            onPressed: () => setState(() => _isCompact = !_isCompact),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Table View',
            onPressed: () => context.push('/transactions-table'),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }
          
          // Group transactions by date
          final grouped = <DateTime, List<Transaction>>{};
          for (var t in transactions) {
            final date = DateTime(t.date.year, t.date.month, t.date.day);
            if (grouped.containsKey(date)) {
              grouped[date]!.add(t);
            } else {
              grouped[date] = [t];
            }
          }
          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return accountsAsync.when(
            data: (accountsStats) {
               final accountMap = {for (var s in accountsStats) s.account.id: s.account};

               return categoriesAsync.when(
                 data: (categories) {
                   final catMap = {for (var c in categories) c.id: c};
                   
                   return ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayTransactions = grouped[date]!;
                      dayTransactions.sort((a, b) => b.date.compareTo(a.date)); // Ensure newest on top
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest 
                                    : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat.yMMMd().format(date),
                                style: TextStyle(
                                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12
                                ),
                              ),
                            ),
                          ),
                          ...dayTransactions.map((t) {
                            final accountId = t.type == TransactionType.income ? t.toAccountId : t.fromAccountId;
                            final accountName = accountId != null ? accountMap[accountId]?.name ?? 'Unknown' : 'Unknown';
                            final category = t.categoryId != null ? catMap[t.categoryId] : null;

                            return TransactionTile(
                              transaction: t,
                              accountName: accountName,
                              category: category,
                              compact: _isCompact,
                              onTap: () {
                                 context.push('/transaction-details', extra: t);
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                 },
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (e, s) => Center(child: Text('Error loading categories: $e')),
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading accounts: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
