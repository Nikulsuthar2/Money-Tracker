import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
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
import 'package:money_manager/features/transactions/presentation/widgets/transactions_filter_sheet.dart';
import 'package:money_manager/features/transactions/providers/transaction_filters_provider.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/core/widgets/custom_refresh_indicator.dart';
import 'package:gap/gap.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isCompact = false;

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TransactionsFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineProvider);
    final filters = ref.watch(advancedTransactionsFilterProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      body: timelineAsync.when(
        data: (allEntries) {
            final entries = allEntries.where((e) {
              if (e is TransactionTimelineEntry) {
                if (!filters.showTransactions) return false;
                final t = e.transaction;
                
                if (!filters.showInvestments) {
                   if (t.type == TransactionType.buyInvestment || t.type == TransactionType.sellInvestment) return false;
                   if (t.title != null && t.title!.contains('Brokerage / Fund Correction')) return false;
                }
                
                // Compare only the date part so that transactions on the same day are included
                final tDateOnly = DateTime(t.date.year, t.date.month, t.date.day);
                if (filters.startDate != null) {
                   final sDate = DateTime(filters.startDate!.year, filters.startDate!.month, filters.startDate!.day);
                   if (tDateOnly.isBefore(sDate)) return false;
                }
                if (filters.endDate != null) {
                   final eDate = DateTime(filters.endDate!.year, filters.endDate!.month, filters.endDate!.day);
                   if (tDateOnly.isAfter(eDate)) return false;
                }
                
                if (filters.types.isNotEmpty && !filters.types.contains(t.type)) return false;
                if (filters.categoryIds.isNotEmpty) {
                  // Wait, how to filter by category if it's split?
                  // For now, check if t.categoryId is in filters or if it has expenses with those categories
                  // Actually `t.categoryId` is straightforward. Split categories are fetched later.
                  if (t.categoryId != null && !filters.categoryIds.contains(t.categoryId)) {
                     // Check if it's a split transaction matching it? 
                     // Let's just do a simple check for now.
                     return false;
                  }
                  if (t.categoryId == null) return false; // If not categorized, it doesn't match
                }
              }
              if (e is SettlementTimelineEntry) {
                if (!filters.showSettlements) return false;
              }
              if (e is ExpenseOnlyTimelineEntry) {
                if (!filters.showFriendPaid) return false;
              }
              return true;
            }).toList();

            // Group entries by date
            final grouped = <DateTime, List<TimelineEntry>>{};
            double totalIncome = 0;
            double totalExpense = 0;

            for (var e in entries) {
              if (e is TransactionTimelineEntry) {
                final t = e.transaction;
                if (!t.skipFromStats) {
                  if (t.type == TransactionType.income) totalIncome += t.amount;
                  if (t.type == TransactionType.expense)
                    totalExpense += t.amount;
                }
              }

              final date = DateTime(e.date.year, e.date.month, e.date.day);
              if (grouped.containsKey(date)) {
                grouped[date]!.add(e);
              } else {
                grouped[date] = [e];
              }
            }
            final sortedDates = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return accountsAsync.when(
              data: (accountsStats) {
                final accountMap = {
                  for (var s in accountsStats) s.account.id: s.account,
                };

                return categoriesAsync.when(
                  data: (categories) {
                    final catMap = {for (var c in categories) c.id: c};

                    return CustomRefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(timelineProvider);
                        ref.invalidate(accountsWithBalanceProvider);
                        await Future.delayed(const Duration(milliseconds: 300));
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            pinned: true,
                            backgroundColor: Colors.transparent,
                            expandedHeight: 180,
                            flexibleSpace: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                                ),
                              ),
                            ),
                            bottom: PreferredSize(
                              preferredSize: const Size.fromHeight(150),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Transactions',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(_isCompact ? Icons.view_agenda : Icons.view_headline),
                                          tooltip: _isCompact ? 'Comfortable View' : 'Concise View',
                                          onPressed: () => setState(() => _isCompact = !_isCompact),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.filter_list),
                                          tooltip: 'Filters',
                                          onPressed: _openFilters,
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
                                    const Gap(16),
                                    Card(
                                      elevation: 0,
                                      color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.6),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.arrow_downward, size: 16, color: Colors.teal),
                                                      Gap(8),
                                                      Text('Total Income', style: TextStyle(color: Colors.teal)),
                                                    ],
                                                  ),
                                                  const Gap(8),
                                                  Text(
                                                    '$currency${totalIncome.toStringAsFixed(0)}',
                                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 1, height: 50, color: Theme.of(context).colorScheme.outlineVariant,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                                                      Gap(8),
                                                      Text('Total Expense', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                  const Gap(8),
                                                  Text(
                                                    '$currency${totalExpense.toStringAsFixed(0)}',
                                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (entries.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80),
                                child: const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No activity found')))
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final date = sortedDates[index];
            
                                    final dayEntries = grouped[date]!;
                                    
                                    // Calculate daily net movement
                                    double dailyNet = 0;
                                    for (var e in dayEntries) {
                                       if (e is TransactionTimelineEntry) {
                                          if (!e.transaction.skipFromStats) {
                                            if (e.transaction.type == TransactionType.income) dailyNet += e.transaction.amount;
                                            if (e.transaction.type == TransactionType.expense) dailyNet -= e.transaction.amount;
                                          }
                                       }
                                    }
            
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withOpacity(0.5),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  DateFormat.yMMMd().format(date),
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              if (dailyNet != 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (dailyNet > 0 ? Colors.teal : Colors.red).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${dailyNet > 0 ? '+' : ''}${dailyNet.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color: dailyNet > 0 ? Colors.teal : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        ...dayEntries.map((entry) {
                                          return TimelineEntryTile(
                                            entry: entry,
                                            accountMap: accountMap,
                                            categoryMap: catMap,
                                            compact: _isCompact,
                                            onTapTransaction: (t) {
                                              context.push(
                                                '/transaction-details',
                                                extra: t,
                                              );
                                            },
                                          );
                                        }),
                                        const Gap(8),
                                      ],
                                    );
                                  },
                                  childCount: sortedDates.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      );
    }
  }
