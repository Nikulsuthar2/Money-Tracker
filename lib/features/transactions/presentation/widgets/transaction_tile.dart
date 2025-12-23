import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.onTap,
  });

  final Transaction transaction;
  final String accountName;
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

    final icon = t.type == TransactionType.income
        ? Icons.arrow_downward
        : t.type == TransactionType.expense
            ? Icons.arrow_upward
            : Icons.compare_arrows;

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
                      t.note?.isNotEmpty == true ? t.note! : t.type.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        if (t.subTransactions != null && t.subTransactions!.isNotEmpty) ...[
                             Icon(Icons.call_split, size: 12, color: theme.colorScheme.onSurfaceVariant),
                             const Gap(4),
                             Text('${t.subTransactions!.length} splits',
                                 style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                              const Gap(8),
                        ],
                        Text(
                          DateFormat.yMMMd().format(t.date),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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
