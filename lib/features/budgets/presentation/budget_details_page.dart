import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/budgets/providers/budget_providers.dart';
import 'package:money_manager/features/categories/presentation/category_icon_widget.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/budgets/data/budget_repository.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetDetailsPage extends ConsumerWidget {
  final int budgetId;

  const BudgetDetailsPage({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithConsumptionProvider);
    final transactionsAsync = ref.watch(budgetTransactionsProvider(budgetId));
    
    // Find our budget from the list
    final budgetWithCons = budgetsAsync.value?.where((b) => b.budget.id == budgetId).firstOrNull;
    
    if (budgetWithCons == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget Details')),
        body: const Center(child: Text('Budget not found')),
      );
    }

    final budget = budgetWithCons.budget;
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isExceeded = budgetWithCons.isExceeded;
    final progressColor = isExceeded ? Colors.redAccent : Colors.green;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${budget.categoryName} Budget'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/budgets/add', extra: budget);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Budget'),
                    content: const Text('Are you sure you want to delete this budget?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          ref.read(budgetRepositoryProvider).deleteBudget(budget.id);
                          Navigator.pop(ctx);
                          context.pop(); // go back
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Analysis'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ANALYSIS TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Summary
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(budget.categoryColor).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(budget.categoryColor).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Color(budget.categoryColor).withOpacity(0.2),
                          child: CategoryIconWidget(
                            iconData: budget.categoryIconData,
                            color: budget.categoryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          budget.categoryName,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${budget.period.displayName} Limit: ${currencyFormatter.format(budget.amount)}',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Spent', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                Text(
                                  currencyFormatter.format(budgetWithCons.spent),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: isExceeded ? Colors.redAccent : theme.textTheme.titleLarge?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Left', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                Text(
                                  currencyFormatter.format(budget.amount - budgetWithCons.spent >= 0 ? budget.amount - budgetWithCons.spent : 0),
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: budgetWithCons.progress > 1 ? 1.0 : budgetWithCons.progress,
                            minHeight: 16,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                        if (isExceeded) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Exceeded limit by ${currencyFormatter.format(budgetWithCons.spent - budget.amount)}',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Graph
                  transactionsAsync.when(
                    data: (txns) {
                      if (txns.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data for graph')));
                      }

                      // Group by day for the chart
                      final Map<int, double> dailySpending = {};
                      for (var t in txns) {
                        dailySpending[t.date.day] = (dailySpending[t.date.day] ?? 0) + t.amount;
                      }

                      final spots = dailySpending.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
                        ..sort((a, b) => a.x.compareTo(b.x));

                      return Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) => Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Color(budget.categoryColor),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Color(budget.categoryColor).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                ],
              ),
            ),

            // TRANSACTIONS TAB
            transactionsAsync.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(child: Text('No transactions in this period', style: TextStyle(color: Colors.grey)));
                }
                
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final transaction = rows[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(budget.categoryColor).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CategoryIconWidget(iconData: budget.categoryIconData, color: budget.categoryColor, size: 20),
                      ),
                      title: Text((transaction.note?.isNotEmpty == true) ? transaction.note! : budget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('MMM d, yyyy').format(transaction.date)),
                      trailing: Text(
                        '-${currencyFormatter.format(transaction.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () {
                        context.push('/transaction-details', extra: transaction);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
