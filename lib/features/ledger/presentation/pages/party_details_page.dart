import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/ledger/data/ledger_service.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/features/ledger/presentation/widgets/ledger_entry_compact_tile.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class PartyDetailsPage extends ConsumerWidget {
  const PartyDetailsPage({super.key, required this.party});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledgerService = ref.watch(ledgerServiceProvider);
    final currencySymbol = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
           // Quick Filter or Options?
        ],
      ),
      body: FutureBuilder<List<LedgerEntry>>(
        future: ledgerService.getLedgerEntriesForParty(party.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];
          entries.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
               // Header Card
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                 color: theme.colorScheme.surface,
                 child: Column(
                   children: [
                      Text('Outstanding Balance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
                      const Gap(8),
                      FutureBuilder<double>(
                        future: ledgerService.getOutstandingBalance(party.id),
                        builder: (c, s) {
                           final bal = s.data ?? 0.0;
                           final isPositive = bal >= 0; 
                           // Positive = They Owe Me (Green). Negative = I Owe Them (Red).
                           final color = bal == 0 ? theme.colorScheme.onSurface : (isPositive ? Colors.green : Colors.red);
                           
                           return Column(
                             children: [
                               Text(
                                 CurrencyFormatter.format(bal.abs(), symbol: currencySymbol),
                                 style: theme.textTheme.displayMedium?.copyWith(
                                   color: color,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 32
                                 ),
                               ),
                               const Gap(4),
                               if (bal != 0)
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: color.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Text(
                                     isPositive ? 'You are owed' : 'You owe',
                                     style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                   ),
                                 )
                               else
                                 const Text('Settled', style: TextStyle(color: Colors.grey)),
                             ],
                           );
                        }
                      ),
                   ],
                 ),
               ),
               const Divider(height: 1),
               
               // List
               Expanded(
                 child: entries.isEmpty 
                   ? const Center(child: Text('No history found'))
                   : ListView.separated(
                       itemCount: entries.length,
                       separatorBuilder: (c, i) => Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                       itemBuilder: (context, index) {
                          final entry = entries[index];
                          
                          return LedgerEntryCompactTile(
                            entry: entry, 
                            currencySymbol: currencySymbol,
                          );
                       },
                   ),
               ),
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           // We'll just open AddTransaction in Settlement mode.
           // Since we can't easily pass map params without updating router/page, 
           // let's just show a simple snackbar or open page generics for now till that is fixed?
           // Or assume user will select party.
           // Ideally update AddTransactionPage to accept 'extra' map? 
           // User Request: "Settle Up Button: Clarify usage"
           // Let's make it clear it's manual for now.
           context.push('/add-transaction'); 
        },
        label: const Text('Add Transaction / Settle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}


