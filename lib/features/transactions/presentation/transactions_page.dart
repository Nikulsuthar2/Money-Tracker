import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recent transactions provider
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.subscriptions),
            tooltip: 'Subscriptions',
            onPressed: () => context.push('/subscriptions'),
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
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-transaction');
        },
        icon: const Icon(Icons.post_add),
        label: const Text('New Transaction'),
      ),
    );
  }
}
