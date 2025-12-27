import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.category,
    this.onTap,
    this.compact = false,
  });

  final Transaction transaction;
  final String accountName;
  final Category? category;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    // Determine color based on type
    final color = t.type == TransactionType.income
        ? Colors.teal
        : t.type == TransactionType.expense
            ? Colors.redAccent
            : Colors.blue;

    IconData icon;
    if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
      icon = Icons.call_split;
    } else if (category != null) {
      icon = IconData(category!.icon, fontFamily: 'MaterialIcons');
    } else {
      icon = t.type == TransactionType.income
        ? Icons.arrow_downward
        : t.type == TransactionType.expense
            ? Icons.arrow_upward
            : Icons.compare_arrows;
    }

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 4 : 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: compact ? 32 : 48,
                height: compact ? 32 : 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: compact ? 18 : 24),
              ),
              const Gap(16),
              
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? (t.subTransactions?.isNotEmpty == true ? 'Split Transaction' : (t.type.name[0].toUpperCase() + t.type.name.substring(1))),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 14 : 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const Gap(4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (t.note?.isNotEmpty == true)
                            Text(t.note!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                          
                          if (t.subTransactions != null && t.subTransactions!.isNotEmpty) ...[
                               const Gap(2),
                               ...t.subTransactions!.take(2).map((s) => Text(
                                 '• $currency${s.amount.toStringAsFixed(0)} ${s.note?.isNotEmpty==true ? "(${s.note})" : ""}',
                                 style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                               )),
                               if (t.subTransactions!.length > 2)
                                 Text('+ ${t.subTransactions!.length - 2} more', style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                          ],

                          const Gap(4),
                          Row(
                            children: [
                              Text(
                                t.hasTime 
                                  ? DateFormat('MMM d, y • h:mm a').format(t.date)
                                  : DateFormat('MMM d, y').format(t.date),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Amount & Account
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                  if (!compact) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(accountName, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
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
