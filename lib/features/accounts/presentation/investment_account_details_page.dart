import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/accounts/presentation/widgets/holdings_card.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/presentation/widgets/trade_stock_sheet.dart';

class InvestmentAccountDetailsPage extends ConsumerStatefulWidget {
  const InvestmentAccountDetailsPage({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<InvestmentAccountDetailsPage> createState() => _InvestmentAccountDetailsPageState();
}

class _InvestmentAccountDetailsPageState extends ConsumerState<InvestmentAccountDetailsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Holdings, Transactions
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider).valueOrNull ?? [];
    final item = accountsWithBalance.firstWhere((a) => a.account.id == account.id, orElse: () => AccountStats(account, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));

    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                 context.push('/add-account', extra: account);
              } else if (value == 'delete') {
                 showDialog(context: context, builder: (d) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('This will delete the account and all associated transactions permanently.'),
                    actions: [
                       TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                       TextButton(onPressed: () async {
                          await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
                          if (context.mounted) {
                             Navigator.pop(d);
                             context.pop();
                          }
                       }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ]
                 ));
              } else if (value == 'set_pl') {
                 _showPLDialog(context, ref, account);
              }
            },
            itemBuilder: (context) => [
               const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), Gap(12), Text('Edit Account')])),
               const PopupMenuItem(value: 'set_pl', child: Row(children: [Icon(Icons.percent, size: 20), Gap(12), Text('Set P/L')])),
               const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), Gap(12), Text('Delete Account', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // Current Value
                    Builder(
                      builder: (context) {
                        final currentValue = item.investedBalance * (1 + (item.pl / 100));
                        final plAmount = currentValue - item.investedBalance;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withAlpha(200)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: theme.colorScheme.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                          ),
                          child: Column(
                            children: [
                              Text('Current Value', style: TextStyle(color: theme.colorScheme.onPrimary.withAlpha(200), fontSize: 14)),
                              const Gap(8),
                              Text('$currency${currentValue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: theme.colorScheme.onPrimary)),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item.pl >= 0 ? '+' : ''}$currency${plAmount.toStringAsFixed(2)} (${item.pl >= 0 ? '+' : ''}${item.pl.toStringAsFixed(2)}%)',
                                  style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('Fund Wallet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                            const Gap(4),
                            Text('$currency${item.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                        Column(
                          children: [
                            Text('Invested Value', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                            const Gap(4),
                            Text('$currency${item.investedBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ],
                        ),
                      ],
                    ),
                    const Gap(24),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.add,
                          label: 'Add Funds',
                          onTap: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.transfer}),
                        ),
                        _ActionButton(
                          icon: Icons.remove,
                          label: 'Withdraw',
                          onTap: () {
                             // Transfer out: from this account
                             // Wait, if it's from this account, `accountId` in add_transaction usually acts as the source for expense, 
                             // but for transfer, we need to make sure the UI sets it as From Account.
                             context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.transfer, 'isWithdrawal': true});
                          },
                        ),
                        _ActionButton(
                          icon: Icons.shopping_cart,
                          label: 'Trade Stock',
                          onTap: () {
                             showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               builder: (c) => Padding(
                                 padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
                                 child: TradeStockSheet(account: account, fundBalance: item.balance),
                               ),
                             );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 48,
                maxHeight: 48,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Holdings'),
                    Tab(text: 'Transactions'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
              controller: _tabController,
              children: [
                // Holdings Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                     HoldingsCard(account: account),
                  ],
                ),
                
                // Transactions Tab
                transactionsAsync.when(
                  data: (allTransactions) {
                    final accountTransactions = allTransactions.where((t) => t.fromAccountId == account.id || t.toAccountId == account.id).toList();
                    accountTransactions.sort((a, b) => b.date.compareTo(a.date));
                    
                    if (accountTransactions.isEmpty) {
                      return const Center(child: Text('No transactions yet.'));
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: accountTransactions.length,
                      itemBuilder: (context, index) {
                         final t = accountTransactions[index];
                         return TransactionTile(
                           transaction: t,
                           accountName: account.name,
                           compact: true,
                         );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                )
              ],
            ),
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const Gap(8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPLDialog(BuildContext context, WidgetRef ref, Account account) async {
  final controller = TextEditingController(text: (account.interestRate ?? 0).toString());
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Update Overall P/L (%)'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(
          labelText: 'Profit/Loss Percentage',
          hintText: 'e.g. 5.5 or -2.3',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final val = double.tryParse(controller.text);
            if (val != null) {
               account.interestRate = val;
               await ref.read(accountsRepositoryProvider).updateAccount(account);
            }
            if (c.mounted) Navigator.pop(c);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
