import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:gap/gap.dart';

class AccountHistoryTab extends ConsumerStatefulWidget {
  final Account account;
  final List<Transaction> transactions;

  const AccountHistoryTab({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  ConsumerState<AccountHistoryTab> createState() => _AccountHistoryTabState();
}

class _AccountHistoryTabState extends ConsumerState<AccountHistoryTab> {
  int _filterIndex = 0; // 0: All, 1: Income, 2: Expense
  String _period = 'Month'; // Month, Year, All
  DateTime _selectedDate = DateTime.now();

  void _prevPeriod() {
    setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  void _showPeriodSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Month'),
              onTap: () {
                setState(() => _period = 'Month');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Year'),
              onTap: () {
                setState(() => _period = 'Year');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Time'),
              onTap: () {
                setState(() => _period = 'All');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final theme = Theme.of(context);

    // Apply Time Filter
    List<Transaction> timeFilteredTransactions = widget.transactions;
    if (_period == 'Month') {
      timeFilteredTransactions = widget.transactions.where((t) => t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();
    } else if (_period == 'Year') {
      timeFilteredTransactions = widget.transactions.where((t) => t.date.year == _selectedDate.year).toList();
    }

    // Apply Type Filter
    List<Transaction> filtered = timeFilteredTransactions;
    if (_filterIndex == 1) {
      filtered = filtered.where((t) => t.type == TransactionType.income).toList();
    } else if (_filterIndex == 2) {
      filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
    }

    final grouped = <DateTime, List<Transaction>>{};
    for (var t in filtered) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      if (!grouped.containsKey(date)) grouped[date] = [];
      grouped[date]!.add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    String dateLabel = 'All Time';
    if (_period == 'Month') dateLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_period == 'Year') dateLabel = DateFormat('yyyy').format(_selectedDate);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Period Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      onPressed: _period == 'All' ? null : _prevPeriod, 
                      icon: const Icon(Icons.chevron_left),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
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
                    IconButton.filledTonal(
                      onPressed: _period == 'All' ? null : _nextPeriod, 
                      icon: const Icon(Icons.chevron_right),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const Gap(16),
              // Type Selector
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All')),
                    ButtonSegment(value: 1, label: Text('Income')),
                    ButtonSegment(value: 2, label: Text('Expense')),
                  ],
                  selected: {_filterIndex},
                  showSelectedIcon: false,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _filterIndex = newSelection.first;
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No transactions found')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              DateFormat.yMMMd().format(date),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        ...grouped[date]!.map((t) {
                          final category = t.categoryId != null ? categoriesAsync.value?.firstWhereOrNull((c) => c.id == t.categoryId) : null;
                          return TransactionTile(
                            transaction: t,
                            accountName: widget.account.name,
                            category: category,
                            compact: false,
                            onTap: () => context.push('/transaction-details', extra: t),
                          );
                        }),
                        const Gap(8),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
