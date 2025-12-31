import 'package:flutter/material.dart';
import 'dart:io';
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

class PartyDetailsPage extends ConsumerStatefulWidget {
  const PartyDetailsPage({super.key, required this.party});

  final Party party;

  @override
  ConsumerState<PartyDetailsPage> createState() => _PartyDetailsPageState();
}

class _PartyDetailsPageState extends ConsumerState<PartyDetailsPage> {
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerService = ref.watch(ledgerServiceProvider);
    final currencySymbol = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.party.name),
        actions: [
           if (!Platform.isAndroid)
             IconButton(
               icon: const Icon(Icons.refresh), 
               onPressed: () => setState((){}) // Trigger Rebuild Future
             ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           setState(() {});
           await Future.delayed(const Duration(milliseconds: 300));
        },
        child: FutureBuilder<List<LedgerEntry>>(
        future: ledgerService.getLedgerEntriesForParty(widget.party.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];
          entries.sort((a, b) {
             final orderA = a.sortOrder ?? double.maxFinite;
             final orderB = b.sortOrder ?? double.maxFinite;
             // Sort by order ASC, then Date DESC
             final res = orderA.compareTo(orderB);
             if (res != 0) return res;
             return b.date.compareTo(a.date);
          });

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
                        future: ledgerService.getOutstandingBalance(widget.party.id),
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
                   : ReorderableListView.builder(
                             itemCount: entries.length,
                             onReorder: (oldIndex, newIndex) {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = entries.removeAt(oldIndex);
                                entries.insert(newIndex, item);
                                
                                // Update Sort Order
                                for (int i = 0; i < entries.length; i++) {
                                   entries[i].sortOrder = i.toDouble();
                                }
                                // Save
                                ref.read(ledgerServiceProvider).updateLedgerEntries(entries);
                             },
                             itemBuilder: (context, index) {
                                final entry = entries[index];
                                return ListTile(
                                   key: ValueKey(entry.id),
                                   contentPadding: EdgeInsets.zero,
                                   title: LedgerEntryCompactTile(entry: entry, currencySymbol: currencySymbol),
                                   trailing: ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(Icons.drag_handle, color: Colors.grey),
                                      ),
                                   ),
                                );
                             },
                          ),
               ),
            ],
          );
        }
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           // We'll just open AddTransaction in Settlement mode.
           context.push('/add-transaction'); 
        },
        label: const Text('Add Transaction / Settle'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}


