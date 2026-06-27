import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/application/goals_providers.dart';
import 'package:money_manager/features/goals/presentation/widgets/contribute_sheet.dart';
import 'package:money_manager/features/goals/presentation/widgets/goal_icon_widget.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/goals/data/goals_repository.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class GoalDetailsPage extends ConsumerWidget {
  final Goal goal;
  const GoalDetailsPage({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveGoalAsync = ref.watch(goalStreamProvider(goal.id));
    final liveGoal = liveGoalAsync.value ?? goal; // Fallback to passed goal

    final contributionsAsync = ref.watch(goalContributionsProvider(goal.id));
    final progress = liveGoal.targetAmount > 0
        ? (liveGoal.currentAmount / liveGoal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final accountsAsync = ref.watch(
      accountsWithBalanceProvider,
    ); // To get account names
    final currency = ref.watch(currencyProvider);
    final leftAmount = (liveGoal.targetAmount - liveGoal.currentAmount).clamp(
      0.0,
      double.infinity,
    );

    int? daysLeft;
    if (liveGoal.endDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(
        liveGoal.endDate!.year,
        liveGoal.endDate!.month,
        liveGoal.endDate!.day,
      );
      daysLeft = end.difference(today).inDays;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculate Amounts',
            onPressed: () async {
              try {
                await ref
                    .read(goalsRepositoryProvider)
                    .recalculateGoalAmounts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amounts recalculated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/add-goal', extra: liveGoal);
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Goal'),
                    content: const Text('Are you sure you want to delete this goal? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await ref.read(goalsRepositoryProvider).deleteGoal(liveGoal.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    Gap(12),
                    Text('Edit Goal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    Gap(12),
                    Text('Delete Goal', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => ContributeSheet(goal: liveGoal),
          );
        },
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text('Manage Funds'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GoalIconWidget(
                    iconData: liveGoal.iconData,
                    color: Color(liveGoal.color),
                    size: 96,
                    iconSize: 48,
                  ),
                  const Gap(16),
                  Text(
                    liveGoal.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    liveGoal.type.name.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(32),

                  // Progress
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saved',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$currency${liveGoal.currentAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Target',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$currency${liveGoal.targetAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Left',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$currency${leftAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: leftAmount == 0
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Gap(16),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          color: Color(liveGoal.color),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}% Achieved',
                              style: TextStyle(
                                color: Color(liveGoal.color),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (daysLeft != null)
                              Text(
                                daysLeft >= 0
                                    ? '$daysLeft days left'
                                    : '${-daysLeft} days overdue',
                                style: TextStyle(
                                  color: daysLeft >= 0
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  if (liveGoal.startDate != null || liveGoal.endDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (liveGoal.startDate != null)
                            Column(
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(
                                    liveGoal.startDate!,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (liveGoal.endDate != null)
                            Column(
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(liveGoal.endDate!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  const Gap(16),
                ],
              ),
            ),
          ),
          contributionsAsync.when(
            data: (contributions) {
              if (contributions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No contributions yet.'),
                    ),
                  ),
                );
              }

              // Get accounts map for quick lookup
              final accountsMap = accountsAsync.maybeWhen(
                data: (list) => {for (var s in list) s.account.id: s.account},
                orElse: () => <int, Account>{},
              );

              final accountTotals = <int, double>{};
              for (var c in contributions) {
                accountTotals[c.accountId] =
                    (accountTotals[c.accountId] ?? 0) + c.amount;
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (accountTotals.isNotEmpty) ...[
                      const Text(
                        'Contributions by Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: accountTotals.entries.map((e) {
                          final acc = accountsMap[e.key];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: acc != null
                                  ? Color(acc.color).withOpacity(0.1)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: acc != null
                                    ? Color(acc.color).withOpacity(0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (acc != null) ...[
                                  GoalIconWidget(
                                    iconData: acc.iconData,
                                    color: Color(acc.color),
                                    size: 36,
                                    iconSize: 20,
                                  ),
                                  const Gap(12),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc?.name ?? 'Acc ${e.key}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '$currency${e.value.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Gap(24),
                      const Text(
                        'Contributions History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(16),
                    ],

                    ...contributions.map((c) {
                      final acc = accountsMap[c.accountId];
                      final accName = acc?.name ?? 'Account ${c.accountId}';
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove Contribution?'),
                              content: const Text(
                                'This will remove the contribution and restore the amount to the account\'s spendable balance.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref
                              .read(goalsRepositoryProvider)
                              .deleteContribution(c);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: acc != null
                                ? GoalIconWidget(
                                    iconData: acc.iconData,
                                    color: Color(acc.color),
                                    size: 40,
                                    iconSize: 22,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                            title: Text(
                              c.amount >= 0
                                  ? '+$currency${c.amount.toStringAsFixed(2)}'
                                  : '-$currency${c.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: c.amount >= 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            subtitle: Text(DateFormat.yMMMd().format(c.date)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: acc != null
                                    ? Color(acc.color).withOpacity(0.1)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                accName,
                                style: TextStyle(
                                  color: acc != null
                                      ? Color(acc.color)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ]),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverGap(80),
        ],
      ),
    );
  }
}
