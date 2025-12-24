import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/presentation/transactions_page.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_chart.dart';

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: transactionsAsync.when(
        data: (allTransactions) {
          // Filter transactions for this account
          final accountTransactions = allTransactions.where((t) => 
            t.fromAccountId == account.id || t.toAccountId == account.id
          ).toList();

          accountTransactions.sort((a, b) => b.date.compareTo(a.date)); // Descending

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Current Balance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                      const Gap(8),
                      Text('\$${_calculateBalance(account, accountTransactions).toStringAsFixed(2)}', 
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              
              const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Gap(8),
              
              if (accountTransactions.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No transactions found'))),

              ...accountTransactions.map((t) => TransactionTile(
                  transaction: t, 
                  accountName: account.name, 
                  onTap: () => context.push('/transaction-details', extra: t),
              )).toList(),
            ],
          );
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  double _calculateBalance(Account account, List<dynamic> transactions) {
     // If we trust the passed account balance:
     // return account.balance; // But account structure doesn't store balance? 
     // Ah, AccountStats does. The Account object itself does not have a balance field usually.
     // Let's check Account domain.
     // Wait, in accounts_page we calculate it from stats.
     // Here we just have Account.
     // So we must calculate it from Opening Balance + Transactions.
     
     double balance = account.openingBalance;
     for (final t in transactions) {
       // We need to iterate chronologically to build a graph, but for total current balance:
       // If Income -> +Amount
       // If Expense -> -Amount
       // If Transfer -> -Amount (if From) / +Amount (if To)
       
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         balance += t.amount;
       } else if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
         balance -= t.amount;
       } else if (t.type == TransactionType.transfer) {
         if (t.fromAccountId == account.id) balance -= t.amount;
         if (t.toAccountId == account.id) balance += t.amount;
       }
     }
     return balance;
  }
}
