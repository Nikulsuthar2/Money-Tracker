import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final transactionsAsync = ref.watch(analyticsTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: accountsAsync.when(
        data: (accounts) {
          double netWorth = 0;
          for (var a in accounts) {
            netWorth += a.balance; // Using balance (which handles both cash and investments properly now)
          }

          return transactionsAsync.when(
            data: (allTransactions) {
              final transactions = allTransactions ?? [];
              
              // Calculate Average Monthly Spend & Savings Rate
              // We'll look at the last 3 months
              final now = DateTime.now();
              final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
              
              double totalIncomeLast3M = 0;
              double totalExpenseLast3M = 0;
              
              for (var t in transactions) {
                if (t.skipFromStats) continue;
                if (t.date.isAfter(threeMonthsAgo)) {
                   if (t.type == TransactionType.income) totalIncomeLast3M += t.amount;
                   if (t.type == TransactionType.expense) totalExpenseLast3M += t.amount;
                }
              }
              
              final avgMonthlySpend = totalExpenseLast3M / 3;
              final avgMonthlyIncome = totalIncomeLast3M / 3;
              
              final runwayMonths = avgMonthlySpend > 0 ? (netWorth / avgMonthlySpend) : 0.0;
              final savingsRate = avgMonthlyIncome > 0 ? ((avgMonthlyIncome - avgMonthlySpend) / avgMonthlyIncome) * 100 : 0.0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  const Gap(24),
                  
                  // Key Metrics Grid
                  const Text('Key Metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  GridView.count(
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
                  const Gap(24),

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
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
