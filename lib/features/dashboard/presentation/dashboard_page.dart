import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Total Balance
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider);
    // Recent Transactions
    final recentTransactions = ref.watch(transactionsRepositoryProvider).watchRecentTransactions();
    // For Chart: Watch all transactions
    final allTransactionsStream = ref.watch(transactionsRepositoryProvider).watchAllTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   Text('Total Balance', style: Theme.of(context).textTheme.titleMedium),
                   const Gap(8),
                   accountsWithBalance.when(
                     data: (list) {
                       final total = list.fold(0.0, (sum, item) => sum + item.balance);
                       return Text(
                         '\$${total.toStringAsFixed(2)}',
                         style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                       );
                     },
                     loading: () => const CircularProgressIndicator(),
                     error: (e,s) => Text('Error', style: TextStyle(color: Colors.red)),
                   ),
                ],
              ),
            ),
          ),
          const Gap(24),
          
          // Chart Section
          Text('Spending Trend (Last 30 Days)', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<Transaction>>(
              stream: allTransactionsStream,
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                 if (snapshot.hasError) return const Center(child: Text('Error loading chart'));
                 
                 final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) return const Center(child: Text('Not enough data'));
                
                // 1. Filter expenses last 30 days
                final now = DateTime.now();
                final thirtyDaysAgo = now.subtract(const Duration(days: 30));
                final expenses = transactions.where((t) => 
                  t.type == TransactionType.expense && 
                  t.date.isAfter(thirtyDaysAgo)
                ).toList();

                if (expenses.isEmpty) return const Center(child: Text('No expenses in last 30 days'));

                // 2. Group by day
                final Map<int, double> daySpots = {};
                // Initialize last 30 days with 0
                for (int i = 0; i < 30; i++) {
                   daySpots[i] = 0.0;
                }

                for (var t in expenses) {
                  final daysAgo = now.difference(t.date).inDays;
                  if (daysAgo >= 0 && daysAgo < 30) {
                     // Reverse index: 0 = today, 29 = 30 days ago. 
                     // For chart left-to-right (old to new): x=0 is 30 days ago, x=29 is today.
                     final x = 29 - daysAgo;
                     daySpots[x] = (daySpots[x] ?? 0) + t.amount;
                  }
                }

                final spots = daySpots.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
                  ..sort((a,b) => a.x.compareTo(b.x));

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
              TextButton(onPressed: () => context.go('/transactions'), child: const Text('See All')),
            ],
          ),
          const Gap(8),
          StreamBuilder<List<Transaction>>(
            stream: recentTransactions,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final txs = snapshot.data!;
              if (txs.isEmpty) return const Text('No recent transactions');

              return accountsWithBalance.when(
                data: (accountsStats) {
                   final accountMap = {for (var s in accountsStats) s.account.id: s.account.name};
                   
                   return Column(
                    children: txs.map((t) {
                       final accountId = t.type == TransactionType.income ? t.toAccountId : t.fromAccountId;
                       final accountName = accountId != null ? accountMap[accountId] ?? 'Unknown' : 'Unknown';
                       
                       return TransactionTile(
                         transaction: t, 
                         accountName: accountName,
                         onTap: () => context.push('/transaction-details', extra: t),
                       );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_,__) => const SizedBox(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
