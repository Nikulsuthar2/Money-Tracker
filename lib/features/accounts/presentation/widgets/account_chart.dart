import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:gap/gap.dart';

class AccountChart extends StatefulWidget {
  const AccountChart({
      super.key, 
      required this.transactions, 
      required this.accountId, 
      required this.currency,
      required this.period,      // 'Month', 'Year', 'All'
      required this.focusedDate,
  });

  final List<Transaction> transactions;
  final int accountId;
  final String currency;
  final String period;
  final DateTime focusedDate;

  @override
  State<AccountChart> createState() => _AccountChartState();
}

class _AccountChartState extends State<AccountChart> {
  String _chartType = 'Bar'; // Bar, Line, Pie

  List<Transaction> get _filteredTransactions {
    // Parent already filters by time? 
    // Actually, parent filters the LIST, but chart might need raw data if we want to be safe?
    // User said: "In month and year add just below a calendar swiping".
    // If parent filters strictly to March 1-31, passing that list is fine.
    // But chart generation logic needs to know the boundaries to draw empty bars (e.g. Day 5 has 0 txn).
    // So we use widget.focusedDate to determine boundaries.
    return widget.transactions.where((t) => 
      t.fromAccountId == widget.accountId || t.toAccountId == widget.accountId
    ).toList();
  }
  
  // Date Logic Helper
  bool _isInRange(DateTime date, DateTime start, DateTime end) {
      return !date.isBefore(start) && date.isBefore(end);
  }

  // --- Data Builders ---
  
  List<BarChartGroupData> _buildBarGroups() {
     final groups = <BarChartGroupData>[];
     
     if (widget.period == 'Month') {
        // Daily bars for the specific Month
        final daysInMonth = DateTime(widget.focusedDate.year, widget.focusedDate.month + 1, 0).day;
        
        for (int day = 1; day <= daysInMonth; day++) {
             // Define precise range for Day
             final start = DateTime(widget.focusedDate.year, widget.focusedDate.month, day);
             final end = start.add(const Duration(days: 1));
             
             double income = 0;
             double expense = 0;
             
             for (var t in _filteredTransactions) {
               if (_isInRange(t.date, start, end)) {
                   if (t.toAccountId == widget.accountId) income += t.amount;
                   if (t.fromAccountId == widget.accountId) expense += t.amount;
               }
             }
             
             groups.add(BarChartGroupData(
               x: day,
               barsSpace: 2,
               barRods: [
                 BarChartRodData(toY: income, color: Colors.teal, width: 6, borderRadius: BorderRadius.circular(2)),
                 BarChartRodData(toY: expense, color: Colors.red, width: 6, borderRadius: BorderRadius.circular(2)),
               ],
             ));
        }
     } else if (widget.period == 'Year') {
        // Monthly bars for the specific Year
        for (int month = 1; month <= 12; month++) {
             // Range
             final start = DateTime(widget.focusedDate.year, month, 1);
             final end = DateTime(widget.focusedDate.year, month + 1, 1);
             
             double income = 0;
             double expense = 0;
             
             for (var t in _filteredTransactions) {
               if (_isInRange(t.date, start, end)) {
                   if (t.toAccountId == widget.accountId) income += t.amount;
                   if (t.fromAccountId == widget.accountId) expense += t.amount;
               }
             }

             groups.add(BarChartGroupData(
               x: month,
               barsSpace: 4,
               barRods: [
                 BarChartRodData(toY: income, color: Colors.teal, width: 8, borderRadius: BorderRadius.circular(2)),
                 BarChartRodData(toY: expense, color: Colors.red, width: 8, borderRadius: BorderRadius.circular(2)),
               ],
             ));
        }
     } else {
        // 'All' -> Show Last 5 Years?
        final currentYear = DateTime.now().year;
        for (int i = 4; i >= 0; i--) {
           final year = currentYear - i;
           final start = DateTime(year, 1, 1);
           final end = DateTime(year + 1, 1, 1);
           
           double income = 0;
           double expense = 0;
           
           for (var t in _filteredTransactions) {
             if (_isInRange(t.date, start, end)) {
                 if (t.toAccountId == widget.accountId) income += t.amount;
                 if (t.fromAccountId == widget.accountId) expense += t.amount;
             }
           }
           
           groups.add(BarChartGroupData(
             x: year,
             barsSpace: 8,
             barRods: [
               BarChartRodData(toY: income, color: Colors.teal, width: 12, borderRadius: BorderRadius.circular(4)),
               BarChartRodData(toY: expense, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
             ],
           ));
        }
     }
     
     return groups;
  }

  List<FlSpot> _buildLineSpots(bool isIncome) {
     final spots = <FlSpot>[];
     
     if (widget.period == 'Month') {
         final daysInMonth = DateTime(widget.focusedDate.year, widget.focusedDate.month + 1, 0).day;
         for (int day = 1; day <= daysInMonth; day++) {
             final start = DateTime(widget.focusedDate.year, widget.focusedDate.month, day);
             final end = start.add(const Duration(days: 1));
             double sum = 0;
             for (var t in _filteredTransactions) {
               if (_isInRange(t.date, start, end)) {
                   if (isIncome && t.toAccountId == widget.accountId) sum += t.amount;
                   if (!isIncome && t.fromAccountId == widget.accountId) sum += t.amount;
               }
             }
             spots.add(FlSpot(day.toDouble(), sum));
         }
     } else if (widget.period == 'Year') {
         for (int month = 1; month <= 12; month++) {
             final start = DateTime(widget.focusedDate.year, month, 1);
             final end = DateTime(widget.focusedDate.year, month + 1, 1);
             double sum = 0;
             for (var t in _filteredTransactions) {
               if (_isInRange(t.date, start, end)) {
                   if (isIncome && t.toAccountId == widget.accountId) sum += t.amount;
                   if (!isIncome && t.fromAccountId == widget.accountId) sum += t.amount;
               }
             }
             spots.add(FlSpot(month.toDouble(), sum));
         }
     }
     else {
         // 'All' -> Last 5 Years
         final currentYear = DateTime.now().year;
         for (int i = 4; i >= 0; i--) {
            final year = currentYear - i;
            final start = DateTime(year, 1, 1);
            final end = DateTime(year + 1, 1, 1);
            
            double sum = 0;
            for (var t in _filteredTransactions) {
              if (_isInRange(t.date, start, end)) {
                  if (isIncome && t.toAccountId == widget.accountId) sum += t.amount;
                  if (!isIncome && t.fromAccountId == widget.accountId) sum += t.amount;
              }
            }
            spots.add(FlSpot(year.toDouble(), sum));
         }
     }
     return spots;
  }
  
  List<PieChartSectionData> _buildPieSections() {
      // Aggregate strict range
      DateTime start, end;
      if (widget.period == 'Month') {
         start = DateTime(widget.focusedDate.year, widget.focusedDate.month, 1);
         end = DateTime(widget.focusedDate.year, widget.focusedDate.month + 1, 1);
      } else if (widget.period == 'Year') {
         start = DateTime(widget.focusedDate.year, 1, 1);
         end = DateTime(widget.focusedDate.year + 1, 1, 1);
      } else {
         start = DateTime(2000); // Far past
         end = DateTime(3000); // Far future
      }
      
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (var t in _filteredTransactions) {
         if (_isInRange(t.date, start, end)) {
             if (t.toAccountId == widget.accountId) totalIncome += t.amount;
             if (t.fromAccountId == widget.accountId) totalExpense += t.amount;
         }
      }
      
      if (totalIncome == 0 && totalExpense == 0) return [];
      
      final total = totalIncome + totalExpense;
      
      return [
        if (totalIncome > 0)
        PieChartSectionData(
          value: totalIncome, 
          color: Colors.teal, 
          title: '${((totalIncome/total)*100).toStringAsFixed(0)}%', 
          radius: 50, 
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          badgeWidget: _Badge(
             icon: Icons.arrow_downward, 
             color: Colors.teal, 
             text: '${widget.currency}${totalIncome.toStringAsFixed(0)}'
          ),
          badgePositionPercentageOffset: 1.3,
        ),
        if (totalExpense > 0)
        PieChartSectionData(
          value: totalExpense, 
          color: Colors.red, 
          title: '${((totalExpense/total)*100).toStringAsFixed(0)}%', 
          radius: 50, 
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          badgeWidget: _Badge(
             icon: Icons.arrow_upward, 
             color: Colors.red, 
             text: '${widget.currency}${totalExpense.toStringAsFixed(0)}'
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      ];
  }

  // Format Labels
  String _getLabel(double value) {
     final intVal = value.toInt();
     if (widget.period == 'Month') {
        if (intVal >= 1 && intVal <= 31) {
           // Show every 5th or if width permits
           if (intVal == 1 || intVal % 5 == 0) return intVal.toString();
        }
     } else if (widget.period == 'Year') {
        const m = ['J','F','M','A','M','J','J','A','S','O','N','D'];
        if (intVal >= 1 && intVal <= 12) return m[intVal-1];
     } else if (widget.period == 'All') {
        return intVal.toString(); // Year
     }
     return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row: Title + Type Toggle
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
              const Text('Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButton<String>(
                   value: _chartType,
                   underline: const SizedBox(),
                   isDense: true,
                   items: ['Bar', 'Line', 'Pie'].map((s) => DropdownMenuItem(value: s, child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(s == 'Bar' ? Icons.bar_chart : (s == 'Line' ? Icons.show_chart : Icons.pie_chart), size: 18, color: Theme.of(context).colorScheme.primary),
                       const Gap(8),
                       Text(s, style: const TextStyle(fontSize: 12)),
                     ],
                   ))).toList(),
                   onChanged: (v) => setState(() => _chartType = v!),
               ),
           ],
        ),
        
        const Gap(16),
        
        AspectRatio(
          aspectRatio: 1.5,
          child: _chartType == 'Bar' ? BarChart(
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
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                       final txt = _getLabel(value);
                       return Padding(padding: const EdgeInsets.only(top: 8), child: Text(txt, style: const TextStyle(fontSize: 10)));
                    }
                  )
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _buildBarGroups(),
            )
          ) : _chartType == 'Line' ? LineChart(
             LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                         final txt = _getLabel(value);
                         return Padding(padding: const EdgeInsets.only(top: 8), child: Text(txt, style: const TextStyle(fontSize: 10)));
                      }
                    )
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                   LineChartBarData(
                      spots: _buildLineSpots(true),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.1)),
                   ),
                   LineChartBarData(
                      spots: _buildLineSpots(false),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                   ),
                ]
             )
          ) : PieChart(
             PieChartData(
                sections: _buildPieSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
       padding: const EdgeInsets.all(4),
       decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
       ),
       child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(icon, color: color, size: 12),
             const Gap(4),
             Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
       ),
    );
  }
}

