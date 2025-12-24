import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';

import 'package:money_manager/features/categories/domain/category.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.category,
    this.onTap,
  });

  final Transaction transaction;
  final String accountName;
  final Category? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);

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
      margin: const EdgeInsets.only(bottom: 12), // Increased margin
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3), // Slightly transparent
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const Gap(16),
              
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? (t.subTransactions?.isNotEmpty == true ? 'Split Transaction' : (t.type.name[0].toUpperCase() + t.type.name.substring(1))),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.note?.isNotEmpty == true)
                          Text(t.note!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                        
                        if (t.subTransactions != null && t.subTransactions!.isNotEmpty) ...[
                             const Gap(2),
                             // Show first 2 splits as example
                             ...t.subTransactions!.take(2).map((s) => Text(
                               '• \$${s.amount.toStringAsFixed(0)} ${s.note?.isNotEmpty==true ? "(${s.note})" : ""}',
                               style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                             )),
                             if (t.subTransactions!.length > 2)
                               Text('+ ${t.subTransactions!.length - 2} more', style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                        ],

                        const Gap(4),
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(t.date),
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Account
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      accountName,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
