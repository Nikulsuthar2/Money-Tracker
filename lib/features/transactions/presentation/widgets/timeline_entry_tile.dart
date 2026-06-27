import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      bool isSplit = false;
      bool hasMultipleCategories = false;
      if (tEntry.expenses.isNotEmpty) {
         isSplit = tEntry.expenses.length > 1;
         if (!isSplit) {
            final eSplits = tEntry.splits[tEntry.expenses.first.id];
            isSplit = eSplits != null && eSplits.any((s) => s.personId != 0);
         } else {
            // Check if there are multiple unique categories
            final catIds = tEntry.expenses.map((e) => e.categoryId).where((id) => id != null).toSet();
            hasMultipleCategories = catIds.length > 1;
         }
      }
      if (!isSplit && t.subTransactions != null && t.subTransactions!.isNotEmpty) {
         isSplit = t.subTransactions!.length > 1 || t.subTransactions!.any((s) => s.partyId != null);
         if (t.subTransactions!.length > 1) {
             final catIds = t.subTransactions!.map((s) => s.categoryId).where((id) => id != null).toSet();
             hasMultipleCategories = catIds.length > 1;
         }
      }

      return TransactionTile(
        transaction: t,
        accountName: accountName,
        category: category,
        compact: compact,
        isSplit: isSplit,
        hasMultipleCategories: hasMultipleCategories,
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
         date: firstExp.date,
         amount: totalAmount,
         isIncome: false,
         onTap: () {
            context.push('/expense-details', extra: eEntry);
         },
      );
    }
    
    // Settlement entries are now rendered by TransactionTile since they use TransactionTimelineEntry
    return const SizedBox.shrink();
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime date,
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
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, y').format(date),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}$currency${formatAmount(amount)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 15 : 18, color: color),
                  ),
                  if (!compact) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(subtitle, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
