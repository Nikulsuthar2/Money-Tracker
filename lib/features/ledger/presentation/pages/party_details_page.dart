import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/ledger/data/ledger_service.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';

class PartyDetailsPage extends ConsumerWidget {
  const PartyDetailsPage({super.key, required this.party});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledgerService = ref.watch(ledgerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
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
          
          // Calculate Totals locally for immediate display (or use service)
          double netBalance = 0;
          for (var e in entries) {
             // If Receivable (I get money): Positive
             // If Payable (I owe money): Negative
             // But let's check Nature more closely or just sum logic
             if (e.nature == LedgerNature.receivable) netBalance += e.amount;
             if (e.nature == LedgerNature.payable) netBalance -= e.amount;
             // Settlement?
             // If I receive settlement (Income) -> Reduces Receivable (Credit)
             // If I pay settlement (Expense) -> Reduces Payable (Debit)
             // LedgerService likely handles "Balance" more complexes.
             // Ideally we ask Service for "Balance".
          }

          return Column(
            children: [
               // Header Card
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 color: theme.colorScheme.surface,
                 child: Column(
                   children: [
                      Text('Outstanding Balance', style: theme.textTheme.titleMedium),
                      const Gap(8),
                      // We should ideally fetch precise balance from service
                      FutureBuilder<double>(
                        future: ledgerService.getOutstandingBalance(party.id),
                        builder: (c, s) {
                           final bal = s.data ?? 0.0;
                           final isPositive = bal >= 0; 
                           // If Positive: They Owe Me (Green)
                           // If Negative: I Owe Them (Red)
                           return Text(
                             '\$${bal.abs().toStringAsFixed(2)}',
                             style: theme.textTheme.displayMedium?.copyWith(
                               color: isPositive ? Colors.green : Colors.red,
                               fontWeight: FontWeight.bold
                             ),
                           );
                        }
                      ),
                      const Gap(8),
                      FutureBuilder<double>(
                        future: ledgerService.getOutstandingBalance(party.id),
                        builder: (c, s) {
                           final bal = s.data ?? 0.0;
                           if (bal == 0) return const Text('Settled', style: TextStyle(color: Colors.grey));
                           return Text(bal > 0 ? 'You are owed' : 'You owe', style: TextStyle(color: theme.colorScheme.secondary));
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
                       separatorBuilder: (c, i) => const Divider(height: 1),
                       itemBuilder: (context, index) {
                          // Sort by date desc
                          // We should probably sort the list first.
                          // Assuming service returns raw, let's sort here for safety
                          entries.sort((a, b) => b.date.compareTo(a.date));
                          
                          final entry = entries[index];
                          final isReceivable = entry.nature == LedgerNature.receivable;
                          final isPayable = entry.nature == LedgerNature.payable;
                          
                          return ListTile(
                             leading: Icon(
                                isReceivable ? Icons.arrow_downward : (isPayable ? Icons.arrow_upward : Icons.check_circle),
                                color: isReceivable ? Colors.green : (isPayable ? Colors.red : Colors.blue),
                             ),
                             title: Text(entry.note ?? entry.nature.name),
                             subtitle: Text(DateFormat.yMMMd().format(entry.date)),
                             trailing: Text(
                                '\$${entry.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isReceivable ? Colors.green : (isPayable ? Colors.red : Colors.blue)
                                )
                             ),
                             onTap: () {
                                if (entry.transactionId != null) {
                                   // We need to fetch transaction first to push it (or pass ID if route supports it)
                                   // AppRouter defines /transaction-details taking 'extra: Transaction'.
                                   // So we must fetch it.
                                   // We can't fetch easily here without TransactionsRepository.
                                   // Todo: Implement navigation to transaction
                                }
                             },
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
           // Settle Up Flow?
           // For now just generic Add
        },
        label: const Text('Settle Up (Coming Soon)'),
        icon: const Icon(Icons.attach_money),
      ),
    );
  }
}
