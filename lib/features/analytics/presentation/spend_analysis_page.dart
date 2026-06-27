import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/categories/presentation/category_icon_widget.dart';
import 'package:gap/gap.dart';

class SpendAnalysisPage extends ConsumerStatefulWidget {
  const SpendAnalysisPage({super.key});

  @override
  ConsumerState<SpendAnalysisPage> createState() => _SpendAnalysisPageState();
}

class _SpendAnalysisPageState extends ConsumerState<SpendAnalysisPage> {
  String _period = 'Monthly'; // Monthly, Yearly, Custom
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;

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

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = 'Custom';
      });
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    return all.where((t) {
      if (t.skipFromStats) return false;
      if (t.type != TransactionType.expense) return false; // Spend Analysis only looks at expenses

      if (_period == 'Monthly') {
        return t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
      } else if (_period == 'Yearly') {
        return t.date.year == _selectedDate.year;
      } else if (_period == 'Custom' && _customRange != null) {
        return !t.date.isBefore(_customRange!.start) && !t.date.isAfter(_customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(analyticsTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    String dateLabel = '';
    if (_period == 'Monthly') dateLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_period == 'Yearly') dateLabel = DateFormat('yyyy').format(_selectedDate);
    if (_period == 'Custom') {
      if (_customRange != null) {
        dateLabel = '${DateFormat.yMMMd().format(_customRange!.start)} - ${DateFormat.yMMMd().format(_customRange!.end)}';
      } else {
        dateLabel = 'Select Range';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spend Analysis'),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final transactions = _filterTransactions(allTransactions ?? []);
          
          return categoriesAsync.when(
            data: (categories) {
              final catMap = {for (var c in categories) c.id: c};
              
              // Group by Category
              final categoryTotals = <int, double>{};
              double totalSpend = 0;
              
              for (var t in transactions) {
                final catId = t.categoryId ?? -1;
                categoryTotals[catId] = (categoryTotals[catId] ?? 0) + t.amount;
                totalSpend += t.amount;
              }

              final sortedEntries = categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected: _period == 'Monthly',
                          onSelected: (val) {
                            if (val) setState(() => _period = 'Monthly');
                          },
                        ),
                        const Gap(8),
                        ChoiceChip(
                          label: const Text('Yearly'),
                          selected: _period == 'Yearly',
                          onSelected: (val) {
                            if (val) setState(() => _period = 'Yearly');
                          },
                        ),
                        const Gap(8),
                        ChoiceChip(
                          label: const Text('Custom Range'),
                          selected: _period == 'Custom',
                          onSelected: (val) {
                            if (val) _pickCustomRange();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  
                  // Date Navigator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _period == 'Custom' ? null : _prevPeriod, 
                          icon: const Icon(Icons.chevron_left)
                        ),
                        GestureDetector(
                          onTap: _period == 'Custom' ? _pickCustomRange : null,
                          child: Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        ),
                        IconButton(
                          onPressed: _period == 'Custom' ? null : _nextPeriod, 
                          icon: const Icon(Icons.chevron_right)
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  
                  if (transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No spending for this period.')))
                  else ...[
                    // Total Spend Overview
                    Center(
                      child: Column(
                        children: [
                          const Text('Total Spend', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const Gap(4),
                          Text('$currency${totalSpend.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                    const Gap(32),
                    
                    // Chart
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sortedEntries.map((e) {
                            final isUncategorized = e.key == -1;
                            final cat = isUncategorized ? null : catMap[e.key];
                            final color = isUncategorized ? Colors.grey.shade400 : (cat != null ? Color(cat.color) : Colors.grey);
                            final pct = (e.value / totalSpend) * 100;
                            
                            return PieChartSectionData(
                              value: e.value,
                              title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                              color: color,
                              radius: 50,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                        ),
                      ),
                    ),
                    const Gap(32),
                    
                    // List
                    const Text('Top Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Gap(16),
                    ...sortedEntries.map((e) {
                        final isUncategorized = e.key == -1;
                        final cat = isUncategorized ? null : catMap[e.key];
                        final color = isUncategorized ? Colors.grey.shade400 : (cat != null ? Color(cat.color) : Colors.grey);
                        final name = isUncategorized ? 'Uncategorized' : (cat?.name ?? 'Unknown');
                        final pct = (e.value / totalSpend) * 100;

                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                                  child: cat != null 
                                      ? CategoryIconWidget(iconData: cat.iconData, color: cat.color, size: 24)
                                      : Icon(Icons.help_outline, color: color),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const Gap(4),
                                      LinearProgressIndicator(
                                        value: e.value / totalSpend,
                                        backgroundColor: color.withOpacity(0.1),
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$currency${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                    }),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
