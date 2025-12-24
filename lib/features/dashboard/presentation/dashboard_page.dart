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
import 'package:money_manager/features/subscriptions/presentation/subscriptions_page.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {

  @override
  void initState() {
    super.initState();
    // Delay check to allow UI to build
    Future.microtask(() => _checkDueSubscriptions());
  }

  Future<void> _checkDueSubscriptions() async {
    final subsStream = ref.read(subscriptionsStreamProvider.stream);
    // Get current list (not just one update)
    final subs = await subsStream.first;
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    final due = subs.where((s) => s.isActive && s.startDate.isBefore(todayStart.add(const Duration(days: 1)))).toList();
    
    if (due.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${due.length} Subscriptions Due'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: due.map((s) => ListTile(
              title: Text(s.name),
              trailing: Text('\$${s.amount.toStringAsFixed(2)}'),
              dense: true,
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                _processSubscriptions(due);
                Navigator.pop(context);
              },
              child: const Text('Process & Pay'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processSubscriptions(List<Subscription> dueSubs) async {
    final transactionRepo = ref.read(transactionsRepositoryProvider);
    final subRepo = ref.read(subscriptionsRepositoryProvider);
    // Fetch categories to determine Income/Expense
    final categories = await ref.read(categoriesStreamProvider.future);
    final catMap = {for (var c in categories) c.id: c};
    
    for (final sub in dueSubs) {
      final category = sub.categoryId != null ? catMap[sub.categoryId] : null;
      final type = category?.type == CategoryType.income ? TransactionType.income : TransactionType.expense;

      // 1. Create Transaction
      final t = Transaction()
        ..amount = sub.amount
        ..date = DateTime.now()
        ..type = type
        ..categoryId = sub.categoryId
        ..note = 'Auto-Subscription: ${sub.name}';
      
      // Assign Account Correctly
      if (type == TransactionType.income) {
          t.toAccountId = sub.accountId;
      } else {
          t.fromAccountId = sub.accountId;
      }
        
      t.subscriptionId = sub.id;

      await transactionRepo.addTransaction(t);

      // 2. Update Subscription Date
      final nextDate = _calculateNextDate(sub.startDate, sub.repeat);
      sub.startDate = nextDate;
      sub.lastPaymentDate = DateTime.now();
      
      await subRepo.updateSubscription(sub);
    }

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processed ${dueSubs.length} subscriptions')));
    }
  }

  DateTime _calculateNextDate(DateTime current, SubscriptionRepeat repeat) {
    switch (repeat) {
      case SubscriptionRepeat.daily: return current.add(const Duration(days: 1));
      case SubscriptionRepeat.weekly: return current.add(const Duration(days: 7));
      case SubscriptionRepeat.monthly: return DateTime(current.year, current.month + 1, current.day);
      case SubscriptionRepeat.yearly: return DateTime(current.year + 1, current.month, current.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total Balance
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider);
    // Recent Transactions
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    // For Chart: Watch all transactions
    final allTransactionsAsync = ref.watch(transactionsStreamProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
        children: [
          // Total Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                ),
                const Gap(20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                       accountsWithBalance.when(
                         data: (list) {
                           final total = list.fold(0.0, (sum, item) => sum + item.balance);
                           return Text(
                             '\$${total.toStringAsFixed(2)}',
                             style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                           );
                         },
                         loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                         error: (e,s) => const Text('Error', style: TextStyle(color: Colors.white)),
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Accounts Section
          Text('My Wallets', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          accountsWithBalance.when(
            data: (accounts) {
              if (accounts.isEmpty) return const Text('No wallets yet.');
              return Column(
                children: accounts.map((item) => AccountCard(item: item)).toList(),
              );
            },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (_,__) => const Text('Error loading accounts'),
          ),
          const Gap(24),
          
          // Chart Section
          Text('Spending Trend (Last 30 Days)', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          SizedBox(
            height: 200,
            child: allTransactionsAsync.when(
              data: (transactions) {
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
                     final x = 29 - daysAgo;
                     daySpots[x] = (daySpots[x] ?? 0) + t.amount;
                  }
                }

                final spots = daySpots.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
                  ..sort((a,b) => a.x.compareTo(b.x));

                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16), // Padding for tooltip overflow
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                         show: true,
                         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         bottomTitles: AxisTitles(
                           sideTitles: SideTitles(
                             showTitles: true,
                             getTitlesWidget: (value, meta) {
                               final index = value.toInt();
                               if (index >= 0 && index < 30) {
                                  // Show one label every 5 days
                                  if (index % 5 == 0 || index == 29) {
                                     final date = DateTime.now().subtract(Duration(days: 29 - index));
                                     return Padding(
                                       padding: const EdgeInsets.only(top: 8.0),
                                       child: Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                     );
                                  }
                               }
                               return const SizedBox.shrink();
                             },
                             reservedSize: 30,
                           )
                         ),
                      ),
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
                       lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            fitInsideHorizontally: true, // Prevent horizontal overflow
                            fitInsideVertically: true, // Prevent vertical overflow
                            getTooltipItems: (touchedSpots) {
                               return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  final date = DateTime.now().subtract(Duration(days: 29 - index));
                                  return LineTooltipItem(
                                    '${DateFormat('MMM d').format(date)}\n',
                                    TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12),
                                    children: [
                                      TextSpan(
                                        text: '\$${spot.y.toStringAsFixed(0)}', 
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)
                                      ),
                                    ]
                                  );
                               }).toList();
                            }
                          ),
                       ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text('Error loading chart')),
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
          recentTransactionsAsync.when(
            data: (txs) {
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text('Error loading transactions'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-account'),
        icon: const Icon(Icons.add_card),
        label: const Text('New Wallet'),
      ),
    );
  }
}
