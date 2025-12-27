import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:gap/gap.dart';

import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_chart.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

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
                      Text('$currency${_calculateBalance(account, accountTransactions).toStringAsFixed(2)}', 
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing
                        children: [
                          _SummaryItem(
                            label: 'Net Income', 
                            amount: '$currency${_calculateAdjustedIncome(account, accountTransactions).toStringAsFixed(0)}', 
                            color: Colors.teal,
                            icon: Icons.arrow_downward
                          ),
                          Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant), // Better splitter
                          _SummaryItem(
                            label: 'Net Spend', 
                            amount: '$currency${_calculateNetCost(account, accountTransactions).toStringAsFixed(0)}', 
                            color: Colors.red,
                            icon: Icons.arrow_upward
                          ),
                        ],
                      ),
                      const Gap(16),
                      // Reimbursed Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.undo, size: 14, color: Colors.grey),
                            const Gap(8),
                            Text('Reimbursed: $currency${_calculateReimbursements(account, accountTransactions).toStringAsFixed(2)}',
                               style: const TextStyle(fontSize: 12, color: Colors.black87)), // Ensure visibility
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const Gap(16),

              // Chart
              Container( // Wrap in container or card
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.surface,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: theme.colorScheme.outlineVariant),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text('Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Gap(16),
                      AccountChart(transactions: accountTransactions, accountId: account.id, currency: currency),
                   ],
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
              )),
            ],
          );
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  double _calculateBalance(Account account, List<dynamic> transactions) {
     double balance = account.openingBalance;
     for (final t in transactions) {
       if (t.skipFromStats) continue;

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

  double _calculateAdjustedIncome(Account account, List<dynamic> transactions) {
     double income = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         // Exclude Repayments from "Actual Income" (it's just money coming back)
         // Check note "Repayment:" or "Refund:"
         final isRepayment = t.note != null && (t.note!.toLowerCase().contains('repayment') || t.note!.toLowerCase().contains('refund'));
         if (!isRepayment) {
            income += t.amount;
         }
       }
     }
     return income;
  }

  double _calculateNetCost(Account account, List<dynamic> transactions) {
     double expense = 0;
     double reimbursed = 0;
     
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       
       if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
         expense += t.amount;
       }
       
       // Check for repayments to deduct from expense
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         final isRepayment = t.note != null && (t.note!.toLowerCase().contains('repayment') || t.note!.toLowerCase().contains('refund'));
         if (isRepayment) {
            reimbursed += t.amount;
         }
       }
     }
     return expense - reimbursed;
  }

  double _calculateReimbursements(Account account, List<dynamic> transactions) {
     double reimbursed = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         final isRepayment = t.note != null && (t.note!.toLowerCase().contains('repayment') || t.note!.toLowerCase().contains('refund'));
         if (isRepayment) {
            reimbursed += t.amount;
         }
       }
     }
     return reimbursed;
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData? icon;
  const _SummaryItem({required this.label, required this.amount, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: color), const Gap(4)],
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
