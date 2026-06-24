import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/core/widgets/icon_utils.dart';
import 'package:go_router/go_router.dart';

class TimelineEntryTile extends ConsumerWidget {
  const TimelineEntryTile({
    super.key,
    required this.entry,
    required this.accountMap,
    required this.categoryMap,
    this.compact = false,
    required this.onTapTransaction,
  });

  final TimelineEntry entry;
  final Map<int, dynamic> accountMap;
  final Map<int, Category> categoryMap;
  final bool compact;
  final Function(Transaction) onTapTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry is TransactionTimelineEntry) {
      final tEntry = entry as TransactionTimelineEntry;
      final t = tEntry.transaction;
      final accountId = t.type == TransactionType.income ? t.toAccountId : t.fromAccountId;
      final accountName = accountId != null ? accountMap[accountId]?.name ?? 'Unknown' : 'Unknown';
      final category = t.categoryId != null ? categoryMap[t.categoryId] : null;

      // Group multiple expenses
      if (tEntry.expenses.length > 1) {
         // It's a grouped transaction
         final title = t.title?.isNotEmpty == true ? t.title! : '${category?.name ?? 'Multiple Items'} + ${tEntry.expenses.length - 1} more';
         return _buildCard(
           context,
           ref,
           icon: Icons.receipt_long,
           color: Colors.purple,
           title: title,
           subtitle: accountName,
           amount: t.amount,
           isIncome: false,
           onTap: () => onTapTransaction(t),
         );
      }

      return TransactionTile(
        transaction: t,
        accountName: accountName,
        category: category,
        compact: compact,
        onTap: () => onTapTransaction(t),
      );
    } 
    
    if (entry is ExpenseOnlyTimelineEntry) {
      final eEntry = entry as ExpenseOnlyTimelineEntry;
      if (eEntry.expenses.isEmpty) return const SizedBox.shrink();
      final firstExp = eEntry.expenses.first;
      final category = firstExp.categoryId != null ? categoryMap[firstExp.categoryId] : null;
      
      final title = firstExp.note?.isNotEmpty == true ? firstExp.note! : 
                    (eEntry.expenses.length > 1 ? 'Multiple Expenses' : (category?.name ?? 'Expense'));
      
      final totalAmount = eEntry.expenses.fold(0.0, (sum, e) => sum + e.totalAmount);
      
      return _buildCard(
         context,
         ref,
         icon: Icons.group,
         color: Colors.orange,
         title: title,
         subtitle: 'Paid by Friend',
         amount: totalAmount,
         isIncome: false,
         onTap: () {
            context.push('/expense-details', extra: eEntry);
         },
      );
    }
    
    if (entry is SettlementTimelineEntry) {
      final sEntry = entry as SettlementTimelineEntry;
      return _buildCard(
         context,
         ref,
         icon: Icons.handshake,
         color: Colors.blue,
         title: 'Settlement',
         subtitle: 'Debt cleared',
         amount: sEntry.settlement.amount,
         isIncome: true, // or neutral
         onTap: () {
            final peopleMap = ref.read(peopleStreamProvider).value?.fold<Map<int, String>>({}, (map, p) {
               map[p.id] = p.name;
               return map;
            }) ?? {};
            
            final fromName = sEntry.settlement.fromPersonId == 0 ? 'Me' : (peopleMap[sEntry.settlement.fromPersonId] ?? 'Person ${sEntry.settlement.fromPersonId}');
            final toName = sEntry.settlement.toPersonId == 0 ? 'Me' : (peopleMap[sEntry.settlement.toPersonId] ?? 'Person ${sEntry.settlement.toPersonId}');

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Settlement Details'),
                content: Text('$fromName paid $toName\n${ref.read(currencyProvider)}${formatAmount(sEntry.settlement.amount)}'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                ],
              ),
            );
         },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required double amount,
    required bool isIncome,
    required VoidCallback onTap,
  }) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 4 : 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 12 : 16)),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Row(
            children: [
              Container(
                width: compact ? 32 : 48,
                height: compact ? 32 : 48,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: compact ? 18 : 24),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 15 : 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!compact) ...[
                      const Gap(4),
                      Text(subtitle, style: TextStyle(color: theme.colorScheme.outline, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const Gap(8),
              Text(
                '${isIncome ? '+' : '-'}$currency${formatAmount(amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 15 : 17, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
