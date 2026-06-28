import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/providers/transaction_filters_provider.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:gap/gap.dart';

class TransactionsFilterSheet extends ConsumerStatefulWidget {
  const TransactionsFilterSheet({super.key});

  @override
  ConsumerState<TransactionsFilterSheet> createState() => _TransactionsFilterSheetState();
}

class _TransactionsFilterSheetState extends ConsumerState<TransactionsFilterSheet> {
  late TransactionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = ref.read(advancedTransactionsFilterProvider);
  }

  void _apply() {
    ref.read(advancedTransactionsFilterProvider.notifier).updateFilters(_filters);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _filters = const TransactionFilters();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filters.startDate != null && _filters.endDate != null
          ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _filters = _filters.copyWith(
          startDate: picked.start,
          endDate: picked.end,
          clearMonth: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                // Activity Types
                const Text('Activity Types', style: TextStyle(fontWeight: FontWeight.bold)),
                const Gap(8),
                CheckboxListTile(
                  title: const Text('Regular Transactions'),
                  value: _filters.showTransactions,
                  onChanged: (v) => setState(() => _filters = _filters.copyWith(showTransactions: v)),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Settlements'),
                  value: _filters.showSettlements,
                  onChanged: (v) => setState(() => _filters = _filters.copyWith(showSettlements: v)),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Expenses Paid By Others'),
                  value: _filters.showFriendPaid,
                  onChanged: (v) => setState(() => _filters = _filters.copyWith(showFriendPaid: v)),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Investment Transactions'),
                  value: _filters.showInvestments,
                  onChanged: (v) => setState(() => _filters = _filters.copyWith(showInvestments: v)),
                  dense: true,
                ),
                const Gap(16),

                // Date Range
                const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const Gap(8),
                ListTile(
                  title: Text(
                    _filters.startDate != null && _filters.endDate != null
                        ? '${DateFormat.yMMMd().format(_filters.startDate!)} - ${DateFormat.yMMMd().format(_filters.endDate!)}'
                        : 'Any time',
                  ),
                  trailing: const Icon(Icons.date_range),
                  onTap: _pickDateRange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                if (_filters.startDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _filters = _filters.copyWith(clearDates: true)),
                      child: const Text('Clear Dates'),
                    ),
                  ),
                const Gap(16),

                // Transaction Types
                const Text('Transaction Types', style: TextStyle(fontWeight: FontWeight.bold)),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TransactionType.values.map((type) {
                    final isSelected = _filters.types.contains(type);
                    return FilterChip(
                      label: Text(type.name.capitalize()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          final newTypes = Set<TransactionType>.from(_filters.types);
                          if (selected) newTypes.add(type);
                          else newTypes.remove(type);
                          _filters = _filters.copyWith(types: newTypes);
                        });
                      },
                    );
                  }).toList(),
                ),
                const Gap(16),

                // Categories
                const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                const Gap(8),
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const Text('No categories available');
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((c) {
                        final isSelected = _filters.categoryIds.contains(c.id);
                        return FilterChip(
                          label: Text(c.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              final newIds = Set<int>.from(_filters.categoryIds);
                              if (selected) newIds.add(c.id);
                              else newIds.remove(c.id);
                              _filters = _filters.copyWith(categoryIds: newIds);
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading categories'),
                ),
              ],
            ),
          ),
          const Gap(16),
          FilledButton(
            onPressed: _apply,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Apply Filters', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
