import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:collection/collection.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_card.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _trendView = 'Daily';
  bool _isTotalView =
      true; // true = Total (Cash Flow), false = Net (Accounting)

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Total Balance
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider);
    // Recent Transactions
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    // For Chart: Watch based on view toggle
    final rawTransactionsAsync = ref.watch(transactionsStreamProvider);
    final netTransactionsAsync = ref.watch(analyticsTransactionsProvider);
    final allTransactionsAsync = _isTotalView ? rawTransactionsAsync : netTransactionsAsync;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.wallet,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const Gap(8),
                  Text(
                    'Money Tracker',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('All Transactions'),
              onTap: () {
                Navigator.pop(context);
                context.go('/transactions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: accountsWithBalance.when(
          data: (stats) {
            double totalBalance = 0;
            for (var s in stats) {
              totalBalance += s.totalContributionToNetWorth;
            }
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/accounts'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Consumer(
                        builder: (c, ref, _) => Text(
                          '${ref.watch(currencyProvider)}${totalBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsWithBalanceProvider);
          ref.invalidate(transactionsStreamProvider);
          ref.invalidate(recentTransactionsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 80,
          ),
          children: [
            // Stats Section
            accountsWithBalance.when(
              data: (stats) {
                double totalBalance = 0;
                for (var s in stats) {
                  totalBalance += s.totalContributionToNetWorth;
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
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wallet,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 52,
                        ),
                      ),
                      const Gap(16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const Gap(4),
                          Consumer(
                            builder: (c, ref, _) => Text(
                              '${ref.watch(currencyProvider)}${totalBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const Gap(24),

            // Accounts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Accounts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/add-account'),
                      icon: const Icon(Icons.add_card),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Add Account',
                    ),
                    IconButton(
                      onPressed: () => context.push('/accounts'),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'View All',
                    ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            accountsWithBalance.when(
              data: (accounts) {
                if (accounts.isEmpty) return const Text('No accounts yet.');
                final displayAccounts = accounts.take(3).toList();
                return Column(
                  children: displayAccounts
                      .map((item) => AccountCard(item: item))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading accounts: $e\n$s'),
            ),
            const Gap(24),

            // Chart Section
            // Header: Financial Trend | Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // Switch Total vs Net
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleOption(
                        'Total I&E',
                        _isTotalView,
                        () => setState(() => _isTotalView = true),
                      ),
                      _buildToggleOption(
                        'Net I&E',
                        !_isTotalView,
                        () => setState(() => _isTotalView = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            // Time Segments (Full Width)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Daily',
                    label: Text('Daily'),
                    icon: null,
                  ),
                  ButtonSegment(
                    value: 'Monthly',
                    label: Text('Monthly'),
                    icon: null,
                  ),
                  ButtonSegment(
                    value: 'Yearly',
                    label: Text('Yearly'),
                    icon: null,
                  ),
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
                  if (transactions.isEmpty)
                    return const Center(child: Text('Not enough data'));

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
                        if (t.date.year == date.year &&
                            t.date.month == date.month &&
                            t.date.day == date.day) {
                          if (_isTotalView) {
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                            if (t.type == TransactionType.transfer) {
                              if (t.fromAccountId == null || t.isSettlement) income += t.amount; // External or Settlement in
                              if (t.toAccountId == null || t.isSettlement) expense += t.amount; // External or Settlement out
                            }
                          } else {
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                          }
                        }
                      }
                      incomeSpots.add(FlSpot((29 - i).toDouble(), income));
                      expenseSpots.add(FlSpot((29 - i).toDouble(), expense));

                      if (income > maxY) maxY = income;
                      if (expense > maxY) maxY = expense;
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
                        if (t.date.year == date.year &&
                            t.date.month == date.month) {
                          if (_isTotalView) {
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                            if (t.type == TransactionType.transfer) {
                              if (t.fromAccountId == null || t.isSettlement) income += t.amount;
                              if (t.toAccountId == null || t.isSettlement) expense += t.amount;
                            }
                          } else {
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                          }
                        }
                      }
                      incomeSpots.add(FlSpot((11 - i).toDouble(), income));
                      expenseSpots.add(FlSpot((11 - i).toDouble(), expense));

                      if (income > maxY) maxY = income;
                      if (expense > maxY) maxY = expense;
                    }
                    bottomLabel = (val) {
                      final date = DateTime(
                        now.year,
                        now.month - (11 - val),
                        1,
                      );
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
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                            if (t.type == TransactionType.transfer) {
                              if (t.fromAccountId == null || t.isSettlement) income += t.amount;
                              if (t.toAccountId == null || t.isSettlement) expense += t.amount;
                            }
                          } else {
                            if (t.type == TransactionType.income)
                              income += t.amount;
                            if (t.type == TransactionType.expense)
                              expense += t.amount;
                          }
                        }
                      }
                      incomeSpots.add(FlSpot((4 - i).toDouble(), income));
                      expenseSpots.add(FlSpot((4 - i).toDouble(), expense));

                      if (income > maxY) maxY = income;
                      if (expense > maxY) maxY = expense;
                    }
                    bottomLabel = (val) {
                      return (now.year - (4 - val)).toString();
                    };
                  }

                  if (maxY == 0) maxY = 100;

                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 16,
                      left: 16,
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final txt = bottomLabel(value.toInt());
                                if (txt.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    txt,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
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
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.teal.withOpacity(0.1),
                            ),
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
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withOpacity(0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) =>
                                Theme.of(context).colorScheme.surface,
                            tooltipPadding: const EdgeInsets.all(8),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final isIncome = spot.barIndex == 0;
                                return LineTooltipItem(
                                  '${isIncome ? "Income" : "Expense"}\n',
                                  TextStyle(
                                    color: isIncome ? Colors.teal : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${ref.watch(currencyProvider)}${spot.y.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isIncome
                                            ? Colors.teal
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    const Center(child: Text('Error loading chart')),
              ),
            ),

            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const Gap(8),
            recentTransactionsAsync.when(
              data: (txs) {
                if (txs.isEmpty) return const Text('No recent transactions');

                return accountsWithBalance.when(
                  data: (accountsStats) {
                    final accountMap = {
                      for (var s in accountsStats) s.account.id: s.account.name,
                    };

                    return Column(
                      children:
                          (txs..sort((a, b) {
                                final dateComp = b.date.compareTo(a.date);
                                if (dateComp != 0) return dateComp;
                                return b.id.compareTo(a.id);
                              }))
                              .map((t) {
                                final accountId =
                                    t.type == TransactionType.income
                                    ? t.toAccountId
                                    : t.fromAccountId;
                                final accountName = accountId != null
                                    ? accountMap[accountId] ?? 'Unknown'
                                    : 'Unknown';
                                
                                final category = t.categoryId != null ? categoriesAsync.value?.firstWhereOrNull((c) => c.id == t.categoryId) : null;

                                return TransactionTile(
                                  transaction: t,
                                  accountName: accountName,
                                  category: category,
                                  onTap: () => context.push(
                                    '/transaction-details',
                                    extra: t,
                                  ),
                                );
                              })
                              .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
    this.max,
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            'Total',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Consumer(
            builder: (c, ref, _) => Text(
              '${ref.watch(currencyProvider)}${total.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
            ),
          ),
          const Gap(4),
          Text(
            'Net (Real)',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Consumer(
            builder: (c, ref, _) => Text(
              '${ref.watch(currencyProvider)}${net.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
