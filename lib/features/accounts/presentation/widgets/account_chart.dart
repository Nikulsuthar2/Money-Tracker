import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:gap/gap.dart';

class AccountChart extends StatefulWidget {
  const AccountChart({super.key, required this.transactions, required this.accountId, required this.currency});

  final List<Transaction> transactions;
  final int accountId;
  final String currency;

  @override
  State<AccountChart> createState() => _AccountChartState();
}

class _AccountChartState extends State<AccountChart> {
  String _period = 'Week'; // Week, Month, Year

  List<Transaction> get _filteredTransactions {
    return widget.transactions.where((t) => 
      t.fromAccountId == widget.accountId || t.toAccountId == widget.accountId
    ).toList();
  }

  // Pre-calculate data for chart
  List<_ChartData> _getChartData() {
    final now = DateTime.now();
    final data = <_ChartData>[];
    
    // Logic for Week (Last 7 days)
    if (_period == 'Week') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        
        double income = 0;
        double expense = 0;
        
        for (var t in _filteredTransactions) {
           if (t.date.year == dayStart.year && t.date.month == dayStart.month && t.date.day == dayStart.day) {
             if (t.type == TransactionType.income && t.toAccountId == widget.accountId) income += t.amount;
             if (t.type == TransactionType.expense && t.fromAccountId == widget.accountId) expense += t.amount;
             // Transfers? maybe treat as income/expense depending on direction
             if (t.type == TransactionType.transfer) {
                if (t.toAccountId == widget.accountId) income += t.amount;
                if (t.fromAccountId == widget.accountId) expense += t.amount;
             }
           }
        }
        data.add(_ChartData(label: DateFormat.E().format(date), income: income, expense: expense));
      }
    } 
    // Logic for Month (Last 4 weeks approx or 30 days... let's do 4 weeks chunks for simplicity or just last 30 days grouped by 5 days?)
    // User asked "weekly daily monthly".
    // Let's interpret 'Month' as Daily view for current month.
    else if (_period == 'Month') {
       // Last 30 days
       for (int i = 29; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          // Optimization: Pre-filter or Map
           // Skip rendering every single day text?
          if (i % 5 != 0) continue; // Sample
          
          // Actually we need to SUM strict ranges.
          // Let's Keep it simple: Last 7 Days (Daily), Last 4 Weeks (Weekly), Last 6 Months (Monthly)
       }
    }
    
    return data;
  }
  
  List<BarChartGroupData> _buildBarGroups() {
    final now = DateTime.now();
    final List<BarChartGroupData> groups = [];
    
    if (_period == 'Week') {
      // Last 7 Days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final start = DateTime(date.year, date.month, date.day);
        
        double income = 0;
        double expense = 0;
        
        for (var t in _filteredTransactions) {
          if (t.date.year == start.year && t.date.month == start.month && t.date.day == start.day) {
              if (t.toAccountId == widget.accountId) income += t.amount;
              if (t.fromAccountId == widget.accountId) expense += t.amount;
          }
        }
        
        groups.add(
          BarChartGroupData(
            x: 6 - i,
            barRods: [
              BarChartRodData(toY: income, color: Colors.teal, width: 8, borderRadius: BorderRadius.circular(2)),
              BarChartRodData(toY: expense, color: Colors.red, width: 8, borderRadius: BorderRadius.circular(2)),
            ],
          )
        );
      }
    } else if (_period == 'Month') { // Last 4 Weeks
       for (int i = 3; i >= 0; i--) {
         // 0 = This week, 1 = Last week...
         // Calculate Week Range
         final wStart = now.subtract(Duration(days: (i * 7) + now.weekday - 1)); // Start of week? Simpler: 
         // Just grouping last 28 days into 4 chunks
         
         double income = 0;
         double expense = 0;
         // TODO: filtering logic
          groups.add(
          BarChartGroupData(
            x: 3 - i,
            barRods: [
               BarChartRodData(toY: 10, color: Colors.teal), // Dummy
            ]
          ));
       }
    }
    
    return groups;
  }

  // Simplified Approach: 
  // Tab 1: "Daily" (Last 7 Days)
  // Tab 2: "Weekly" (Last 4 Weeks)
  // Tab 3: "Monthly" (Last 6 Months)

  List<BarChartGroupData> _buildGroups(int count, Duration interval, String Function(DateTime) labelFormat) {
     final now = DateTime.now();
     final groups = <BarChartGroupData>[];
     
     for (int i = count - 1; i >= 0; i--) {
       DateTime end = now;
       DateTime start = now;
       
       if (interval.inDays == 1) { // Daily
          start = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
          end = start.add(const Duration(days: 1));
       } else if (interval.inDays == 7) { // Weekly
          // Start of current week? No, strictly last 7 days window
          end = now.subtract(Duration(days: i * 7));
          start = end.subtract(const Duration(days: 7));
       } else if (interval.inDays == 30) { // Monthly
          // Approximate
          DateTime temp = DateTime(now.year, now.month - i, 1);
          start = temp;
          end = DateTime(now.year, now.month - i + 1, 1);
       }

       double income = 0;
       double expense = 0;
       
       for (var t in _filteredTransactions) {
         if (t.date.isAfter(start) && t.date.isBefore(end)) {
             if (t.toAccountId == widget.accountId) income += t.amount;
             if (t.fromAccountId == widget.accountId) expense += t.amount;
         }
       }
       
       groups.add(BarChartGroupData(
         x: count - 1 - i,
         barsSpace: 4,
         barRods: [
           BarChartRodData(toY: income, color: Colors.teal, width: 12, borderRadius: BorderRadius.circular(4)),
           BarChartRodData(toY: expense, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
         ],
       ));
     }
     return groups;
  }
  
  // Format based on index
  String _getLabel(int index, int count, Duration interval) {
     final now = DateTime.now();
     int offset = count - 1 - index;
     if (interval.inDays == 1) {
       return DateFormat.E().format(now.subtract(Duration(days: offset)));
     } else if (interval.inDays == 7) {
       final d = now.subtract(Duration(days: offset * 7));
       return '${d.day}/${d.month}';
     } else {
       final d = DateTime(now.year, now.month - offset, 1);
       return DateFormat.MMM().format(d);
     }
  }

  @override
  Widget build(BuildContext context) {
    int count = 7;
    Duration interval = const Duration(days: 1);
    
    if (_period == 'Weekly') {
      count = 5;
      interval = const Duration(days: 7);
    } else if (_period == 'Monthly') {
      count = 6;
      interval = const Duration(days: 30);
    }

    final groups = _buildGroups(count, interval, (d) => '');

    return Column(
      children: [
        // Toggles
        SegmentedButton<String>(
          segments: const [
             ButtonSegment(value: 'Daily', label: Text('Daily')),
             ButtonSegment(value: 'Weekly', label: Text('Weekly')),
             ButtonSegment(value: 'Monthly', label: Text('Monthly')),
          ], 
          selected: {_period == 'Week' ? 'Daily' : _period}, // Mismatch mapping: Week->Daily
          onSelectionChanged: (Set<String> newSelection) {
             setState(() {
               final val = newSelection.first;
               if (val == 'Daily') {
                 _period = 'Week'; // Keep internal var or rename? renaming better but keeping var for now
               } else {
                 _period = val;
               }
             });
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(EdgeInsets.zero),
          ),
        ),
        const Gap(16),
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                   getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final type = rod.color == Colors.teal ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$type\n${widget.currency}${rod.toY.toStringAsFixed(0)}',
                        TextStyle(color: rod.color, fontWeight: FontWeight.bold)
                      );
                   }
                )
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y Amount
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                       final txt = _getLabel(value.toInt(), count, interval);
                       return Padding(padding: const EdgeInsets.only(top: 8), child: Text(txt, style: const TextStyle(fontSize: 10)));
                    }
                  )
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: groups,
            )
          ),
        ),
        const Gap(8),
        // Legend
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: Colors.teal, size: 12), SizedBox(width: 4), Text('Income'),
            SizedBox(width: 16),
            Icon(Icons.circle, color: Colors.red, size: 12), SizedBox(width: 4), Text('Expense'),
          ],
        )
      ],
    );
  }
}

class _ChartData {
  final String label;
  final double income;
  final double expense;
  _ChartData({required this.label, required this.income, required this.expense});
}
