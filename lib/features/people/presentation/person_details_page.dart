import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/transactions/application/timeline_provider.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/transactions/presentation/widgets/timeline_entry_tile.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class PersonDetailsPage extends ConsumerWidget {
  final Person person;

  const PersonDetailsPage({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: timelineAsync.when(
        data: (allEntries) {
          // Filter entries to ONLY those involving this person
          final List<TimelineEntry> personEntries = [];

          for (final entry in allEntries) {
            if (entry is TransactionTimelineEntry) {
               // Check if they are involved in the transaction's linked expenses
               bool involved = false;
               for (final e in entry.expenses) {
                  if (e.paidByPersonId == person.id) involved = true;
                  // We would ideally check splits too, but currently TimelineProvider doesn't attach splits to expenses directly.
                  // Wait! The user's rule: "Friend-paid expenses should ALWAYS appear inside Person Details."
                  // To strictly follow this without a complex query, we might need to fetch the person's explicit history.
               }
               // Also check if they paid the actual transaction? (No, transactions are always "Me" or Bank).
               if (involved) personEntries.add(entry);
            } else if (entry is ExpenseOnlyTimelineEntry) {
               bool involved = false;
               for (final e in entry.expenses) {
                  if (e.paidByPersonId == person.id) involved = true;
               }
               if (involved) personEntries.add(entry);
            } else if (entry is SettlementTimelineEntry) {
               if (entry.settlement.fromPersonId == person.id || entry.settlement.toPersonId == person.id) {
                 personEntries.add(entry);
               }
            }
          }

          if (personEntries.isEmpty) {
            return const Center(child: Text('No history found for this person.'));
          }

          return accountsAsync.when(
             data: (accountsStats) {
                final accountMap = {for (var s in accountsStats) s.account.id: s.account};
                return categoriesAsync.when(
                  data: (categories) {
                    final catMap = {for (var c in categories) c.id: c};
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: personEntries.length,
                      itemBuilder: (context, index) {
                         return TimelineEntryTile(
                            entry: personEntries[index],
                            accountMap: accountMap,
                            categoryMap: catMap,
                            onTapTransaction: (t) => context.push('/transaction-details', extra: t),
                         );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
