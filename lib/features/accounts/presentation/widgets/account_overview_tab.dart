import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/goals/application/goals_providers.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/presentation/widgets/contribute_sheet.dart';
import 'package:money_manager/features/goals/presentation/widgets/goal_icon_widget.dart';
import 'package:gap/gap.dart';

class AccountOverviewTab extends ConsumerWidget {
  final Account account;
  final List<Transaction> transactions;

  const AccountOverviewTab({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final statsList = ref.watch(accountsWithBalanceProvider).valueOrNull;
    final stats = statsList?.firstWhere((s) => s.account.id == account.id, orElse: () => AccountStats(account, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    
    final currentBalance = account.isCash ? (stats?.balance ?? 0) : (stats?.totalContributionToNetWorth.abs() ?? 0);
    
    // Calculate for current month only
    final now = DateTime.now();
    double totalIn = 0;
    double totalOut = 0;
    double netIn = 0;
    double netSpend = 0;

    for (final t in transactions) {
      if (t.date.year != now.year || t.date.month != now.month) continue;
      if (t.skipFromStats) continue;

      final bool isSettlement = t.isSettlement || t.mode == TransactionMode.settlement;
      final double effectiveAmt = t.effectiveAmount;

      if (t.type == TransactionType.income && t.toAccountId == account.id) {
        totalIn += t.amount;
        if (!isSettlement) netIn += effectiveAmt;
      } else if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
        totalOut += t.amount;
        if (!isSettlement) netSpend += effectiveAmt;
      } else if (t.type == TransactionType.transfer) {
        if (t.toAccountId == account.id) {
          totalIn += t.amount;
        }
        if (t.fromAccountId == account.id) {
          totalOut += t.amount;
        }
      }
    }

    final interestRate = account.interestRate ?? 0.0;
    final expectedInterest = interestRate > 0 ? (currentBalance * (interestRate / 100.0)) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Balance Card
        Card(
          color: theme.colorScheme.primaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(account.isCash ? 'Current Balance' : 'Current Value', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
                const Gap(8),
                Text('$currency${currentBalance.toStringAsFixed(2)}', 
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900
                  )
                ),
              ],
            ),
          ),
        ),
        const Gap(16),
        
        // This Month Stats
        const Text('This Month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _StatColumn(label: 'Total In', amount: totalIn, color: Colors.teal, currency: currency)),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  Expanded(child: _StatColumn(label: 'Total Out', amount: totalOut, color: Colors.red, currency: currency)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                children: [
                  Expanded(child: _StatColumn(label: 'Net Income', amount: netIn, color: Colors.teal, currency: currency, isBold: true)),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  Expanded(child: _StatColumn(label: 'Net Spend', amount: netSpend, color: Colors.red, currency: currency, isBold: true)),
                ],
              ),
            ],
          ),
        ),
        const Gap(24),
        
        // Fund Allocation (if cash account)
        if (account.isCash) ...[
          const Text('Fund Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(12),
          Consumer(
            builder: (ctx, ref, _) {
              final allGoals = ref.watch(goalsStreamProvider).valueOrNull ?? [];
              final allContributions = ref.watch(allGoalContributionsProvider).valueOrNull ?? [];
              final myContributions = allContributions.where((c) => c.accountId == account.id);
              
              double totalGoalContributions = 0;
              final goalTotals = <int, double>{};
              for (var c in myContributions) {
                totalGoalContributions += c.amount;
                goalTotals[c.goalId] = (goalTotals[c.goalId] ?? 0) + c.amount;
              }
              
              final spendable = currentBalance - (account.reservedBalance.isNaN ? 0.0 : account.reservedBalance) - totalGoalContributions;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Spendable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const Gap(4),
                                Text(
                                  '$currency${(spendable < 0 ? 0.0 : spendable).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Reserved', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const Gap(4),
                                Text(
                                  '$currency${(account.reservedBalance.isNaN ? 0.0 : account.reservedBalance).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (goalTotals.isNotEmpty) ...[
                        const Gap(16),
                        const Divider(),
                        const Gap(8),
                        const Text('Goals & Targets', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const Gap(12),
                        ...goalTotals.entries.where((e) => e.value > 0).map((entry) {
                          final goal = allGoals.firstWhere((g) => g.id == entry.key, orElse: () => Goal()..name = 'Unknown Goal');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                GoalIconWidget(iconData: goal.iconData, color: Color(goal.color), iconSize: 20),
                                const Gap(12),
                                Expanded(child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Text('$currency${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Gap(8),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  color: theme.colorScheme.primary,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (ctx) => ContributeSheet(goal: goal, preselectedAccountId: account.id),
                                    );
                                  },
                                )
                              ],
                            )
                          );
                        }).toList()
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const Gap(24),
        ],

        // Expected Interest (At the bottom)
        if (interestRate > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.trending_up, color: Colors.green),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expected Interest', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Based on $interestRate% annual rate', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                    ],
                  ),
                ),
                Text('+$currency${expectedInterest.toStringAsFixed(2)}/yr',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
          const Gap(24),
        ],
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  final bool isBold;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
