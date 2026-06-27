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
import 'package:money_manager/features/people/application/people_balances_provider.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
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
    final balancesAsync = ref.watch(peopleBalancesProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(timelineProvider);
              ref.invalidate(peopleBalancesProvider);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'edit') {
                _showEditDialog(context, ref);
              } else if (val == 'delete') {
                _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Friend')),
            ],
          ),
        ],
      ),
      body: timelineAsync.when(
        data: (allEntries) {
          // Filter entries to ONLY those involving this person
          final List<TimelineEntry> personEntries = [];
          for (final entry in allEntries) {
            if (entry is TransactionTimelineEntry) {
               bool involved = false;
               for (final e in entry.expenses) {
                  if (e.paidByPersonId == person.id) involved = true;
                  for (final splitList in entry.splits.values) {
                     if (splitList.any((s) => s.personId == person.id)) involved = true;
                  }
               }
               if (entry.settlement != null) {
                 if (entry.settlement!.fromPersonId == person.id || entry.settlement!.toPersonId == person.id) {
                   involved = true;
                 }
               }
               if (involved) personEntries.add(entry);
            } else if (entry is ExpenseOnlyTimelineEntry) {
               bool involved = false;
               for (final e in entry.expenses) {
                  if (e.paidByPersonId == person.id) involved = true;
                  for (final splitList in entry.splits.values) {
                     if (splitList.any((s) => s.personId == person.id)) involved = true;
                  }
               }
               if (involved) personEntries.add(entry);
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
                    
                    return balancesAsync.when(
                      data: (peopleBalances) {
                        final pBalance = peopleBalances.firstWhere(
                          (p) => p.person.id == person.id,
                          orElse: () => PersonWithBalance(person: person, balance: 0),
                        );
                        
                        double owedToMe = pBalance.balance > 0 ? pBalance.balance : 0;
                        double iOwe = pBalance.balance < 0 ? pBalance.balance.abs() : 0;
                        
                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          const Text('Owes me', style: TextStyle(color: Colors.green)),
                                          const Gap(4),
                                          Text('$currency${owedToMe.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Card(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          const Text('I owe', style: TextStyle(color: Colors.red)),
                                          const Gap(4),
                                          Text('$currency${iOwe.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Gap(8),
                            if (personEntries.isEmpty)
                               const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No history found.')))
                            else
                               ...personEntries.map((entry) => TimelineEntryTile(
                                   entry: entry,
                                   accountMap: accountMap,
                                   categoryMap: catMap,
                                   onTapTransaction: (t) => context.push('/transaction-details', extra: t),
                               )),
                          ],
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: person.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final updatedPerson = Person()..id = person.id..name = newName;
                await ref.read(peopleRepositoryProvider).updatePerson(updatedPerson);
                if (ctx.mounted) Navigator.pop(ctx);
                // Also pop the current page since the name changed, or we can just invalidate.
                // Invalidate is enough since people stream will update, but wait, the page takes Person as param.
                // To reflect name change instantly in app bar, popping might be best, but we'll just pop dialog.
                if (context.mounted) context.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Friend'),
        content: const Text('Are you sure you want to delete this friend? This will not delete their transaction history, but they will be removed from your friends list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(peopleRepositoryProvider).deletePerson(person.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
