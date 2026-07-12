import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/application/timeline_provider.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:gap/gap.dart';

import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_overview_tab.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_analytics_tab.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_history_tab.dart';

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final timelineAsync = ref.watch(timelineProvider);
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(account.name),
          actions: [
            IconButton(
              tooltip: 'Add Transaction',
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id}), 
            ),
            IconButton(
              tooltip: 'Transfer',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => context.push('/add-transaction', extra: {'accountId': account.id, 'type': TransactionType.transfer}),
            ),
             if (account.isCash)
               IconButton(
                 tooltip: 'Manage Reserved',
                 icon: const Icon(Icons.lock_outline),
                 onPressed: () {
                     final controller = TextEditingController(text: account.reservedBalance.toString());
                     showDialog(context: context, builder: (d) => AlertDialog(
                        title: const Text('Manage Reserved Savings'),
                        content: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                              const Text('Adjust amount reserved safely from spending.'),
                              const Gap(16),
                              TextField(
                                 controller: controller,
                                 decoration: InputDecoration(
                                   labelText: 'Reserved Amount',
                                   prefixText: currency,
                                   border: const OutlineInputBorder(),
                                 ),
                                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                           ],
                        ),
                        actions: [
                           TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                           FilledButton(onPressed: () async {
                              final val = double.tryParse(controller.text) ?? 0.0;
                              final updated = account..reservedBalance = val;
                              await ref.read(accountsRepositoryProvider).updateAccount(updated);
                              if (context.mounted) Navigator.pop(d);
                           }, child: const Text('Save')),
                        ]
                     ));
                 },
               ),
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
                }
              },
              itemBuilder: (context) => [
                 const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), Gap(12), Text('Edit Account')])),
                 const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), Gap(12), Text('Delete Account', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Analytics'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: timelineAsync.when(
          data: (entries) {
            final allTransactions = <Transaction>[];
            for (var entry in entries) {
               if (entry is TransactionTimelineEntry) {
                  final tx = entry.transaction;
                  final subs = <SubTransaction>[];
                  for (var exp in entry.expenses) {
                     final splits = entry.splits[exp.id] ?? [];
                     if (splits.isEmpty) {
                        subs.add(SubTransaction()..amount = exp.totalAmount..categoryId = exp.categoryId..isMine = true);
                     } else {
                        for (var s in splits) {
                           subs.add(SubTransaction()..amount = s.amount..categoryId = exp.categoryId..isMine = s.personId == 0);
                        }
                     }
                  }
                  if (subs.isNotEmpty) tx.subTransactions = subs;
                  allTransactions.add(tx);
               }
            }

            final accountTransactions = allTransactions.where((t) => 
              t.fromAccountId == account.id || t.toAccountId == account.id
            ).toList();
  
            accountTransactions.sort((a, b) {
               final dateCmp = b.date.compareTo(a.date);
               if (dateCmp != 0) return dateCmp;
               return b.id.compareTo(a.id);
            });
            
            return TabBarView(
              children: [
                AccountOverviewTab(account: account, transactions: accountTransactions),
                AccountAnalyticsTab(account: account, transactions: accountTransactions),
                AccountHistoryTab(account: account, transactions: accountTransactions),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
