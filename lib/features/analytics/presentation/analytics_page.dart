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

          final Map<int, double> categoryNetMap = {}; // CatId -> (Expense - Income)

          for (var t in transactions) {
            double effectiveAmount = t.amount;
            List<SubTransaction> relevantSplits = [];
            
            if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
               // verify if we should use splits
               // If split, effective expense is sum of isMine splits
               // effective income... usually splits are for Expense.
               // Let's assume splits override the main amount distribution for analytics
               relevantSplits = t.subTransactions!;
               // If there are splits, we ignore the main amount and iterate splits
               
               for (var s in relevantSplits) {
                 if (!s.isMine) continue; // Skip not mine

                 if (t.type == TransactionType.income) {
                    totalIncome += s.amount;
                    if (s.categoryId != null) {
                       categoryNetMap[s.categoryId!] = (categoryNetMap[s.categoryId!] ?? 0) - s.amount;
                    }
                 } else if (t.type == TransactionType.expense) {
                    totalExpense += s.amount;
                    if (s.categoryId != null) {
                       categoryNetMap[s.categoryId!] = (categoryNetMap[s.categoryId!] ?? 0) + s.amount;
                    }
                 }
               }
               // Transfer splits? usually not used.
            } else {
              // No splits, use main transaction
              if (t.type == TransactionType.income) {
                 totalIncome += t.amount;
                 if (t.categoryId != null) {
                    categoryNetMap[t.categoryId!] = (categoryNetMap[t.categoryId!] ?? 0) - t.amount;
                 }
              } else if (t.type == TransactionType.expense) {
                 totalExpense += t.amount;
                 if (t.categoryId != null) {
                    categoryNetMap[t.categoryId!] = (categoryNetMap[t.categoryId!] ?? 0) + t.amount;
                 }
              } else {
                 totalTransfer += t.amount;
              }
            }
          }
          
          // Filter out categories that end up being <= 0 (Net Income or Zero) for the Pie Chart?
          // Or just show positive expenses. User wants "Expense Breakdown".
          final positiveExpenses = categoryNetMap.entries.where((e) => e.value > 0).toList();
          final netExpenseTotal = totalExpense - totalIncome; // Simplified global net

          return StreamBuilder<List<Category>>(
             stream: categoriesAsync,
             builder: (context, catSnapshot) {
               final categories = catSnapshot.data ?? [];
               final categoryMap = {for (var c in categories) c.id: c};
               
               // Prepare Pie Chart Data
               final pieSections = positiveExpenses.map((e) {
                 final cat = categoryMap[e.key];
                 final color = cat != null ? Color(cat.color) : Colors.grey;
                 // Percentage of NET POSITIVE expenses?
                 // Or percentage of Total Expense? Using value / sum(positiveValues)
                 final sumPositive = positiveExpenses.fold(0.0, (s, item) => s + item.value);
                 final percentage = sumPositive == 0 ? 0.0 : (e.value / sumPositive * 100);

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
                   // Summary Card
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
                                   Text('\$${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                 ],
                               ),
                               Column(
                                 children: [
                                   Text('Total Expense', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                   Text('\$${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                 ],
                               ),
                             ],
                           ),
                           const Divider(height: 24),
                           Text('Net Result (Expense - Income)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                           const Gap(4),
                           Text('\$${netExpenseTotal.toStringAsFixed(2)}', 
                             style: TextStyle(
                               fontWeight: FontWeight.bold, 
                               fontSize: 28,
                               color: netExpenseTotal > 0 ? Colors.red : Colors.teal
                             )),
                           if (totalTransfer > 0) ...[
                             const Gap(8),
                             Text('Transfers: \$${totalTransfer.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                           ]
                         ],
                       ),
                     ),
                   ),
                   const Gap(24),
                   const Text('Net Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const Text('Income in a category reduces its expense (Refund logic)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                   const Gap(16),
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
                     // Legend List below Chart
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: positiveExpenses.length,
                       itemBuilder: (context, index) {
                         final e = positiveExpenses[index];
                         final cat = categoryMap[e.key];
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
                     const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No net expenses'))),
                 ],
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
