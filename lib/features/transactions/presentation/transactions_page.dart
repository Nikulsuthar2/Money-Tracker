import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recent transactions stream
    final transactionsStream = ref.watch(transactionsRepositoryProvider).watchRecentTransactions();
    final accountsAsync = ref.watch(accountsRepositoryProvider).watchAllAccounts();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: StreamBuilder<List<Transaction>>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final transactions = snapshot.data ?? [];
          
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

          return StreamBuilder<List<Account>>(
            stream: accountsAsync,
            builder: (context, accountSnapshot) {
               final accounts = accountSnapshot.data ?? [];
               final accountMap = {for (var a in accounts) a.id: a};

               return ListView.builder(
            padding: const EdgeInsets.all(16),
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

                    return TransactionTile(
                      transaction: t,
                      accountName: accountName,
                      onTap: () {
                         context.push('/transaction-details', extra: t);
                      },
                    );
                  }).toList(),
                  }).toList(),
                ],
              );
            },
          );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-transaction');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
