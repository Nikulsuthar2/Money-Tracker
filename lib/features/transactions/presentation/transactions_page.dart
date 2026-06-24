import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/application/timeline_provider.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/transactions/presentation/widgets/timeline_entry_tile.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';

final timelineFiltersProvider = StateProvider<Map<String, bool>>((ref) => {
  'transactions': true,
  'settlements': true,
  'friend_paid': false,
});

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isCompact = false;

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineProvider);
    final filters = ref.watch(timelineFiltersProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);

    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_isCompact ? Icons.view_agenda : Icons.view_headline),
            tooltip: _isCompact ? 'Comfortable View' : 'Concise View',
            onPressed: () => setState(() => _isCompact = !_isCompact),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'transactions',
                child: Row(children: [
                  Checkbox(value: filters['transactions'], onChanged: null),
                  const Text('Transactions'),
                ]),
              ),
              PopupMenuItem(
                value: 'settlements',
                child: Row(children: [
                  Checkbox(value: filters['settlements'], onChanged: null),
                  const Text('Settlements'),
                ]),
              ),
              PopupMenuItem(
                value: 'friend_paid',
                child: Row(children: [
                  Checkbox(value: filters['friend_paid'], onChanged: null),
                  const Text('Expenses Paid By Others'),
                ]),
              ),
            ],
            onSelected: (value) {
              ref.read(timelineFiltersProvider.notifier).update((state) {
                return {...state, value: !(state[value] ?? false)};
              });
            },
          ),
          if (!Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                 ref.invalidate(timelineProvider);
                 ref.invalidate(accountsWithBalanceProvider);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           ref.invalidate(timelineProvider);
           ref.invalidate(accountsWithBalanceProvider);
           await Future.delayed(const Duration(milliseconds: 300));
        },
        child: timelineAsync.when(
          data: (allEntries) {
          
          final entries = allEntries.where((e) {
             if (e is TransactionTimelineEntry) return filters['transactions'] == true;
             if (e is SettlementTimelineEntry) return filters['settlements'] == true;
             if (e is ExpenseOnlyTimelineEntry) return filters['friend_paid'] == true;
             return true;
          }).toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No activity found'));
          }
          
          // Group entries by date
          final grouped = <DateTime, List<TimelineEntry>>{};
          double totalIncome = 0;
          double totalExpense = 0;

          for (var e in entries) {
            if (e is TransactionTimelineEntry) {
               final t = e.transaction;
               if (!t.skipFromStats) {
                  if (t.type == TransactionType.income) totalIncome += t.amount;
                  if (t.type == TransactionType.expense) totalExpense += t.amount;
               }
            }

            final date = DateTime(e.date.year, e.date.month, e.date.day);
            if (grouped.containsKey(date)) {
              grouped[date]!.add(e);
            } else {
              grouped[date] = [e];
            }
          }
          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return accountsAsync.when(
            data: (accountsStats) {
               final accountMap = {for (var s in accountsStats) s.account.id: s.account};

               return categoriesAsync.when(
                 data: (categories) {
                   final catMap = {for (var c in categories) c.id: c};
                   
                   return ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
                    itemCount: sortedDates.length + 1, // +1 for Header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                         // Stats Header
                         return Card(
                           elevation: 0,
                           color: Theme.of(context).colorScheme.surfaceContainer,
                           margin: const EdgeInsets.only(bottom: 24),
                           child: Padding(
                             padding: const EdgeInsets.all(16),
                             child: Row(
                               children: [
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.center, // Centered
                                     children: [
                                       const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_downward, size: 16, color: Colors.teal), Gap(8), Text('Total Income', style: TextStyle(color: Colors.teal))]),
                                       const Gap(8),
                                       Consumer(builder: (c, ref, _) => Text('${ref.watch(currencyProvider)}${totalIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal))),
                                     ],
                                   ),
                                 ),
                                 Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outlineVariant),
                                 const Gap(16),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.center, // Centered
                                     children: [
                                       const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_upward, size: 16, color: Colors.red), Gap(8), Text('Total Expense', style: TextStyle(color: Colors.red))]),
                                       const Gap(8),
                                       Consumer(builder: (c, ref, _) => Text('${ref.watch(currencyProvider)}${totalExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red))),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         );
                      }

                      final date = sortedDates[index - 1];
                      final dayEntries = grouped[date]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Theme.of(context).colorScheme.surfaceContainerHighest 
                                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat.yMMMd().format(date),
                                style: TextStyle(
                                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12
                                ),
                              ),
                            ),
                          ),
                          ...dayEntries.map((e) {
                            return TimelineEntryTile(
                              entry: e,
                              accountMap: accountMap,
                              categoryMap: catMap,
                              compact: _isCompact,
                              onTapTransaction: (t) {
                                 context.push('/transaction-details', extra: t);
                              },
                            );
                          }),
                        ],
                      );
                    },
                  );
                 },
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (e, s) => Center(child: Text('Error loading categories: $e')),
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading accounts: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}


