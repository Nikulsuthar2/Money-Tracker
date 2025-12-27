import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

final allTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAllTransactions();
});

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _viewMode = 'Month'; // Month, Year
  DateTime _selectedDate = DateTime.now();
  int _chartIndex = 0; // 0 = Bar, 1 = Pie

  void _prevPeriod() {
    setState(() {
      if (_viewMode == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
     setState(() {
      if (_viewMode == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    return all.where((t) {
      if (t.skipFromStats) return false;
      if (_viewMode == 'Month') {
        return t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
      } else if (_viewMode == 'Year') {
        return t.date.year == _selectedDate.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final dateFormat = _viewMode == 'Month' ? DateFormat('MMMM yyyy') : DateFormat('yyyy');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            initialValue: _viewMode,
            onSelected: (v) => setState(() => _viewMode = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Month', child: Text('Monthly')),
              const PopupMenuItem(value: 'Year', child: Text('Yearly')),
              const PopupMenuItem(value: 'All', child: Text('All Time')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_viewMode, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final transactions = _filterTransactions(allTransactions ?? []);
          
          return Column(
            children: [
               // Fixed Header (Date Nav)
               if (_viewMode != 'All')
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 color: theme.colorScheme.surface,
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left)),
                      Text(dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton.filledTonal(onPressed: _nextPeriod, icon: const Icon(Icons.chevron_right)),
                    ],
                 ),
               ),
               const Divider(height: 1),

               Expanded(
                 child: transactions.isEmpty 
                   ? _buildEmptyState()
                   : _buildContent(transactions),
               ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey.withOpacity(0.3)),
          const Gap(16),
          const Text('No data for selected period', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    
    // Separate logic needed for charts (buckets)
    // Map<Comparable, double> incomeBuckets = {}; 
    // Map<Comparable, double> expenseBuckets = {};

    final categoryExpenseMap = <int, double>{};
    final categoryIncomeMap = <int, double>{};

    for (var t in transactions) {
      if (t.type == TransactionType.transfer) continue;

      if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
         for (var s in t.subTransactions!) {
            if (!s.isMine) continue;
            if (t.type == TransactionType.income) {
               totalIncome += s.amount;
               if (s.categoryId != null) categoryIncomeMap[s.categoryId!] = (categoryIncomeMap[s.categoryId!] ?? 0) + s.amount;
            } else if (t.type == TransactionType.expense) {
               totalExpense += s.amount;
               if (s.categoryId != null) categoryExpenseMap[s.categoryId!] = (categoryExpenseMap[s.categoryId!] ?? 0) + s.amount;
            }
         }
      } else {
         if (t.type == TransactionType.income) {
            totalIncome += t.amount;
            if (t.categoryId != null) categoryIncomeMap[t.categoryId!] = (categoryIncomeMap[t.categoryId!] ?? 0) + t.amount;
         } else if (t.type == TransactionType.expense) {
            totalExpense += t.amount;
            if (t.categoryId != null) categoryExpenseMap[t.categoryId!] = (categoryExpenseMap[t.categoryId!] ?? 0) + t.amount;
         }
      }
    }

    final netResult = totalIncome - totalExpense; // Net Income
    final ref = this.ref; // Capture ref for below
    final currency = ref.watch(currencyProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Net Result Card
        Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Net Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Gap(8),
                Text(
                  '${netResult >= 0 ? "+" : ""}$currency${netResult.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: netResult >= 0 ? Colors.teal : Colors.red,
                  ),
                ),
                const Gap(24),
                Row(
                  children: [
                    Expanded(child: _CompactStat(label: 'Income', amount: totalIncome, color: Colors.teal, currency: currency)),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                    Expanded(child: _CompactStat(label: 'Expense', amount: totalExpense, color: Colors.red, currency: currency)),
                  ],
                )
              ],
            ),
          ),
        ),
        const Gap(24),

        // Chart Selector
        SegmentedButton<int>(
           segments: const [
             ButtonSegment(value: 0, label: Text('Trends'), icon: Icon(Icons.bar_chart)),
             ButtonSegment(value: 1, label: Text('Categories'), icon: Icon(Icons.pie_chart)),
           ],
           selected: {_chartIndex},
           onSelectionChanged: (s) => setState(() => _chartIndex = s.first),
           showSelectedIcon: false,
        ),
        const Gap(24),

        if (_chartIndex == 0)
          SizedBox(
            height: 250,
            child: _TrendBarChart(transactions: transactions, viewMode: _viewMode, selectedDate: _selectedDate),
          )
        else
          Column(
            children: [
              _CategoryPieChart(dataMap: categoryExpenseMap, title: 'Expense Breakdown', currency: currency),
              const Gap(32),
              if (categoryIncomeMap.isNotEmpty)
               _CategoryPieChart(dataMap: categoryIncomeMap, title: 'Income Breakdown', currency: currency),
            ],
          ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  const _CompactStat({required this.label, required this.amount, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Text('$currency${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String viewMode;
  final DateTime selectedDate;

  const _TrendBarChart({required this.transactions, required this.viewMode, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    // Bucket logic
    final Map<int, double> incomeBuckets = {};
    final Map<int, double> expenseBuckets = {};
    int maxKey = 0;

    if (viewMode == 'Month') {
      final days = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      maxKey = days;
      for (int i=1; i<=days; i++) { incomeBuckets[i] = 0; expenseBuckets[i] = 0; }
      
      for (var t in transactions) {
         if (t.type == TransactionType.income) incomeBuckets[t.date.day] = (incomeBuckets[t.date.day] ?? 0) + t.amount;
         if (t.type == TransactionType.expense) expenseBuckets[t.date.day] = (expenseBuckets[t.date.day] ?? 0) + t.amount;
      }
    } else {
      // Year or All (buckets by month)
      maxKey = 12;
      for (int i=1; i<=12; i++) { incomeBuckets[i] = 0; expenseBuckets[i] = 0; }
      for (var t in transactions) {
         if (t.type == TransactionType.income) incomeBuckets[t.date.month] = (incomeBuckets[t.date.month] ?? 0) + t.amount;
         if (t.type == TransactionType.expense) expenseBuckets[t.date.month] = (expenseBuckets[t.date.month] ?? 0) + t.amount;
      }
    }

    final groups = <BarChartGroupData>[];
    for (int i=1; i<=maxKey; i++) {
        // Optimize: Only show Bars with data or simplify x-axis
        if (viewMode == 'Month' && i % 5 != 0 && i != 1 && i != maxKey) {
           // Skip creating group if 0? No, need spacing.
           // Actually FlChart handles spacing.
        }
        
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
               BarChartRodData(toY: incomeBuckets[i] ?? 0, color: Colors.teal, width: 4),
               BarChartRodData(toY: expenseBuckets[i] ?? 0, color: Colors.redAccent, width: 4),
            ],
          )
        );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
           touchTooltipData: BarTouchTooltipData(
             getTooltipColor: (_) => Colors.blueGrey,
           ) // Replaces tooltipBgColor
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                 final i = val.toInt();
                 if (viewMode == 'Month') {
                    if (i == 1 || i == 10 || i == 20 || i == maxKey) return Text('$i', style: const TextStyle(fontSize: 10));
                    return const SizedBox();
                 } else {
                    // Month initials
                    const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                    if (i-1 < months.length) return Text(months[i-1], style: const TextStyle(fontSize: 10));
                    return const SizedBox();
                 }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _CategoryPieChart extends ConsumerWidget {
  final Map<int, double> dataMap;
  final String title;
  final String currency;

  const _CategoryPieChart({required this.dataMap, required this.title, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dataMap.isEmpty) return const SizedBox();

    final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchAllCategories();
    
    return StreamBuilder<List<Category>>(
      stream: categoriesAsync,
      builder: (context, snapshot) {
         if (!snapshot.hasData) return const SizedBox();
         final categories = snapshot.data!;
         final catMap = {for (var c in categories) c.id: c};
         
         final total = dataMap.values.fold(0.0, (s, e) => s + e);
         final sortedEntries = dataMap.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

         return Column(
           children: [
             Text(title, style: Theme.of(context).textTheme.titleMedium),
             const Gap(16),
             SizedBox(
               height: 200,
               child: PieChart(
                 PieChartData(
                   sections: sortedEntries.map((e) {
                      final cat = catMap[e.key];
                      final color = cat != null ? Color(cat.color) : Colors.grey;
                      final pct = (e.value / total * 100);
                      return PieChartSectionData(
                        value: e.value,
                        title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                        color: color,
                        radius: 50,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                   }).toList(),
                   sectionsSpace: 2,
                   centerSpaceRadius: 40,
                 ),
               ),
             ),
             const Gap(16),
             // Legend List
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: sortedEntries.length > 5 ? 5 : sortedEntries.length, // Top 5
               itemBuilder: (context, index) {
                  final e = sortedEntries[index];
                  final cat = catMap[e.key];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: cat != null ? Color(cat.color) : Colors.grey, shape: BoxShape.circle)),
                        const Gap(8),
                        Expanded(child: Text(cat?.name ?? 'Unknown', style: const TextStyle(fontSize: 14))),
                        Text('$currency${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
               },
             ),
           ],
         );
      }
    );
  }
}
