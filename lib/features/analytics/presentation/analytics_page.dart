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
// Simple provider to get transactions
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
  int _monthViewType = 0; // 0 = Chart, 1 = Calendar

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
      return true; // All Time
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchAllCategories();

    final dateFormat = _viewMode == 'Month' ? DateFormat('MMMM yyyy') : (_viewMode == 'Year' ? DateFormat('yyyy') : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final transactions = _filterTransactions(allTransactions ?? []);
          
          return Column(
            children: [
               // Period Selector & Navigation
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.surface,
                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                   boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                   ]
                 ),
                 child: Column(
                   children: [
                     SegmentedButton<String>(
                       segments: const [
                         ButtonSegment(value: 'Month', label: Text('Monthly')),
                         ButtonSegment(value: 'Year', label: Text('Yearly')),
                         ButtonSegment(value: 'All', label: Text('All')),
                       ],
                       selected: {_viewMode},
                       onSelectionChanged: (v) => setState(() => _viewMode = v.first),
                       showSelectedIcon: false,
                     ),
                     const Gap(16),
                     if (_viewMode != 'All')
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left)),
                          Text(dateFormat!.format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: _nextPeriod, icon: const Icon(Icons.chevron_right)),
                        ],
                     ),
                   ],
                 ),
               ),

               Expanded(
                 child: transactions.isEmpty 
                   ? const Center(child: Text('No data for selected period'))
                   : Builder(builder: (context) {
                       // Logic to calculate totals...
                       // I need to copy the calculation logic here or extract it
                       return _buildContent(transactions);
                   })
               ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(List<Transaction> transactions) {
          double totalIncome = 0;
          double totalExpense = 0;
          double totalTransfer = 0; 
          final categoryNetMap = <int, double>{};
          final incomeMap = <int, double>{}; 

           for (var t in transactions) {
             List<SubTransaction> relevantSplits = [];
             if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                relevantSplits = t.subTransactions!;
                for (var s in relevantSplits) {
                  if (!s.isMine) continue;
                  if (t.type == TransactionType.income) {
                     totalIncome += s.amount;
                     if (s.categoryId != null) incomeMap[s.categoryId!] = (incomeMap[s.categoryId!] ?? 0) + s.amount;
                  } else if (t.type == TransactionType.expense) {
                     totalExpense += s.amount;
                     if (s.categoryId != null) categoryNetMap[s.categoryId!] = (categoryNetMap[s.categoryId!] ?? 0) + s.amount;
                  }
                }
             } else {
               if (t.type == TransactionType.income) {
                  totalIncome += t.amount;
                  if (t.categoryId != null) incomeMap[t.categoryId!] = (incomeMap[t.categoryId!] ?? 0) + t.amount;
               } else if (t.type == TransactionType.expense) {
                  totalExpense += t.amount;
                  if (t.categoryId != null) categoryNetMap[t.categoryId!] = (categoryNetMap[t.categoryId!] ?? 0) + t.amount;
               } else {
                  totalTransfer += t.amount;
               }
             }
           }
           
           final positiveExpenses = categoryNetMap.entries.where((e) => e.value > 0).toList();
           final positiveIncome = incomeMap.entries.where((e) => e.value > 0).toList();
           
           final netExpenseTotal = totalExpense - totalIncome;

           // Use ref to get categories since we are in state
           final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchAllCategories();

           return StreamBuilder<List<Category>>(
              stream: categoriesAsync,
              builder: (context, catSnapshot) {
                final categories = catSnapshot.data ?? [];
                final categoryMap = {for (var c in categories) c.id: c};
                
                final currency = ref.watch(currencyProvider);

                Widget content = _AnalyticsContent(
                   totalIncome: totalIncome,
                   totalExpense: totalExpense,
                   netResult: netExpenseTotal,
                   expenseList: positiveExpenses,
                   incomeList: positiveIncome,
                   categoryMap: categoryMap,
                   totalTransfer: totalTransfer,
                   currency: currency,
                );
                
                if (_viewMode == 'Month') {
                   return Column(
                     children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, icon: Icon(Icons.pie_chart), label: Text('Chart')),
                              ButtonSegment(value: 1, icon: Icon(Icons.calendar_month), label: Text('Calendar')),
                            ],
                            selected: {_monthViewType},
                            onSelectionChanged: (s) => setState(() => _monthViewType = s.first),
                            showSelectedIcon: false,
                          ),
                        ),
                        const Gap(16),
                        Expanded(child: _monthViewType == 0 ? content : _CalendarView(
                          currentMonth: _selectedDate, 
                          transactions: transactions,
                          currency: currency,
                        )),
                     ],
                   );
                }

                return content; 
              }
           );
  }
}

class _CalendarView extends StatelessWidget {
  final DateTime currentMonth;
  final List<Transaction> transactions;
  final String currency;

  const _CalendarView({required this.currentMonth, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Grid
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday; // 1=Mon, 7=Sun
    
    // We want Mon as first column? Or Sun?
    // Let's assume Mon start for now as standard in many regions, or check locale?
    // Material uses Localizations. 
    // Let's stick to Mon-Sun (ISO 8601) for consistency with common repetitive logic or just generic.
    // Sunday start is common in US. Monday in EU.
    // Let's use Mon start day adjustment.
    
    // Grid Logic:
    // Offset blank cells = firstDayWeekday - 1 (if Mon=1, Mon is index 0. So offset 0).
    final offset = firstDayWeekday - 1; 

    // Process Transactions per day
    final Map<int, _DailyStats> dailyStats = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dailyStats[i] = _DailyStats();
    }
    
    for (var t in transactions) {
       // Filter matches month? Already filtered by parent.
       final day = t.date.day;
       if (t.type == TransactionType.income) {
          dailyStats[day]!.income += t.amount;
       } else if (t.type == TransactionType.expense) {
          dailyStats[day]!.expense += t.amount;
       }
       // Subtransactions need handling if we want precise accuracy, assuming parent logic didn't flatten them.
       // Current _filterTransactions in parent returns Transaction objects.
       // If flattened stats are needed, we duplicate logic?
       // For simplicity, using main amount if not split, or splits if split.
       if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
           // Re-calculate based on splits
           // Reset first? No, we added main amount erroneously if we didn't check.
           // Actually, earlier logic separated them.
           // Let's refine:
           if (t.type == TransactionType.income) dailyStats[day]!.income -= t.amount; // undo
           if (t.type == TransactionType.expense) dailyStats[day]!.expense -= t.amount; // undo

           for (var s in t.subTransactions!) {
               if(!s.isMine) continue;
               // Category type determines inc/exp?
               // The parent logic relies on Category type. 
               // Here we need to know the type of subtransaction. 
               // Assuming subtransaction follows main transaction type for now or we look up category.
               // Limitation: We don't have category map easily here without passing it.
               // Simplification: Assume split type matches transaction Type (usually true except transfer).
               if (t.type == TransactionType.income) dailyStats[day]!.income += s.amount;
               if (t.type == TransactionType.expense) dailyStats[day]!.expense += s.amount;
           }
       }
    }

    return Column(
      children: [
        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M','T','W','T','F','S','S'].map((e) => SizedBox(width: 40, child: Center(child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold))))).toList(),
          ),
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.7),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
               if (index < offset) return const SizedBox();
               final day = index - offset + 1;
               final stats = dailyStats[day]!;
               final isToday = day == DateTime.now().day && currentMonth.month == DateTime.now().month && currentMonth.year == DateTime.now().year;
               
               return Container(
                 margin: const EdgeInsets.all(2),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey.withOpacity(0.2)),
                   borderRadius: BorderRadius.circular(8),
                   color: isToday ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Text('$day', style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                      ),
                      const Spacer(),
                      if (stats.income > 0)
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text('+$currency${stats.income.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: Colors.teal))),
                      if (stats.expense > 0)
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text('-$currency${stats.expense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: Colors.red))),
                      const Gap(2),
                   ],
                 ),
               );
            },
          ),
        ),
      ],
    );
  }
}

class _DailyStats {
  double income = 0;
  double expense = 0;
}

class _AnalyticsContent extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final double netResult;
  final double totalTransfer;
  final List<MapEntry<int, double>> expenseList;
  final List<MapEntry<int, double>> incomeList;
  final Map<int, Category> categoryMap;
  final String currency;

  const _AnalyticsContent({
    required this.totalIncome,
    required this.totalExpense,
    required this.netResult,
    required this.expenseList,
    required this.incomeList,
    required this.categoryMap,
    required this.totalTransfer,
    required this.currency,
  });

  @override
  State<_AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<_AnalyticsContent> {
  int _tabIndex = 0; // 0 = Expense, 1 = Income

  @override
  Widget build(BuildContext context) {
      final currentList = _tabIndex == 0 ? widget.expenseList : widget.incomeList;
      final totalForChart = currentList.fold(0.0, (s, e) => s + e.value);
      
      final pieSections = currentList.map((e) {
         final cat = widget.categoryMap[e.key];
         final color = cat != null ? Color(cat.color) : Colors.grey;
         final percentage = totalForChart == 0 ? 0.0 : (e.value / totalForChart * 100);
         return PieChartSectionData(
           value: e.value,
           title: '${percentage.toStringAsFixed(0)}%',
           color: color,
           radius: 60,
           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
         );
      }).toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
             // Summary Card (Same as before)
             Card(
                     color: Theme.of(context).colorScheme.secondaryContainer,
                     child: Padding(
                       padding: const EdgeInsets.all(16),
                       child: Column(
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                               Column(
                                 children: [
                                   Text('Total Income', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                   Text('${widget.currency}${widget.totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                 ],
                               ),
                               Column(
                                 children: [
                                   Text('Total Expense', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                   Text('${widget.currency}${widget.totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                 ],
                               ),
                             ],
                           ),
                           const Divider(height: 24),
                           Text('Net Result', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                           const Gap(4),
                           Text('${widget.currency}${widget.netResult.toStringAsFixed(2)}', 
                             style: TextStyle(
                               fontWeight: FontWeight.bold, 
                               fontSize: 28,
                               color: widget.netResult > 0 ? Colors.red : Colors.teal
                             )),
                         ],
                       ),
                     ),
                   ),
             const Gap(24),
             
             // Toggle
             Center(
               child: SegmentedButton<int>(
                 segments: const [
                   ButtonSegment(value: 0, label: Text('Expense Breakdown')),
                   ButtonSegment(value: 1, label: Text('Income Breakdown')),
                 ],
                 selected: {_tabIndex},
                 onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
               ),
             ),
             
             const Gap(24),
             if (pieSections.isNotEmpty) ...[
                 AspectRatio(
                   aspectRatio: 1.5,
                   child: PieChart(
                     PieChartData(
                       sections: pieSections,
                       sectionsSpace: 2,
                       centerSpaceRadius: 40,
                     ),
                   ),
                 ),
                 const Gap(16),
                 ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: currentList.length,
                   itemBuilder: (context, index) {
                     final e = currentList[index];
                     final cat = widget.categoryMap[e.key];
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 8),
                       child: Row(
                         children: [
                           Container(width: 12, height: 12, decoration: BoxDecoration(color: cat != null ? Color(cat.color) : Colors.grey, shape: BoxShape.circle)),
                           const Gap(8),
                           Expanded(child: Text(cat?.name ?? 'Unknown', overflow: TextOverflow.ellipsis)),
                           Text('${widget.currency}${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                         ],
                       ),
                     );
                   },
                 ),
             ] else 
                 const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No data for this category'))),

        ],
      );
  }
}

