import 'package:flutter/material.dart';
import 'dart:ui' as dart_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class CategorySpendingPage extends ConsumerStatefulWidget {
  final int categoryId;
  final String period;
  final String? startDateStr;
  final String? endDateStr;

  const CategorySpendingPage({
    super.key,
    required this.categoryId,
    required this.period,
    this.startDateStr,
    this.endDateStr,
  });

  @override
  ConsumerState<CategorySpendingPage> createState() => _CategorySpendingPageState();
}

class _CategorySpendingPageState extends ConsumerState<CategorySpendingPage> {
  late String _period;
  late DateTime _selectedDate;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _period = widget.period;
    _selectedDate = widget.startDateStr != null ? DateTime.parse(widget.startDateStr!) : DateTime.now();
    if (_period == 'Custom' && widget.startDateStr != null && widget.endDateStr != null) {
      _customRange = DateTimeRange(
        start: DateTime.parse(widget.startDateStr!),
        end: DateTime.parse(widget.endDateStr!),
      );
    }
  }

  DateTime? get _startDate {
    if (_period == 'Monthly') return DateTime(_selectedDate.year, _selectedDate.month, 1);
    if (_period == 'Yearly') return DateTime(_selectedDate.year, 1, 1);
    if (_period == 'Custom') return _customRange?.start;
    return null;
  }
  
  DateTime? get _endDate {
    if (_period == 'Monthly') return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    if (_period == 'Yearly') return DateTime(_selectedDate.year, 12, 31);
    if (_period == 'Custom') return _customRange?.end;
    return null;
  }

  String _formatAmount(double value) {
    return value == value.truncateToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  void _nextPeriod() {
    setState(() {
      if (_period == 'Monthly') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      } else if (_period == 'Yearly') {
        _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
      }
    });
  }

  void _prevPeriod() {
    setState(() {
      if (_period == 'Monthly') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      } else if (_period == 'Yearly') {
        _selectedDate = DateTime(_selectedDate.year - 1, 1, 1);
      }
    });
  }

  void _showPeriodSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select Period', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Gap(16),
                      ListTile(
                        title: const Text('Monthly'),
                        trailing: _period == 'Monthly' ? const Icon(Icons.check, color: Colors.teal) : null,
                        onTap: () {
                          setState(() {
                            _period = 'Monthly';
                            _selectedDate = DateTime.now();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: const Text('Yearly'),
                        trailing: _period == 'Yearly' ? const Icon(Icons.check, color: Colors.teal) : null,
                        onTap: () {
                          setState(() {
                            _period = 'Yearly';
                            _selectedDate = DateTime.now();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: const Text('Custom Range'),
                        trailing: _period == 'Custom' ? const Icon(Icons.check, color: Colors.teal) : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: _customRange,
                          );
                          if (range != null) {
                            setState(() {
                              _period = 'Custom';
                              _customRange = range;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
        title: const Text('Category Details'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final cat = widget.categoryId == -1 ? null : categories.firstWhere((c) => c.id == widget.categoryId);
          final catName = widget.categoryId == -1 ? 'Uncategorized' : (cat?.name ?? 'Unknown');
          final color = widget.categoryId == -1 ? Colors.grey : Color(cat?.color ?? Colors.grey.value);

          return transactionsAsync.when(
            data: (allTransactions) {
              // 1. Calculate Period Spend
              double periodSpend = 0;
              final periodTransactions = <Transaction>[];

              for (var t in allTransactions) {
                if (t.skipFromStats) continue;
                if (t.isSettlement || t.mode == TransactionMode.settlement) continue;
                if (t.type != TransactionType.expense && t.type != TransactionType.buyInvestment) continue;

                // Adjust for sub-transactions logic
                double catAmount = 0;
                bool belongsToCat = false;
                
                if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                  for (var sub in t.subTransactions!) {
                    bool isMine = false;
                    double amt = 0;
                    int subCatId = t.categoryId ?? -1;
                    
                    if (sub is SubTransaction) {
                      isMine = sub.isMine;
                      amt = sub.amount;
                      if (sub.categoryId != null) subCatId = sub.categoryId!;
                    } else if (sub is Map) {
                      isMine = sub['isMine'] == true;
                      amt = (sub['amount'] as num?)?.toDouble() ?? 0.0;
                      if (sub['categoryId'] != null) subCatId = sub['categoryId'] as int;
                    } else if (sub.runtimeType.toString() == 'SubTransaction' || sub.runtimeType.toString() == 'SubTransactionItem') {
                      try {
                        isMine = sub.isMine == true;
                        amt = (sub.amount as num).toDouble();
                        if (sub.categoryId != null) subCatId = sub.categoryId as int;
                      } catch (_) {}
                    }
                    
                    if (isMine && subCatId == widget.categoryId) {
                      catAmount += amt;
                      belongsToCat = true;
                    }
                  }
                } else {
                  if ((t.categoryId ?? -1) == widget.categoryId) {
                    catAmount = t.amount;
                    belongsToCat = true;
                  }
                }

                if (belongsToCat) {
                  // Check if in period
                  bool inPeriod = false;
                  if (widget.period == 'Monthly' && _startDate != null) {
                    inPeriod = t.date.year == _startDate!.year && t.date.month == _startDate!.month;
                  } else if (widget.period == 'Yearly' && _startDate != null) {
                    inPeriod = t.date.year == _startDate!.year;
                  } else if (widget.period == 'Custom' && _startDate != null && _endDate != null) {
                    inPeriod = !t.date.isBefore(_startDate!) && !t.date.isAfter(_endDate!.add(const Duration(days: 1)));
                  } else {
                     // Fallback
                     inPeriod = true;
                  }

                  if (inPeriod) {
                    periodSpend += catAmount;
                    // Create a cloned transaction with just the category amount for display
                    final displayTx = Transaction()
                      ..id = t.id
                      ..type = t.type
                      ..amount = catAmount
                      ..date = t.date
                      ..title = t.title
                      ..note = t.note
                      ..categoryId = widget.categoryId;
                    periodTransactions.add(displayTx);
                  }
                }
              }
              
              periodTransactions.sort((a, b) => b.date.compareTo(a.date));

              // 2. Prepare Line Chart Data (Last 6 Months)
              final now = DateTime.now();
              List<FlSpot> spots = [];
              double maxAmount = 0;
              final monthlyTotals = <DateTime, double>{};
              
              for (int i = 5; i >= 0; i--) {
                final date = DateTime(now.year, now.month - i, 1);
                monthlyTotals[date] = 0;
              }

              for (var t in allTransactions) {
                if (t.skipFromStats || t.isSettlement) continue;
                if (t.type != TransactionType.expense && t.type != TransactionType.buyInvestment) continue;

                double catAmount = 0;
                if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
                  for (var sub in t.subTransactions!) {
                    bool isMine = false;
                    double amt = 0;
                    int subCatId = t.categoryId ?? -1;
                    if (sub is SubTransaction) {
                      isMine = sub.isMine;
                      amt = sub.amount;
                      if (sub.categoryId != null) subCatId = sub.categoryId!;
                    } else if (sub is Map) {
                      isMine = sub['isMine'] == true;
                      amt = (sub['amount'] as num?)?.toDouble() ?? 0.0;
                      if (sub['categoryId'] != null) subCatId = sub['categoryId'] as int;
                    }
                    if (isMine && subCatId == widget.categoryId) catAmount += amt;
                  }
                } else {
                  if ((t.categoryId ?? -1) == widget.categoryId) catAmount = t.amount;
                }

                if (catAmount > 0) {
                  final mDate = DateTime(t.date.year, t.date.month, 1);
                  if (monthlyTotals.containsKey(mDate)) {
                    monthlyTotals[mDate] = monthlyTotals[mDate]! + catAmount;
                  }
                }
              }

              int spotIndex = 0;
              final labels = <int, String>{};
              for (var entry in monthlyTotals.entries) {
                spots.add(FlSpot(spotIndex.toDouble(), entry.value));
                if (entry.value > maxAmount) maxAmount = entry.value;
                labels[spotIndex] = DateFormat('MMM').format(entry.key);
                spotIndex++;
              }
              
              if (maxAmount == 0) maxAmount = 100; // default ceiling

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _period == 'Custom' ? null : _prevPeriod, 
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showPeriodSelectorSheet(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _period,
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    const Gap(2),
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _period == 'Custom' ? null : _nextPeriod, 
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  Center(
                    child: Column(
                      children: [
                         Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                           child: Icon(cat?.iconData != null ? Icons.category : Icons.help_outline, color: color, size: 32), // Simplified icon for now
                         ),
                         const Gap(16),
                         Text(catName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                         const Gap(4),
                         Text('Total in ${widget.period}', style: const TextStyle(color: Colors.grey)),
                         Text('$currency${_formatAmount(periodSpend)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  ),
                  const Gap(32),
                  
                  const Text('6 Month Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
                      child: LineChart(
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
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final txt = labels[value.toInt()] ?? '';
                                  if (txt.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(txt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              preventCurveOverShooting: true,
                              color: color,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => theme.colorScheme.surface,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '$currency${_formatAmount(spot.y)}',
                                    TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(32),

                  const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  if (periodTransactions.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No transactions in this period.')))
                  else
                    ...periodTransactions.map((t) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.receipt_long, color: color, size: 20),
                        ),
                        title: Text(t.title ?? t.note ?? 'Expense'),
                        subtitle: Text(DateFormat.yMMMd().format(t.date)),
                        trailing: Text(
                          '$currency${_formatAmount(t.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () {
                          // Try to open the actual transaction if the ID is valid (> 0)
                          if (t.id > 0) {
                            // Find the full transaction from allTransactions
                            final fullTx = allTransactions.firstWhere((x) => x.id == t.id, orElse: () => t);
                            context.push('/transaction-details', extra: fullTx);
                          }
                        },
                      );
                    }).toList(),
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
