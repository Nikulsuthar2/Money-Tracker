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
  String _filter = 'Month'; // Month, Year, All

  List<Transaction> _filterTransactions(List<Transaction> all) {
    if (_filter == 'All') return all;
    
    final now = DateTime.now();
    return all.where((t) {
      if (_filter == 'Month') {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (_filter == 'Year') {
        return t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesRepositoryProvider).watchAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Month', label: Text('This Month')),
                ButtonSegment(value: 'Year', label: Text('This Year')),
                ButtonSegment(value: 'All', label: Text('All Time')),
              ],
              selected: {_filter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filter = newSelection.first;
                });
              },
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
          
          // Calculate Income vs Expense
          double income = 0;
          double expense = 0;
          for (var t in transactions) {
            if (t.type == TransactionType.income) income += t.amount;
            if (t.type == TransactionType.expense) expense += t.amount;
          }

          // Pie Chart Data (Category Wise Expense)
          final Map<int, double> beneficialMap = <int, double>{};
          for (var t in transactions) {
             if (t.type == TransactionType.expense && t.categoryId != null) {
               beneficialMap[t.categoryId!] = (beneficialMap[t.categoryId!] ?? 0) + t.amount;
             }
          }
          
          return StreamBuilder<List<Category>>(
             stream: categoriesAsync,
             builder: (context, catSnapshot) {
               final categories = catSnapshot.data ?? [];
               final categoryMap = {for (var c in categories) c.id: c};
               
               final pieSections = beneficialMap.entries.map((e) {
                 final cat = categoryMap[e.key];
                 final color = cat != null ? Color(cat.color) : Colors.grey;
                 return PieChartSectionData(
                   value: e.value,
                   title: '${(e.value / (expense == 0 ? 1 : expense) * 100).toStringAsFixed(0)}%',
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
                           Text(_filter == 'All' ? 'All Time Overview' : (_filter == 'Month' ? DateFormat('MMMM yyyy').format(DateTime.now()) : DateFormat('yyyy').format(DateTime.now())), 
                               style: Theme.of(context).textTheme.titleMedium),
                           const Gap(16),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                               Column(
                                 children: [
                                   const Text('Income', style: TextStyle(color: Colors.teal)),
                                   Text('\$${income.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                                 ],
                               ),
                               Column(
                                 children: [
                                   const Text('Expense', style: TextStyle(color: Colors.red)),
                                   Text('\$${expense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                                 ],
                               ),
                             ],
                           ),
                           const Divider(height: 32),
                           Text('Net: \$${(income - expense).toStringAsFixed(2)}', 
                             style: TextStyle(
                               fontWeight: FontWeight.bold, 
                               fontSize: 24,
                               color: (income - expense) >= 0 ? Colors.teal : Colors.red
                             )),
                         ],
                       ),
                     ),
                   ),
                   const Gap(24),
                   const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const Gap(16),
                   if (pieSections.isNotEmpty)
                     AspectRatio(
                       aspectRatio: 1.3,
                       child: Row(
                         children: [
                           Expanded(
                             child: PieChart(
                               PieChartData(
                                 sections: pieSections,
                                 sectionsSpace: 2,
                                 centerSpaceRadius: 40,
                               ),
                             ),
                           ),
                           // Legend
                           const Gap(16),
                           Expanded(
                             child: ListView(
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               children: beneficialMap.entries.map((e) {
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
                               }).toList(),
                             ),
                           )
                         ],
                       ),
                     )
                   else 
                     const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No expenses to show'))),
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
