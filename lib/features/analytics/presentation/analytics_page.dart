import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _period = 'Monthly'; // Monthly, Yearly, All Time
  String _viewType = 'Trends'; // Trends, Categories, Calendar
  DateTime _selectedDate = DateTime.now();

  void _prevPeriod() {
    setState(() {
      if (_period == 'Monthly') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else if (_period == 'Yearly') {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
     setState(() {
      if (_period == 'Monthly') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else if (_period == 'Yearly') {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    if (_period == 'All Time') return all.where((t) => !t.skipFromStats).toList();
    
    return all.where((t) {
      if (t.skipFromStats) return false;
      if (_period == 'Monthly') {
         return t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
      } else if (_period == 'Yearly') {
         return t.date.year == _selectedDate.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(analyticsTransactionsProvider);
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    String dateLabel = '';
    if (_period == 'Monthly') dateLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_period == 'Yearly') dateLabel = DateFormat('yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'), // Default left aligned on Material 3 if centerTitle not true
        centerTitle: false,
        actions: [
        ],
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final transactions = _filterTransactions(allTransactions ?? []);
          
          return Column(
            children: [
               // Period Switch
               Padding(
                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                 child: SizedBox(
                   width: double.infinity,
                   child: SegmentedButton<String>(
                      segments: const [
                         ButtonSegment(value: 'Monthly', label: Text('Monthly')),
                         ButtonSegment(value: 'Yearly', label: Text('Yearly')),
                         ButtonSegment(value: 'All Time', label: Text('All Time')),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) => setState(() => _period = s.first),
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                   ),
                 ),
               ),
              // 1. Date Navigation (Hidden for All Time)
              // 1. Date Navigation (Hidden for All Time)
              if (_period != 'All Time')
                Center(
                  child: Container(
                     margin: const EdgeInsets.symmetric(vertical: 8),
                     constraints: const BoxConstraints(maxWidth: 300),
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(50),
                     ),
                     child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.filledTonal(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero, iconSize: 18),
                          Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton.filledTonal(onPressed: _nextPeriod, icon: const Icon(Icons.chevron_right), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero, iconSize: 18),
                        ],
                     ),
                  ),
                ),
               
               if (_period != 'All Time') const Divider(height: 1),

               // 2. Scrollable Content
               Expanded(
                 child: ListView(
                   padding: const EdgeInsets.all(16),
                   children: [
                     // Net Result Card
                     _NetResultCard(transactions: transactions, currency: currency),
                     const Gap(24),
// ... (Skipping to NetResultCard modification) ...


                     // View Switcher
                     SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Trends', label: Text('Trends'), icon: Icon(Icons.bar_chart)),
                          ButtonSegment(value: 'Categories', label: Text('Categories'), icon: Icon(Icons.pie_chart)),
                          ButtonSegment(value: 'Calendar', label: Text('Calendar'), icon: Icon(Icons.calendar_month)),
                        ],
                        selected: {_viewType},
                        onSelectionChanged: (s) => setState(() => _viewType = s.first),
                        showSelectedIcon: false,
                     ),
                     const Gap(24),

                     // Content Views
                     if (transactions.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data for this period')))
                     else if (_viewType == 'Trends')
                        _TrendsView(transactions: transactions, period: _period, selectedDate: _selectedDate, currency: currency)
                     else if (_viewType == 'Categories')
                        _CategoriesView(transactions: transactions, currency: currency)
                     else if (_viewType == 'Calendar')
                        _CalendarView(transactions: transactions, period: _period, selectedDate: _selectedDate, currency: currency),
                   ],
                 ),
               ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NetResultCard extends StatelessWidget {
  final List<Transaction> transactions;
  final String currency;

  const _NetResultCard({required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Accounting
    double accIncome = 0;
    double accExpense = 0;
    // Cash Flow
    double cashIn = 0;
    double cashOut = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
         accIncome += t.amount;
         cashIn += t.amount;
      } else if (t.type == TransactionType.expense) {
         accExpense += t.amount;
         cashOut += t.amount;
      } else if (t.type == TransactionType.transfer) {
         // Transfer is In AND Out conceptually for "Total Flow"
         cashIn += t.amount;
         cashOut += t.amount;
      }
    }

    final accNet = accIncome - accExpense;
    // final cashNet = cashIn - cashOut; // Redundant if same as accNet? Yes, but CashIn/Out diff

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? Colors.tealAccent : Colors.teal;
    final redColor = isDark ? Colors.redAccent.shade100 : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             const Text('Net Result', style: TextStyle(fontSize: 14, color: Colors.grey)),
             const Gap(8),
             Text('${accNet >= 0 ? "+" : ""}$currency${accNet.abs().toStringAsFixed(2)}', 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accNet >= 0 ? tealColor : redColor)),
             
             const Gap(24),
             const Divider(),
             const Gap(16),
             
             // Restore 4 Stats
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatCell(label: 'Actual Income', amount: accIncome, color: tealColor, currency: currency),
                     const Gap(12),
                    _StatCell(label: 'Total In', amount: cashIn, color: tealColor.withOpacity(0.7), currency: currency, isSmall: true),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatCell(label: 'Actual Expense', amount: accExpense, color: redColor, currency: currency),
                    const Gap(12),
                    _StatCell(label: 'Total Out', amount: cashOut, color: redColor.withOpacity(0.7), currency: currency, isSmall: true),
                  ],
                ),
                
                ],
             ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
   final String label;
   final double amount;
   final Color color;
   final String currency;
   final bool isSmall;

   const _StatCell({required this.label, required this.amount, required this.color, required this.currency, this.isSmall = false});

   @override
  Widget build(BuildContext context) {
    return Row(
      children: [
         Container(width: 4, height: isSmall ? 12 : 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
         const Gap(8),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(label, style: TextStyle(fontSize: isSmall ? 10 : 12, color: Colors.grey)),
             Text('$currency${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 12 : 16, color: color)),
           ],
         )
      ],
    );
  }
}

class _TrendsView extends StatelessWidget {
  final List<Transaction> transactions;
  final String period;
  final DateTime selectedDate;
  final String currency;

  const _TrendsView({required this.transactions, required this.period, required this.selectedDate, required this.currency});

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Bar Chart Data
    // Group by Day (Month view) or Month (Year view)
    final Map<int, double> incomeMap = {};
    final Map<int, double> expenseMap = {};
    int maxKey = 0;

    if (period == 'Monthly') {
       maxKey = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
       for(var t in transactions) {
         if (t.type == TransactionType.income) incomeMap[t.date.day] = (incomeMap[t.date.day] ?? 0) + t.amount;
         if (t.type == TransactionType.expense) expenseMap[t.date.day] = (expenseMap[t.date.day] ?? 0) + t.amount;
       }
    } else {
       maxKey = 12; // 12 Months
       for(var t in transactions) {
         if (t.type == TransactionType.income) incomeMap[t.date.month] = (incomeMap[t.date.month] ?? 0) + t.amount;
         if (t.type == TransactionType.expense) expenseMap[t.date.month] = (expenseMap[t.date.month] ?? 0) + t.amount;
       }
    }

    final groups = <BarChartGroupData>[];
    for(int i=1; i<=maxKey; i++) {
        // Optimization: Skip empty days except start/end/intervals
        groups.add(BarChartGroupData(x: i, barRods: [
           BarChartRodData(toY: incomeMap[i] ?? 0, color: Colors.teal, width: 4),
           BarChartRodData(toY: expenseMap[i] ?? 0, color: Colors.redAccent, width: 4),
        ]));
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
             BarChartData(
               alignment: BarChartAlignment.spaceAround,
               barTouchData: BarTouchData(
                 touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.blueGrey),
               ),
               titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text(val >= 1000 ? '${(val/1000).toStringAsFixed(1)}k' : val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (val, meta) {
                         final i = val.toInt();
                         if (period == 'Monthly') {
                            if (i == 1 || i == maxKey || i % 5 == 0) return Text('$i', style: const TextStyle(fontSize: 10));
                         } else {
                            const m = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                            if (i >= 1 && i <= 12) return Text(m[i-1], style: const TextStyle(fontSize: 10));
                         }
                         return const SizedBox();
                      }
                    )
                  )
               ),
               borderData: FlBorderData(show: false),
               gridData: const FlGridData(show: false),
               barGroups: groups,
             )
          ),
        ),
        const Gap(24),
        // Breakdown List (Top 5 Categories by Expense)
        const Text('Top Spending Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        const Gap(16),
        Consumer(builder: (context, ref, _) {
           final categoriesAsync = ref.watch(categoriesStreamProvider);
           return categoriesAsync.when(
             data: (categories) {
                final catMap = {for (var c in categories) c.id: c};
                // Calculate Category Totals
                final catTotal = <int, double>{};
                for(var t in transactions) {
                   if (t.type == TransactionType.expense && t.categoryId != null) {
                      catTotal[t.categoryId!] = (catTotal[t.categoryId!] ?? 0) + t.amount;
                   }
                }
                final sorted = catTotal.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
                final top = sorted.take(5).toList();
                
                if (top.isEmpty) return const Text('No expense data');

                return Column(
                  children: top.map((e) {
                     final cat = catMap[e.key];
                     return ListTile(
                       leading: CircleAvatar(
                          backgroundColor: cat != null ? Color(cat.color).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          child: Icon(cat?.icon != null ? IconData(cat!.icon, fontFamily: 'MaterialIcons') : Icons.category, color: cat != null ? Color(cat.color) : Colors.grey, size: 16),
                       ),
                       title: Text(cat?.name ?? 'Unknown'),
                       trailing: Text('$currency${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       dense: true,
                     );
                  }).toList(),
                );
             },
             loading: () => const CircularProgressIndicator(),
             error: (_,__) => const SizedBox(),
           );
        }),
      ],
    );
  }
}

class _CategoriesView extends ConsumerWidget {
  final List<Transaction> transactions;
  final String currency;

  const _CategoriesView({required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeMap = <int, double>{};
    final expenseMap = <int, double>{};

    for(var t in transactions) {
       // if (t.categoryId == null) continue; // Don't skip uncategorized
       final catId = t.categoryId ?? -1; // Use -1 for Uncategorized
       
       if (t.type == TransactionType.income) incomeMap[catId] = (incomeMap[catId] ?? 0) + t.amount;
       if (t.type == TransactionType.expense) expenseMap[catId] = (expenseMap[catId] ?? 0) + t.amount;
    }

    return Column(
      children: [
        if (expenseMap.isNotEmpty) _PieChartSection(dataMap: expenseMap, title: 'Expense Breakdown', currency: currency),
        if (expenseMap.isNotEmpty && incomeMap.isNotEmpty) const Gap(32),
        if (incomeMap.isNotEmpty) _PieChartSection(dataMap: incomeMap, title: 'Income Breakdown', currency: currency),
      ],
    );
  }
}

class _PieChartSection extends ConsumerWidget {
  final Map<int, double> dataMap;
  final String title;
  final String currency;

  const _PieChartSection({required this.dataMap, required this.title, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchAllCategories();
      
      return StreamBuilder<List<Category>>(
        stream: categoriesAsync,
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const SizedBox();
           final categories = snapshot.data!;
           final catMap = {for (var c in categories) c.id: c};
           
           final total = dataMap.values.fold(0.0, (s, e) => s + e);
           final sortedEntries = dataMap.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

           return Card(
             child: Padding(
               padding: const EdgeInsets.all(16),
               child: Column(
                 children: [
                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                   const Gap(16),
                   SizedBox(
                     height: 200,
                     child: PieChart(
                       PieChartData(
                         sections: sortedEntries.map((e) {
                            final isUncategorized = e.key == -1;
                            final cat = isUncategorized ? null : catMap[e.key];
                            
                            final color = isUncategorized ? Colors.grey.shade400 : (cat != null ? Color(cat.color) : Colors.grey);
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
                   // Legend
                   ...sortedEntries.take(5).map((e) {
                       final isUncategorized = e.key == -1;
                       final cat = isUncategorized ? null : catMap[e.key];
                       final color = isUncategorized ? Colors.grey.shade400 : (cat != null ? Color(cat.color) : Colors.grey);
                       final name = isUncategorized ? 'Uncategorized' : (cat?.name ?? 'Unknown');

                       return Padding(
                         padding: const EdgeInsets.symmetric(vertical: 4),
                         child: Row(
                           children: [
                             Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                             const Gap(8),
                             Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
                             Text('$currency${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                           ],
                         ),
                       );
                   }),
                 ],
               ),
             ),
           );
        }
      );
  }
}

class _CalendarView extends StatelessWidget {
  final List<Transaction> transactions;
  final String period;
  final DateTime selectedDate;
  final String currency;

  const _CalendarView({required this.transactions, required this.period, required this.selectedDate, required this.currency});

  @override
  Widget build(BuildContext context) {
    // If Monthly -> Day Grid
    // If Yearly -> Month Grid
    // If All Time -> Year Grid (maybe?)

    if (period == 'Monthly') {
       final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
       final firstDayWeekday = DateTime(selectedDate.year, selectedDate.month, 1).weekday; // 1=Mon, 7=Sun
       // Let's assume Mon-Sun week
       final offset = firstDayWeekday - 1;
       final totalCells = offset + daysInMonth;
       
       final dayMap = <int, double>{}; // Net for the day
       
       for(var t in transactions) {
         double val = 0;
         if (t.type == TransactionType.income) val = t.amount;
         if (t.type == TransactionType.expense) val = -t.amount;
         
         dayMap[t.date.day] = (dayMap[t.date.day] ?? 0) + val;
       }

       const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

       return Column(
         children: [
            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((d) => SizedBox(width: 30, child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))).toList(),
            ),
            const Gap(8),
            GridView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.8),
             itemCount: totalCells,
             itemBuilder: (context, index) {
                if (index < offset) return const SizedBox();
                
                final day = index - offset + 1;
                final net = dayMap[day] ?? 0;
                return Card(
                   elevation: 0,
                   color: net > 0 ? Colors.teal.withOpacity(0.1) : (net < 0 ? Colors.red.withOpacity(0.1) : Colors.transparent),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text('$day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                         if (net != 0)
                           Text('${net > 0 ? "+" : ""}${net.abs().toStringAsFixed(0)}', 
                              style: TextStyle(fontSize: 9, color: net > 0 ? Colors.teal : Colors.red, fontWeight: FontWeight.bold))
                      ],
                   ),
                );
             },
           ),
         ],
       );
    } else {
       // Yearly -> 12 Months
       final monthMap = <int, double>{};
       for(var t in transactions) {
         double val = 0;
         if (t.type == TransactionType.income) val = t.amount;
         if (t.type == TransactionType.expense) val = -t.amount;
         monthMap[t.date.month] = (monthMap[t.date.month] ?? 0) + val;
       }
       
       return GridView.builder(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.5),
         itemCount: 12,
         itemBuilder: (context, index) {
            final month = index + 1;
            final net = monthMap[month] ?? 0;
            final mName = DateFormat('MMM').format(DateTime(2024, month));
            
            return Card(
               elevation: 0,
               color: net > 0 ? Colors.teal.withOpacity(0.1) : (net < 0 ? Colors.red.withOpacity(0.1) : Colors.transparent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(mName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                     if (net != 0)
                       Text('${net > 0 ? "+" : ""}${net.abs().toStringAsFixed(0)}', 
                          style: TextStyle(fontSize: 11, color: net > 0 ? Colors.teal : Colors.red, fontWeight: FontWeight.bold))
                  ],
               ),
            );
         },
       );
    }
  }
}


