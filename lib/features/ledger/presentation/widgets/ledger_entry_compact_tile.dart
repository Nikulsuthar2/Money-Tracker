import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class LedgerEntryCompactTile extends ConsumerWidget {
  const LedgerEntryCompactTile({super.key, required this.entry, required this.currencySymbol, this.onTapOverride});
  final LedgerEntry entry;
  final String currencySymbol;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<Party?>(
      future: ref.read(partyRepositoryProvider).getAllParties().then((l) => l.where((p) => p.id == entry.partyId).firstOrNull),
      builder: (context, snapshot) {
         final partyName = snapshot.data?.name ?? 'Unknown';
         
         String leftLabel = 'Me';
         String rightLabel = partyName;
         Color amountColor = Colors.grey;
         IconData arrowIcon = Icons.arrow_right_alt;
         String status = '';
         
         // Logic same as PartyDetailsPage / GlobalLedgerPage
         bool isSettlement = entry.nature == LedgerNature.paid;

         if (isSettlement) {
             // Settlement
             if (entry.amount > 0) { // +Pos = They Paid Me
                leftLabel = partyName;
                rightLabel = 'Me';
                amountColor = Colors.green;
                status = 'PAID';
             } else { // -Neg = I Paid Them
                leftLabel = 'Me';
                rightLabel = partyName;
                amountColor = Colors.red;
                status = 'PAID';
             }
         } else {
             // OWE
             if (entry.amount > 0) { // They Owe Me
                 leftLabel = partyName;
                 rightLabel = 'Me'; 
                 amountColor = Colors.orange;
                 status = 'OWES';
             } else { // I Owe Them
                 leftLabel = 'Me';
                 rightLabel = partyName;
                 amountColor = Colors.redAccent;
                 status = 'OWES';
             }
         }

         return InkWell(
           onLongPress: () {
              _showOptions(context, ref, entry);
           },
           onTap: onTapOverride ?? () async {
              if (entry.transactionId != null) {
                 final txn = await ref.read(transactionsRepositoryProvider).getTransaction(entry.transactionId!);
                 if (txn != null && context.mounted) {
                    context.push('/transaction-details', extra: txn);
                 }
              }
           },
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             child: Row(
               children: [
                 // Date
                 SizedBox(
                   width: 40,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(DateFormat('dd').format(entry.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                       Text(DateFormat('MMM').format(entry.date).toUpperCase(), style: TextStyle(fontSize: 10, color: theme.colorScheme.outline)),
                     ],
                   ),
                 ),
                 
                 const Gap(8),
                 
                 // Flow Visual
                 Expanded(
                   child: Row(
                     children: [
                        _CompactName(name: leftLabel, isMe: leftLabel == 'Me'),
                        const Gap(4),
                        Column(
                          children: [
                             Text(status, style: TextStyle(fontSize: 8, color: theme.colorScheme.outline)),
                             Icon(arrowIcon, size: 14, color: theme.colorScheme.outlineVariant),
                          ],
                        ),
                        const Gap(4),
                        _CompactName(name: rightLabel, isMe: rightLabel == 'Me'),
                     ],
                   ),
                 ),

                 // Amount
                 Text(
                   CurrencyFormatter.format(entry.amount.abs(), symbol: currencySymbol, compact: true),
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
                 ),
               ],
             ),
           ),
         );
      }
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, LedgerEntry entry) {
     showModalBottomSheet(
       context: context, 
       builder: (context) => SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             ListTile(
               leading: const Icon(Icons.edit),
               title: const Text('Edit Entry'),
               onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref, entry);
               },
             ),
             ListTile(
               leading: const Icon(Icons.delete, color: Colors.red),
               title: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
               onTap: () async {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, entry);
               },
             ),
           ],
         ),
       )
     );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, LedgerEntry entry) {
     final amountCtrl = TextEditingController(text: entry.amount.abs().toString());
     final noteCtrl = TextEditingController(text: entry.note ?? '');
     DateTime selectedDate = entry.date;
     int selectedPartyId = entry.partyId;
     LedgerNature selectedNature = entry.nature;
     bool isPositive = entry.amount >= 0;
     int? currentTransactionId = entry.transactionId;

     // Fetch parties
     ref.read(partyRepositoryProvider).getAllParties().then((parties) {
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              // Determine current flow index
              // 0: I Paid Party (Paid, -)
              // 1: Party Paid Me (Paid, +)
              // 2: I Owe Party (Owe, -)
              // 3: Party Owes Me (Owe, +)
              int flowIndex;
              if (selectedNature == LedgerNature.paid) {
                 flowIndex = isPositive ? 1 : 0;
              } else {
                 flowIndex = isPositive ? 3 : 2;
              }

              final party = parties.firstWhere((p) => p.id == selectedPartyId, orElse: () => parties.first);
              
              return AlertDialog(
                title: const Text('Edit Ledger Entry'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Party Dropdown
                       DropdownButtonFormField<int>(
                          value: selectedPartyId,
                          decoration: const InputDecoration(labelText: 'Party', border: OutlineInputBorder()),
                          items: parties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                          onChanged: (v) => setState(() => selectedPartyId = v!),
                       ),
                       const Gap(16),
                       // Flow Dropdown
                       DropdownButtonFormField<int>(
                          value: flowIndex,
                          decoration: const InputDecoration(labelText: 'Interaction Type', border: OutlineInputBorder()),
                          items: [
                             DropdownMenuItem(value: 0, child: Text('I Paid ${party.name}')),
                             DropdownMenuItem(value: 1, child: Text('${party.name} Paid Me')),
                             DropdownMenuItem(value: 2, child: Text('I Owe ${party.name}')),
                             DropdownMenuItem(value: 3, child: Text('${party.name} Owes Me')),
                          ],
                          onChanged: (v) {
                             setState(() {
                                flowIndex = v!;
                                // Update logic state
                                switch(v) {
                                   case 0: selectedNature = LedgerNature.paid; isPositive = false; break;
                                   case 1: selectedNature = LedgerNature.paid; isPositive = true; break;
                                   case 2: selectedNature = LedgerNature.owe; isPositive = false; break;
                                   case 3: selectedNature = LedgerNature.owe; isPositive = true; break;
                                }
                             });
                          },
                       ),
                       const Gap(16),
                       TextFormField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                       ),
                       const Gap(16),
                       TextFormField(
                          controller: noteCtrl,
                          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                       ),
                       const Gap(16),
                       ListTile(
                         title: const Text('Date'),
                         subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
                         trailing: const Icon(Icons.calendar_today),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                         onTap: () async {
                            final picked = await showDatePicker(
                              context: context, 
                              initialDate: selectedDate, 
                              firstDate: DateTime(2000), 
                              lastDate: DateTime(2100)
                            );
                            if (picked != null) {
                               setState(() => selectedDate = picked);
                            }
                         },
                       ),
                       if (currentTransactionId != null) ...[
                          const Gap(16),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                             ),
                             child: Row(
                                children: [
                                   const Icon(Icons.link, size: 20),
                                   const Gap(8),
                                   const Expanded(child: Text('Linked to Transaction', style: TextStyle(fontSize: 12))),
                                   TextButton.icon(
                                      onPressed: () => setState(() => currentTransactionId = null), 
                                      icon: const Icon(Icons.link_off, size: 16),
                                      label: const Text('Unlink'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                   )
                                ],
                             ),
                          )
                       ],
                    ],
                  ),
                ),
                actions: [
                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                   FilledButton(
                      onPressed: () async {
                         final newAmount = double.tryParse(amountCtrl.text);
                         if (newAmount == null) return;
   
                         final signedAmount = isPositive ? newAmount.abs() : -newAmount.abs();
                         
                         final updated = entry
                            ..amount = signedAmount
                            ..nature = selectedNature
                            ..partyId = selectedPartyId
                            ..note = noteCtrl.text
                            ..date = selectedDate
                            ..transactionId = currentTransactionId;
                         
                         await ref.read(ledgerServiceProvider).updateLedgerEntry(updated);
                         
                         if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save'),
                   )
                ],
              );
            }
          ),
        );
     });
  }
  
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, LedgerEntry entry) async {
      await showDialog(
        context: context, 
        builder: (c) => AlertDialog(
           title: const Text('Delete Entry?'),
           content: const Text('This will permanently remove this ledger record.'),
           actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
              TextButton(
                 onPressed: () async {
                    await ref.read(ledgerServiceProvider).deleteLedgerEntry(entry.id);
                    if (c.mounted) Navigator.pop(c);
                 }, 
                 child: const Text('Delete', style: TextStyle(color: Colors.red))
              )
           ],
        )
      );
  }
}

class _CompactName extends StatelessWidget {
  const _CompactName({required this.name, required this.isMe});
  final String name;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name, 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
