import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

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
        actions: [
          Padding(
             padding: const EdgeInsets.only(right: 16),
             child: DropdownButton<String>(
               value: _viewMode,
               underline: const SizedBox(),
               items: const [
                 DropdownMenuItem(value: 'Month', child: Text('Monthly')),
                 DropdownMenuItem(value: 'Year', child: Text('Yearly')),
                 DropdownMenuItem(value: 'All', child: Text('All Time')),
               ],
               onChanged: (v) {
                 if (v != null) setState(() => _viewMode = v);
               },
             ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_viewMode != 'All') IconButton(onPressed: _prevPeriod, icon: const Icon(Icons.arrow_back_ios)),
                Text(_viewMode == 'All' ? 'All Time' : dateFormat!.format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_viewMode != 'All') IconButton(onPressed: _nextPeriod, icon: const Icon(Icons.arrow_forward_ios)),
              ],
            ),
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final transactions = _filterTransactions(allTransactions ?? []);
          
          if (transactions.isEmpty) {
             return const Center(child: Text('No data for selected period'));
          }
          
          // Calculate Net Logic
          // We want to group by Category to show "Net Expense" per category.
          // And show Total Income vs Total Expense vs Net.
          
          double totalIncome = 0;
          double totalExpense = 0;
          double totalTransfer = 0; // Just for info, usually ignored in Net?

           final categoryNetMap = <int, double>{};
           final incomeMap = <int, double>{}; // Track income separately

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
           final positiveIncome = incomeMap.entries.where((e) => e.value > 0).toList(); // Simple Income Sum
           
           final netExpenseTotal = totalExpense - totalIncome;

           return StreamBuilder<List<Category>>(
              stream: categoriesAsync,
              builder: (context, catSnapshot) {
                final categories = catSnapshot.data ?? [];
                final categoryMap = {for (var c in categories) c.id: c};
                
                // Toggle State?
                // We need a local state for toggling charts. Since this is inside a builder...
                // Ideally we lift state up or use a ValueNotifier/local variable.
                // Let's just show BOTH or use a TabBar-like toggle.
                
                return _AnalyticsContent(
                   totalIncome: totalIncome,
                   totalExpense: totalExpense,
                   netResult: netExpenseTotal,
                   expenseList: positiveExpenses,
                   incomeList: positiveIncome,
                   categoryMap: categoryMap,
                   totalTransfer: totalTransfer,
                );
              }
           );
         },
         loading: () => const Center(child: CircularProgressIndicator()),
         error: (e, s) => Center(child: Text('Error: $e')),
       ),
     );
  }
}

class _AnalyticsContent extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final double netResult;
  final double totalTransfer;
  final List<MapEntry<int, double>> expenseList;
  final List<MapEntry<int, double>> incomeList;
  final Map<int, Category> categoryMap;

  const _AnalyticsContent({
    required this.totalIncome,
    required this.totalExpense,
    required this.netResult,
    required this.expenseList,
    required this.incomeList,
    required this.categoryMap,
    required this.totalTransfer,
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
                                   Text('\$${widget.totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                 ],
                               ),
                               Column(
                                 children: [
                                   Text('Total Expense', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                   Text('\$${widget.totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                 ],
                               ),
                             ],
                           ),
                           const Divider(height: 24),
                           Text('Net Result', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                           const Gap(4),
                           Text('\$${widget.netResult.toStringAsFixed(2)}', 
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
                           Text('\$${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

