import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/features/assets/application/assets_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  String _trendView = 'Monthly';
  bool _isTotalView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final assetsAsync = ref.watch(assetsStreamProvider);
    final transactionsAsync = ref.watch(analyticsTransactionsProvider);

    return accountsAsync.when(
        data: (accounts) {
          double netWorth = 0;
          for (var a in accounts) {
            netWorth += a.totalContributionToNetWorth; // Include both cash balance and invested amounts
          }

          return assetsAsync.when(
            data: (assets) {
              for (var a in assets) {
                netWorth += a.value;
              }

              return transactionsAsync.when(
            data: (allTransactions) {
              final transactions = allTransactions ?? [];
              
              // Calculate Average Monthly Spend & Savings Rate
              // We'll look at the last 90 days
              final now = DateTime.now();
              final ninetyDaysAgo = now.subtract(const Duration(days: 90));
              
              double totalIncomeLast90D = 0;
              double totalExpenseLast90D = 0;
              DateTime? earliestActiveDate;
              
              for (var t in transactions) {
                if (t.skipFromStats) continue;
                if (t.isSettlement || t.mode == TransactionMode.settlement) continue;
                
                if (t.date.isAfter(ninetyDaysAgo)) {
                   final effectiveAmt = t.effectiveAmount;
                   if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) totalIncomeLast90D += effectiveAmt;
                   if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) totalExpenseLast90D += effectiveAmt;
                   
                   if (earliestActiveDate == null || t.date.isBefore(earliestActiveDate)) {
                     earliestActiveDate = t.date;
                   }
                }
              }
              
              double activeMonths = 3.0; // Default to 3
              if (earliestActiveDate != null) {
                final activeDays = now.difference(earliestActiveDate).inDays;
                activeMonths = (activeDays / 30.0).clamp(1.0, 3.0); // Between 1 and 3 months
              } else {
                activeMonths = 1.0;
              }
              
              final avgMonthlySpend = totalExpenseLast90D / activeMonths;
              final avgMonthlyIncome = totalIncomeLast90D / activeMonths;
              
              final runwayMonths = avgMonthlySpend > 0 ? (netWorth / avgMonthlySpend) : 0.0;
              final savingsRate = avgMonthlyIncome > 0 ? ((avgMonthlyIncome - avgMonthlySpend) / avgMonthlyIncome) * 100 : 0.0;

              return ListView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80,
                ),
                children: [
                  const Text('Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  // Net Worth Card
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Net Worth', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
                              Icon(Icons.account_balance_wallet, color: theme.colorScheme.onPrimaryContainer),
                            ],
                          ),
                          const Gap(12),
                          Text('$currency${netWorth.toStringAsFixed(2)}', 
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w900
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(16),
                  
                  // Key Metrics Grid
                  const Text('Key Metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  GridView.count(
                    padding: const EdgeInsets.only(top: 16, bottom: 0),
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _MetricCard(
                        title: 'Runway',
                        value: runwayMonths > 99 ? '99+ mo' : '${runwayMonths.toStringAsFixed(1)} mo',
                        subtitle: 'Based on avg spend',
                        icon: Icons.flight_takeoff,
                        color: Colors.blue,
                      ),
                      _MetricCard(
                        title: 'Savings Rate',
                        value: '${savingsRate.toStringAsFixed(1)}%',
                        subtitle: 'Last 3 months',
                        icon: Icons.savings,
                        color: savingsRate > 0 ? Colors.green : Colors.red,
                      ),
                      _MetricCard(
                        title: 'Avg. Spend',
                        value: '$currency${avgMonthlySpend.toStringAsFixed(0)}',
                        subtitle: 'Per month',
                        icon: Icons.trending_down,
                        color: Colors.orange,
                      ),
                      _MetricCard(
                        title: 'Avg. Income',
                        value: '$currency${avgMonthlyIncome.toStringAsFixed(0)}',
                        subtitle: 'Per month',
                        icon: Icons.trending_up,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  // Spend Analysis Link
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/spend-analysis'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.pie_chart, color: theme.colorScheme.onSecondaryContainer),
                            ),
                            const Gap(16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Spend Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Gap(4),
                                  Text('View detailed category breakdown', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildChart(transactions, currency, theme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      );
  }

  Widget _buildChart(List<Transaction> transactions, String currency, ThemeData theme) {
    if (transactions.isEmpty) return const Center(child: Text('Not enough data'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Financial Trend',
              style: theme.textTheme.titleLarge,
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Total I&E')),
                ButtonSegment(value: false, label: Text('Net I&E')),
              ],
              selected: {_isTotalView},
              onSelectionChanged: (s) => setState(() => _isTotalView = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Daily', label: Text('Daily')),
              ButtonSegment(value: 'Monthly', label: Text('Monthly')),
              ButtonSegment(value: 'Yearly', label: Text('Yearly')),
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
          child: _renderChartData(transactions, currency, theme),
        ),
        const Gap(16),
      ],
    );
  }

  Widget _renderChartData(List<Transaction> transactions, String currency, ThemeData theme) {
    final now = DateTime.now();
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    double maxY = 0;
    String Function(int) bottomLabel = (i) => '';

    if (_trendView == 'Daily') {
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.skipFromStats) continue;
          if (t.date.year == date.year && t.date.month == date.month && t.date.day == date.day) {
            if (_isTotalView) {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
              if (t.type == TransactionType.transfer) {
                if (t.fromAccountId == null || t.isSettlement) income += t.amount;
                if (t.toAccountId == null || t.isSettlement) expense += t.amount;
              }
            } else {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
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
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.skipFromStats) continue;
          if (t.date.year == date.year && t.date.month == date.month) {
            if (_isTotalView) {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
              if (t.type == TransactionType.transfer) {
                if (t.fromAccountId == null || t.isSettlement) income += t.amount;
                if (t.toAccountId == null || t.isSettlement) expense += t.amount;
              }
            } else {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
            }
          }
        }
        incomeSpots.add(FlSpot((11 - i).toDouble(), income));
        expenseSpots.add(FlSpot((11 - i).toDouble(), expense));
        if (income > maxY) maxY = income;
        if (expense > maxY) maxY = expense;
      }
      bottomLabel = (val) {
        final date = DateTime(now.year, now.month - (11 - val), 1);
        return DateFormat('MMM').format(date);
      };
    } else if (_trendView == 'Yearly') {
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.skipFromStats) continue;
          if (t.date.year == year) {
            if (_isTotalView) {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
              if (t.type == TransactionType.transfer) {
                if (t.fromAccountId == null || t.isSettlement) income += t.amount;
                if (t.toAccountId == null || t.isSettlement) expense += t.amount;
              }
            } else {
              if (t.type == TransactionType.income || t.type == TransactionType.sellInvestment) income += t.amount;
              if (t.type == TransactionType.expense || t.type == TransactionType.buyInvestment) expense += t.amount;
            }
          }
        }
        incomeSpots.add(FlSpot((4 - i).toDouble(), income));
        expenseSpots.add(FlSpot((4 - i).toDouble(), expense));
        if (income > maxY) maxY = income;
        if (expense > maxY) maxY = expense;
      }
      bottomLabel = (val) => (now.year - (4 - val)).toString();
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
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
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
              getTooltipColor: (_) => theme.colorScheme.surface,
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
                        text: '$currency${spot.y.toStringAsFixed(0)}',
                        style: TextStyle(color: isIncome ? Colors.teal : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
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
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                const Gap(4),
                Text(subtitle, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
