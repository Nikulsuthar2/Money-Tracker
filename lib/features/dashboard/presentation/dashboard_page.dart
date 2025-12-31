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
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_card.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _trendView = 'Daily';
  bool _isTotalView = true; // true = Total (Cash Flow), false = Net (Accounting)

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
              trailing: Text('${ref.watch(currencyProvider)}${s.amount.toStringAsFixed(2)}'),
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
    
    int processedCount = 0;
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));

    for (final sub in dueSubs) {
      final category = sub.categoryId != null ? catMap[sub.categoryId] : null;
      final type = category?.type == CategoryType.income ? TransactionType.income : TransactionType.expense;

      DateTime processDate = sub.startDate;
      
      // Allow max loop to prevent infinite loop in case of error (e.g. daily repeat from 1970)
      int safety = 0;
      while (processDate.isBefore(tomorrow) && safety < 1000) {
          // 1. Create Transaction
          final t = Transaction()
            ..amount = sub.amount
            ..date = processDate
            ..type = type
            ..categoryId = sub.categoryId
            ..note = 'Auto-Subscription: ${sub.name}';
          
          if (type == TransactionType.income) {
              t.toAccountId = sub.accountId;
          } else {
              t.fromAccountId = sub.accountId;
          }
            
          t.subscriptionId = sub.id;

          await transactionRepo.addTransaction(t);
          processedCount++;

          // 2. Calculate Next Date
          processDate = _calculateNextDate(processDate, sub.repeat);
          safety++;
      }

      // Update Subscription
      sub.startDate = processDate;
      sub.lastPaymentDate = DateTime.now();
      
      await subRepo.updateSubscription(sub);
    }

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processed $processedCount transactions')));
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
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           ref.invalidate(accountsWithBalanceProvider);
           ref.invalidate(transactionsStreamProvider);
           ref.invalidate(recentTransactionsProvider);
           await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
        children: [
          // Total Balance Card
          // Stats Section
          accountsWithBalance.when(
            data: (stats) {
               double totalBalance = 0;
               for (var s in stats) {
                  totalBalance += s.balance; 
               }

               return Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [
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
                       blurRadius: 12,
                       offset: const Offset(0, 6),
                     )
                   ],
                 ),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.onPrimary, size: 32),
                       ),
                       const Gap(16),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Total Balance', 
                             style: TextStyle(
                               color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                               fontSize: 16,
                             )
                           ),
                           const Gap(4),
                           Consumer(builder: (c, ref, _) =>
                             Text(
                               '${ref.watch(currencyProvider)}${totalBalance.toStringAsFixed(2)}',
                               style: TextStyle(
                                 color: Theme.of(context).colorScheme.onPrimary,
                                 fontSize: 32,
                                 fontWeight: FontWeight.bold,
                               )
                             )
                           ),
                         ],
                       ),
                    ],
                   ),
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_,__) => const SizedBox(),
          ),
          const Gap(24),

          // Accounts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Wallets', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: () => context.push('/add-account'),
                icon: const Icon(Icons.add_card),
                tooltip: 'Add New Wallet',
              ),
            ],
          ),
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
          // Header: Financial Trend | Switch
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text('Financial Trend', style: Theme.of(context).textTheme.titleLarge),
                // Switch Total vs Net
                Container(
                   height: 32,
                   padding: const EdgeInsets.all(2),
                   decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         _buildToggleOption('Total I&E', _isTotalView, () => setState(() => _isTotalView = true)),
                         _buildToggleOption('Net I&E', !_isTotalView, () => setState(() => _isTotalView = false)),
                      ],
                   ),
                )
             ],
           ),
           const Gap(12),
           // Time Segments (Full Width)
           SizedBox(
             width: double.infinity,
             child: SegmentedButton<String>(
               segments: const [
                 ButtonSegment(value: 'Daily', label: Text('Daily'), icon: null),
                 ButtonSegment(value: 'Monthly', label: Text('Monthly'), icon: null),
                 ButtonSegment(value: 'Yearly', label: Text('Yearly'), icon: null),
               ], 
               selected: {_trendView},
               onSelectionChanged: (s) => setState(() => _trendView = s.first),
               showSelectedIcon: false, 
               style: ButtonStyle(
                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                 visualDensity: VisualDensity.compact,
               ),
             ),
           ),
          const Gap(16),
          SizedBox(
            height: 220,
            child: allTransactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) return const Center(child: Text('Not enough data'));
                
                final now = DateTime.now();
                List<FlSpot> incomeSpots = [];
                List<FlSpot> expenseSpots = [];
                double maxY = 0;
                String Function(int) bottomLabel = (i) => '';

                if (_trendView == 'Daily') {
                    // Last 30 Days (Daily Resolution)
                    for (int i = 29; i >= 0; i--) {
                       final date = now.subtract(Duration(days: i));
                       double income = 0;
                       double expense = 0;
                       for (var t in transactions) {
                          if (t.skipFromStats) continue;
                          if (t.date.year == date.year && t.date.month == date.month && t.date.day == date.day) {
                             if (_isTotalView) {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                                if (t.type == TransactionType.transfer) { income += t.amount; expense += t.amount; }
                             } else {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                             }
                          }
                       }
                       incomeSpots.add(FlSpot((29-i).toDouble(), income));
                       expenseSpots.add(FlSpot((29-i).toDouble(), expense));
                       
                       if(income > maxY) maxY = income;
                       if(expense > maxY) maxY = expense;
                    }
                     bottomLabel = (val) {
                       if (val % 5 == 0 || val == 29) {
                           final date = now.subtract(Duration(days: 29 - val));
                           return DateFormat('d/M').format(date);
                       }
                       return '';
                    };
                } else if (_trendView == 'Monthly') {
                    // Last 12 Months (Monthly Resolution)
                   for (int i = 11; i >= 0; i--) {
                       final date = DateTime(now.year, now.month - i, 1);
                       double income = 0;
                       double expense = 0;
                       for (var t in transactions) {
                          if (t.skipFromStats) continue;
                          if (t.date.year == date.year && t.date.month == date.month) {
                             if (_isTotalView) {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                                if (t.type == TransactionType.transfer) { income += t.amount; expense += t.amount; }
                             } else {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                             }
                          }
                       }
                       incomeSpots.add(FlSpot((11-i).toDouble(), income));
                       expenseSpots.add(FlSpot((11-i).toDouble(), expense));
                       
                       if(income > maxY) maxY = income;
                       if(expense > maxY) maxY = expense;
                   }
                   bottomLabel = (val) {
                       final date = DateTime(now.year, now.month - (11 - val), 1);
                       return DateFormat('MMM').format(date);
                   };
                } else if (_trendView == 'Yearly') {
                    // Last 5 Years (Yearly Resolution)
                    for (int i = 4; i >= 0; i--) {
                       final year = now.year - i;
                       double income = 0;
                       double expense = 0;
                       for (var t in transactions) {
                          if (t.skipFromStats) continue;
                          if (t.date.year == year) {
                             if (_isTotalView) {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                                if (t.type == TransactionType.transfer) { income += t.amount; expense += t.amount; }
                             } else {
                                if (t.type == TransactionType.income) income += t.amount;
                                if (t.type == TransactionType.expense) expense += t.amount;
                             }
                          }
                       }
                       incomeSpots.add(FlSpot((4-i).toDouble(), income));
                       expenseSpots.add(FlSpot((4-i).toDouble(), expense));
                       
                       if(income > maxY) maxY = income;
                       if(expense > maxY) maxY = expense;
                    }
                    bottomLabel = (val) {
                       return (now.year - (4 - val)).toString();
                    };
                }

                if (maxY == 0) maxY = 100;

                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16, left: 16),
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
                               final txt = bottomLabel(value.toInt());
                               if (txt.isEmpty) return const SizedBox.shrink();
                               return Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(txt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                               );
                             },
                             reservedSize: 30,
                           )
                         ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Income
                        LineChartBarData(
                          spots: incomeSpots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: Colors.teal,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.1)),
                        ),
                        // Expense
                        LineChartBarData(
                          spots: expenseSpots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: Colors.red,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                        ),
                      ],
                       lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                            tooltipPadding: const EdgeInsets.all(8),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (touchedSpots) {
                               return touchedSpots.map((spot) {
                                  final isIncome = spot.barIndex == 0;
                                  return LineTooltipItem(
                                    '${isIncome ? "Income" : "Expense"}\n',
                                    TextStyle(color: isIncome ? Colors.teal : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                    children: [
                                      TextSpan(
                                        text: '${ref.watch(currencyProvider)}${spot.y.toStringAsFixed(0)}', 
                                        style: TextStyle(color: isIncome ? Colors.teal : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)
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
                    children: (txs..sort((a, b) {
                      final dateComp = b.date.compareTo(a.date);
                      if (dateComp != 0) return dateComp;
                      return b.id.compareTo(a.id);
                    })).map((t) {
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
      ),
    );
  }


  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
      return GestureDetector(
         onTap: onTap,
         child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
               color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
               borderRadius: BorderRadius.circular(8),
               border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)) : null,
            ),
            child: Text(
               text, 
               style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant
               )
            ),
         ),
      );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title, 
    required this.total, 
    required this.net, 
    required this.color, 
    required this.icon,
    this.max
  });
  
  final String title;
  final double total;
  final double net; // Real
  final Color color;
  final IconData icon;
  final double? max;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                 child: Icon(icon, size: 16, color: color),
               ),
               const Gap(8),
               Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
             ],
           ),
           const Gap(16),
           Text('Total', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
           Consumer(builder: (c, ref, _) =>
             Text(
               '${ref.watch(currencyProvider)}${total.toStringAsFixed(0)}',
               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.7)),
             )
           ),
           const Gap(4),
           Text('Net (Real)', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
            Consumer(builder: (c, ref, _) =>
             Text(
               '${ref.watch(currencyProvider)}${net.toStringAsFixed(0)}',
               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
             )
           ),
        ],
      ),
    );
  }
}
