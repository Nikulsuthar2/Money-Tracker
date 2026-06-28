import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/analytics/application/analytics_transactions_provider.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:collection/collection.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_card.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/core/widgets/custom_refresh_indicator.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _trendView = 'Daily';
  bool _isTotalView =
      true; // true = Total (Cash Flow), false = Net (Accounting)

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Total Balance
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider);
    // Recent Transactions
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    // For Chart: Watch based on view toggle
    final rawTransactionsAsync = ref.watch(transactionsStreamProvider);
    final netTransactionsAsync = ref.watch(analyticsTransactionsProvider);
    final allTransactionsAsync = _isTotalView
        ? rawTransactionsAsync
        : netTransactionsAsync;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsWithBalanceProvider);
          ref.invalidate(transactionsStreamProvider);
          ref.invalidate(recentTransactionsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            bottom:
                MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                80,
          ),
          children: [
            // Stats Section
            accountsWithBalance.when(
              data: (stats) {
                double totalBalance = 0;
                for (var s in stats) {
                  totalBalance += s.totalContributionToNetWorth;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wallet,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 52,
                        ),
                      ),
                      const Gap(16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const Gap(4),
                          Consumer(
                            builder: (c, ref, _) => Text(
                              '${ref.watch(currencyProvider)}${totalBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const Gap(16),
            allTransactionsAsync.when(
              data: (txs) {
                final now = DateTime.now();
                double monthIncome = 0;
                double monthExpense = 0;
                for (var t in txs) {
                  if (!_isTotalView && t.skipFromStats) continue;
                  if (t.date.year == now.year && t.date.month == now.month) {
                    if (t.type == TransactionType.income ||
                        t.type == TransactionType.sellInvestment) {
                      monthIncome += t.amount;
                    } else if (t.type == TransactionType.expense ||
                        t.type == TransactionType.buyInvestment) {
                      monthExpense += t.amount;
                    }
                  }
                }
                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Colors.teal,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Consumer(
                                builder: (c, ref, _) => Text(
                                  '${ref.watch(currencyProvider)}${monthIncome.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Text(
                                    'Expense',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Consumer(
                                builder: (c, ref, _) => Text(
                                  '${ref.watch(currencyProvider)}${monthExpense.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const Gap(24),

            // Accounts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Accounts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/add-account'),
                      icon: const Icon(Icons.add_card),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Add Account',
                    ),
                    IconButton(
                      onPressed: () => context.push('/accounts'),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'View All',
                    ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            accountsWithBalance.when(
              data: (accounts) {
                if (accounts.isEmpty) return const Text('No accounts yet.');
                final displayAccounts = accounts.take(3).toList();
                return Column(
                  children: displayAccounts
                      .map((item) => AccountCard(item: item))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading accounts: $e\n$s'),
            ),
            const Gap(24),

            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const Gap(8),
            recentTransactionsAsync.when(
              data: (txs) {
                if (txs.isEmpty) return const Text('No recent transactions');

                return accountsWithBalance.when(
                  data: (accountsStats) {
                    final accountMap = {
                      for (var s in accountsStats) s.account.id: s.account.name,
                    };

                    return Column(
                      children:
                          (txs..sort((a, b) {
                                final dateComp = b.date.compareTo(a.date);
                                if (dateComp != 0) return dateComp;
                                return b.id.compareTo(a.id);
                              }))
                              .map((t) {
                                final accountId =
                                    t.type == TransactionType.income
                                    ? t.toAccountId
                                    : t.fromAccountId;
                                final accountName = accountId != null
                                    ? accountMap[accountId] ?? 'Unknown'
                                    : 'Unknown';

                                final category = t.categoryId != null
                                    ? categoriesAsync.value?.firstWhereOrNull(
                                        (c) => c.id == t.categoryId,
                                      )
                                    : null;

                                return TransactionTile(
                                  transaction: t,
                                  accountName: accountName,
                                  category: category,
                                  onTap: () => context.push(
                                    '/transaction-details',
                                    extra: t,
                                  ),
                                );
                              })
                              .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Error loading transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.total,
    required this.net,
    required this.color,
    required this.icon,
    this.max,
  });

  final String title;
  final double total;
  final double net; // Real
  final Color color;
  final IconData icon;
  final double? max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            'Total',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Consumer(
            builder: (c, ref, _) => Text(
              '${ref.watch(currencyProvider)}${total.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
            ),
          ),
          const Gap(4),
          Text(
            'Net (Real)',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Consumer(
            builder: (c, ref, _) => Text(
              '${ref.watch(currencyProvider)}${net.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
