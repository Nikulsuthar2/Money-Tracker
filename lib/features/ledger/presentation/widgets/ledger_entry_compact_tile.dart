import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
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
