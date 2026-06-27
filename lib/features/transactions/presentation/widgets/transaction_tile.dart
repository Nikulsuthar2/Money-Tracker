import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

import 'package:money_manager/core/widgets/icon_utils.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.category,
    this.onTap,
    this.compact = false,
    this.isSplit,
    this.hasMultipleCategories = false,
  });

  final Transaction transaction;
  final String accountName;
  final Category? category;
  final VoidCallback? onTap;
  final bool compact;
  final bool? isSplit;
  final bool hasMultipleCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    // Determine if it's a split transaction using Riverpod if not provided in the object
    bool isSplit = this.isSplit ?? false;
    if (this.isSplit == null) {
      if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
        isSplit =
            t.subTransactions!.length > 1 ||
            t.subTransactions!.any((s) => s.partyId != null);
      } else {
        final expenses = ref
            .watch(expensesStreamProvider)
            .value
            ?.where((e) => e.transactionId == t.id)
            .toList();
        if (expenses != null && expenses.isNotEmpty) {
          isSplit = expenses.length > 1;
          if (!isSplit) {
            final splits = ref
                .watch(expenseSplitsStreamProvider)
                .value
                ?.where((s) => s.expenseId == expenses.first.id)
                .toList();
            isSplit = splits != null && splits.any((s) => s.personId != 0);
          }
        }
      }
    }

    // Determine color based on type
    Color color =
        (t.type == TransactionType.income ||
            t.type == TransactionType.sellInvestment)
        ? Colors.teal
        : (t.type == TransactionType.expense ||
              t.type == TransactionType.buyInvestment)
        ? Colors.redAccent
        : Colors.blue;

    if (t.isSettlement && t.type == TransactionType.transfer) {
      if (t.fromAccountId != null) {
        color = Colors.redAccent;
      } else if (t.toAccountId != null) {
        color = Colors.teal;
      }
    }

    Widget iconWidget;

    if (t.isSettlement) {
      iconWidget = Container(
        width: compact ? 32 : 48,
        height: compact ? 32 : 48,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.handshake, color: color, size: compact ? 18 : 24),
      );
    } else if (isSplit && hasMultipleCategories) {
      iconWidget = Container(
        width: compact ? 32 : 48,
        height: compact ? 32 : 48,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.call_split, color: color, size: compact ? 18 : 24),
      );
    } else if (category != null) {
      iconWidget = buildIconWidget(category!.iconData, Color(category!.color), size: compact ? 32 : 48);
    } else {
      IconData icon = (t.type == TransactionType.income || t.type == TransactionType.sellInvestment)
          ? Icons.arrow_downward
          : (t.type == TransactionType.expense ||
                t.type == TransactionType.buyInvestment)
          ? Icons.arrow_upward
          : Icons.compare_arrows;

      
      iconWidget = Container(
        width: compact ? 32 : 48,
        height: compact ? 32 : 48,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: compact ? 18 : 24),
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 4 : 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Row(
            children: [
              // Icon Circle
              iconWidget,
              const Gap(16),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (t.title?.isNotEmpty == true)
                          ? t.title!
                          : (category?.name ??
                                (t.subTransactions?.isNotEmpty == true
                                    ? 'Split Transaction'
                                    : (t.type == TransactionType.buyInvestment
                                          ? 'Buy Investment'
                                          : t.type ==
                                                TransactionType.sellInvestment
                                          ? 'Sell Investment'
                                          : (t.type.name[0].toUpperCase() +
                                                t.type.name.substring(1))))),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 15 : 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const Gap(4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSplit)
                            Consumer(
                              builder: (context, ref, _) {
                                final categoriesAsync = ref.watch(
                                  categoriesStreamProvider,
                                );
                                final expenses =
                                    ref
                                        .watch(expensesStreamProvider)
                                        .value
                                        ?.where((e) => e.transactionId == t.id)
                                        .toList() ??
                                    [];
                                return categoriesAsync.when(
                                  data: (allCats) {
                                    final splitCatIds = expenses
                                        .map((s) => s.categoryId)
                                        .whereType<int>()
                                        .toSet();
                                    if (splitCatIds.isEmpty)
                                      return const SizedBox.shrink();
                                    final names = splitCatIds
                                        .map(
                                          (id) => allCats
                                              .where((c) => c.id == id)
                                              .firstOrNull
                                              ?.name,
                                        )
                                        .whereType<String>()
                                        .join(', ');
                                    return Text(
                                      names,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                            )
                          else if (t.title?.isNotEmpty == true &&
                              category != null)
                            Text(
                              category!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),

                          // Note removed from list view as per request
                          if (t.subTransactions != null &&
                              t.subTransactions!.isNotEmpty) ...[
                            const Gap(2),
                            ...t.subTransactions!
                                .take(2)
                                .map(
                                  (s) => Text(
                                    '• $currency${formatAmount(s.amount)} ${s.note?.isNotEmpty == true ? "(${s.note})" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                            if (t.subTransactions!.length > 2)
                              Text(
                                '+ ${t.subTransactions!.length - 2} more',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],

                          const Gap(4),
                          Row(
                            children: [
                              Text(
                                t.hasTime
                                    ? DateFormat(
                                        'MMM d, y • h:mm a',
                                      ).format(t.date)
                                    : DateFormat('MMM d, y').format(t.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                  Builder(
                    builder: (context) {
                      String prefix =
                          (t.type == TransactionType.income ||
                              t.type == TransactionType.sellInvestment)
                          ? "+"
                          : ((t.type == TransactionType.expense ||
                                    t.type == TransactionType.buyInvestment)
                                ? "-"
                                : "");
                      if (t.isSettlement &&
                          t.type == TransactionType.transfer) {
                        if (t.fromAccountId != null)
                          prefix = "-";
                        else if (t.toAccountId != null)
                          prefix = "+";
                      }
                      return Text(
                        '$prefix$currency${formatAmount(t.amount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900, // Extra Bold
                          fontSize: compact ? 15 : 18, // Larger
                        ),
                      );
                    },
                  ),
                  if (!compact) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        accountName,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
