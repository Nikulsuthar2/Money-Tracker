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
    _tabController = TabController(length: 3, vsync: this); // Overview, Holdings, Transactions
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
               const PopupMenuItem(value: 'set_pl', child: Row(children: [Icon(Icons.attach_money, size: 20), Gap(12), Text('Set P/L Amount')])),
               const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), Gap(12), Text('Delete Account', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Holdings'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
                // Overview Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Current Value
                    Builder(
                      builder: (context) {
                        final plAmount = item.pl;
                        final currentValue = item.investedBalance + plAmount;
                        final plPercentage = item.investedBalance > 0 ? (plAmount / item.investedBalance) * 100 : 0.0;
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
                            ],
                          ),
                        );
                      }
                    ),
                    const Gap(24),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Invested Value', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                                      const Gap(4),
                                      Text('$currency${item.investedBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                                const Gap(16),
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final plAmount = item.pl;
                                      final plPercentage = item.investedBalance > 0 ? (plAmount / item.investedBalance) * 100 : 0.0;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Overall P/L', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                                          const Gap(4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${plAmount >= 0 ? '+' : '-'}$currency${plAmount.abs().toStringAsFixed(2)} ', 
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: plAmount >= 0 ? Colors.green : Colors.red),
                                              ),
                                              Text(
                                                '(${plPercentage >= 0 ? '+' : ''}${plPercentage.toStringAsFixed(2)}%)',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: plAmount >= 0 ? Colors.green : Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5), height: 1),
                            const Gap(12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, size: 18, color: theme.colorScheme.primary),
                                    const Gap(8),
                                    Text('Fund Wallet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                                  ],
                                ),
                                Text('$currency${item.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(32),
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
                        _ActionButton(
                          icon: Icons.sync_alt,
                          label: 'Correct Fund',
                          onTap: () => _showFundCorrectionDialog(context, ref, account, item.balance),
                        ),
                      ],
                    ),
                  ],
                ),
                
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
                         return InkWell(
                            onTap: () => context.push('/transaction-details', extra: t),
                            child: TransactionTile(
                              transaction: t,
                              accountName: account.name,
                              compact: true,
                            ),
                          );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                )
              ],
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
      title: const Text('Update Overall P/L Amount'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: const InputDecoration(
          labelText: 'Profit/Loss Amount',
          hintText: 'e.g. 500.00 or -250.00',
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

Future<void> _showFundCorrectionDialog(BuildContext context, WidgetRef ref, Account account, double currentBalance) async {
  final controller = TextEditingController(text: currentBalance.toString());
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Correct Fund Balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the actual fund wallet balance. A "Brokerage / Fund Correction" transaction will be created to adjust the difference.'),
          const Gap(16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual Fund Balance',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final val = double.tryParse(controller.text);
            if (val != null && val != currentBalance) {
              final diff = val - currentBalance;
              final t = Transaction()
                ..date = DateTime.now()
                ..title = 'Brokerage / Fund Correction'
                ..note = 'Manual fund correction'
                ..amount = diff.abs();

              if (diff < 0) {
                 t.type = TransactionType.expense;
                 t.fromAccountId = account.id;
              } else {
                 t.type = TransactionType.income;
                 t.toAccountId = account.id;
              }
              
              await ref.read(transactionsRepositoryProvider).addTransaction(t);
              if (c.mounted) Navigator.pop(c);
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
