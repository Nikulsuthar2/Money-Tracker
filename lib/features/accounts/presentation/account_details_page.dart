import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:gap/gap.dart';

import 'package:money_manager/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_chart.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _transactionFilterIndex = 0; // 0: All, 1: Income, 2: Expense
  
  // Date State
  String _period = 'Month'; // Month, Year, All
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
       if (!_tabController.indexIsChanging) {
         setState(() {
            switch(_tabController.index) {
               case 0: _period = 'Month'; break;
               case 1: _period = 'Year'; break;
               case 2: _period = 'All'; break;
            }
         });
       }
    });
  }
  
  void _prevPeriod() {
    setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
     setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    
    // Label for Calendar
    String dateLabel = '';
    if (_period == 'Month') dateLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_period == 'Year') dateLabel = DateFormat('yyyy').format(_selectedDate);

    return Scaffold(
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
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          // 1. Filter by Account
          final accountTransactions = allTransactions.where((t) => 
            t.fromAccountId == account.id || t.toAccountId == account.id
          ).toList();

          accountTransactions.sort((a, b) {
             final dateCmp = b.date.compareTo(a.date);
             if (dateCmp != 0) return dateCmp;
             return b.id.compareTo(a.id);
          });
          
          // 2. Filter by Time (Using _period and _selectedDate)
          List<Transaction> timeFilteredTransactions = accountTransactions;
          if (_period == 'Month') {
             timeFilteredTransactions = accountTransactions.where((t) => t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();
          } else if (_period == 'Year') {
             timeFilteredTransactions = accountTransactions.where((t) => t.date.year == _selectedDate.year).toList();
          }
          // 'All' -> No filter

          return Column(
            children: [
               // Fixed Header Section
               Container(
                 color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor, // Match AppBar
                 child: Column(
                   children: [
                       TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Month'),
                            Tab(text: 'Year'),
                            Tab(text: 'All'),
                          ],
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                          indicatorColor: theme.colorScheme.primary,
                       ),
                       
                       // Calendar Swiper (Visible if Month/Year)
                         if (_period != 'All')
                         Container(
                           margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                           padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                           decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(50),
                           ),
                           child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left)),
                                Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(onPressed: _nextPeriod, icon: const Icon(Icons.chevron_right)),
                              ],
                           ),
                         ),
                   ],
                 ),
               ),

               // Scrollable Content
               Expanded(
                 child: ListView(
                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                   children: [
                      // Main Stats Card
                      Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text('Current Balance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
                              const Gap(4),
                              Text('$currency${_calculateBalance(account, accountTransactions).toStringAsFixed(2)}', 
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w900
                                )
                              ),
                              const Gap(24),
                              // Line 2: Total In vs Out (Cash Flow)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                                ),
                                child: 
                              Row(
                                children: [
                                   Expanded(child: _StatColumn(label: 'Total In', amount: _calculateTotalIncome(account, timeFilteredTransactions), color: Colors.teal.shade800, currency: currency)),
                                   Container(width: 1, height: 40, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2)),
                                   Expanded(child: _StatColumn(label: 'Total Out', amount: _calculateTotalExpense(account, timeFilteredTransactions), color: Colors.red.shade800, currency: currency)),
                                ], 
                              ),),
                              const Gap(16),
                              // Line 3: Net Income | Net Spend (Real/Category)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  // border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                                ),
                                child: Row(
                                children: [
                                   Expanded(child: _StatColumn(label: 'Net Income', amount: _calculateAdjustedIncome(account, timeFilteredTransactions), color: Colors.teal, isBold: true, currency: currency)),
                                   Container(width: 1, height: 40, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                   Expanded(child: _StatColumn(label: 'Net Spend', amount: _calculateNetCost(account, timeFilteredTransactions), color: Colors.red, isBold: true, currency: currency)),
                                ],
                                ),
                              ),
                              const Gap(16),
                              
                              // Line 4: Reimbursed
                              if (_calculateReimbursements(account, timeFilteredTransactions) > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.undo, size: 12, color: theme.colorScheme.onSurface),
                                    const Gap(8),
                                    Text('Reimbursed: $currency${_calculateReimbursements(account, timeFilteredTransactions).toStringAsFixed(2)}',
                                       style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)), 
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
        
                      const Gap(16),
        
                      // Funds Status Card (Spendable vs Reserved)
                      Card(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                         child: Padding(
                            padding: const EdgeInsets.all(16),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Row(
                                    children: [
                                       Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                                       const Gap(12),
                                       const Text('Funds Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const Gap(16),
                                  // Spendable & Reserved
                                  Builder(
                                    builder: (context) {
                                      final balance = _calculateBalance(account, accountTransactions);
                                      final spendable = balance - (account.reservedBalance.isNaN ? 0.0 : account.reservedBalance) - account.buckets.fold(0.0, (sum, b) => sum + (b.balance.isNaN ? 0.0 : b.balance));
                                      return Row(
                                         children: [
                                            Expanded(
                                               child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                     const Text('Spendable', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                                     Text(
                                                        '$currency${(account.reservedBalance.isNaN ? 0.0 : account.reservedBalance).toStringAsFixed(2)}',
                                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                                                     ),
                                                  ],
                                               ),
                                            ),
                                         ],
                                      );
                                    }
                                  ),
        
                                  
                                  // Custom Buckets (and Add Button)
                                  if (account.buckets.isNotEmpty) ...[
                                      const Gap(16),
                                      Divider(color: theme.colorScheme.outlineVariant),
                                      const Gap(8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                           const Text('Custom Buckets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                           InkWell(
                                              onTap: () => _showAddBucketDialog(context, account),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text('+ Add Bucket', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                                           ),
                                        ],
                                      ),
                                      const Gap(8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                           ...account.buckets.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final b = entry.value;
                                              return _BucketItem(
                                                label: b.name ?? 'Bucket', 
                                                amount: b.balance, 
                                                color: Colors.blueAccent,
                                                icon: Icons.pie_chart,
                                                onTap: () => _showBucketManagementDialog(context, account, index, _calculateBalance(account, accountTransactions)),
                                             );
                                           }),
                                        ],
                                      ),
                                  ] else ...[
                                      const Gap(16),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () => _showAddBucketDialog(context, account),
                                          icon: const Icon(Icons.add_circle_outline, size: 16),
                                          label: const Text('Create Savings Bucket'),
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        )
                                      )
                                  ],
                               ],
                            )
                         )
                      ),
                       
                       if (account.autoSaveEnabled) ...[

                         const Gap(12),
                         Card(
                           elevation: 0,
                           color: Colors.amber.withOpacity(0.1),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                             side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                           ),
                           child: ListTile(
                             leading: const Icon(Icons.savings, color: Colors.amber),
                             title: const Text('Auto-Save Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             subtitle: Text('Automatically saving ${account.autoSaveIsPercentage ? "${account.autoSaveAmount.toStringAsFixed(0)}%" : "$currency${account.autoSaveAmount.toStringAsFixed(0)}"} of every income deposit.', style: const TextStyle(fontSize: 12)),
                           ),
                         ),
                       ],
        
                       const Gap(16),
        
                       // Chart
                      Container( 
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.surface,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: theme.colorScheme.outlineVariant),
                         ),
                         child: AccountChart(
                           transactions: timeFilteredTransactions, 
                           accountId: account.id, 
                           currency: currency,
                           period: _period,
                           focusedDate: _selectedDate,
                         ),
                      ),
                      const Gap(16),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           const Gap(12),
                           SizedBox(
                             width: double.infinity,
                             child: SegmentedButton<int>(
                                segments: const [
                                   ButtonSegment(value: 0, label: Text('All')),
                                   ButtonSegment(value: 1, label: Text('Income')),
                                   ButtonSegment(value: 2, label: Text('Expense')),
                                ],
                                selected: {_transactionFilterIndex},
                                onSelectionChanged: (Set<int> newSelection) {
                                   setState(() {
                                      _transactionFilterIndex = newSelection.first;
                                   });
                                },
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                             ),
                           ),
                        ],
                      ),
                      const Gap(16),
                      
                      // Transactions List (Date Grouped)
                      Builder(
                        builder: (context) {
                           List<Transaction> filtered = timeFilteredTransactions;
                           if (_transactionFilterIndex == 1) {
                              filtered = filtered.where((t) => t.type == TransactionType.income).toList();
                           } else if (_transactionFilterIndex == 2) {
                              filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
                           }
                           
                           if (filtered.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No transactions found')));
        
                           // Group by Date
                           final grouped = <DateTime, List<Transaction>>{};
                           for (var t in filtered) {
                              final date = DateTime(t.date.year, t.date.month, t.date.day);
                              if (!grouped.containsKey(date)) grouped[date] = [];
                              grouped[date]!.add(t);
                           }
                           final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        
                           return Column(
                             children: sortedDates.map((date) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     // Date Header
                                     Padding(
                                       padding: const EdgeInsets.symmetric(vertical: 8),
                                       child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            DateFormat.yMMMd().format(date),
                                            style: TextStyle(
                                               color: theme.colorScheme.onSurfaceVariant,
                                               fontWeight: FontWeight.bold,
                                               fontSize: 12
                                            ),
                                          ),
                                       ),
                                     ),
                                     ...grouped[date]!.map((t) => TransactionTile(
                                        transaction: t, 
                                        accountName: account.name,
                                        compact: false, // User requested full view
                                        onTap: () => context.push('/transaction-details', extra: t),
                                     )),
                                     const Gap(8),
                                  ],
                                );
                             }).toList(),
                           );
                        }
                      ),
                      
                      const Gap(80), // Bottom padding for scrolling clearance
                   ],
                 ),
               ),
            ],
          );
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  double _calculateBalance(Account account, List<dynamic> transactions) {
     double balance = account.openingBalance;
     for (final t in transactions) {
       if (t.skipFromStats) continue;

       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         balance += t.amount;
       } else if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
         balance -= t.amount;
       } else if (t.type == TransactionType.transfer) {
         if (t.fromAccountId == account.id) balance -= t.amount;
         if (t.toAccountId == account.id) balance += t.amount;
       }
     }
     return balance;
  }

  bool _isReimbursement(dynamic t) {
     if (t.relatedTransactionId != null) return true;
     // Backward compatibility
     if (t.note != null && (t.note!.toLowerCase().contains('repayment') || t.note!.toLowerCase().contains('refund'))) return true;
     return false;
  }

  double _calculateAdjustedIncome(Account account, List<dynamic> transactions) {
     double income = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         if (!_isReimbursement(t)) {
            income += t.amount;
         }
       }
     }
     return income;
  }

  double _calculateNetCost(Account account, List<dynamic> transactions) {
     double expense = 0;
     double reimbursed = 0;
     
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       
       if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
         expense += t.amount;
       }
       
       // Check for repayments to deduct from expense
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         if (_isReimbursement(t)) {
            reimbursed += t.amount;
         }
       }
     }
     return expense - reimbursed;
  }

  double _calculateReimbursements(Account account, List<dynamic> transactions) {
     double reimbursed = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         if (_isReimbursement(t)) {
            reimbursed += t.amount;
         }
       }
     }
     return reimbursed;
  }
   double _calculateTotalIncome(Account account, List<dynamic> transactions) {
     double income = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.income && t.toAccountId == account.id) {
         income += t.amount;
       } else if (t.type == TransactionType.transfer && t.toAccountId == account.id) {
         income += t.amount;
       }
     }
     return income;
   }

   double _calculateTotalExpense(Account account, List<dynamic> transactions) {
     double expense = 0;
     for (final t in transactions) {
       if (t.skipFromStats) continue;
       if (t.type == TransactionType.expense && t.fromAccountId == account.id) {
         expense += t.amount;
       } else if (t.type == TransactionType.transfer && t.fromAccountId == account.id) {
         expense += t.amount;
       }
     }
     return expense;
   }

   Future<void> _showAddBucketDialog(BuildContext context, Account account) async {
      final controller = TextEditingController();
      await showDialog(
         context: context,
         builder: (c) => AlertDialog(
            title: const Text('New Savings Bucket'),
            content: TextField(
               controller: controller,
               decoration: const InputDecoration(labelText: 'Bucket Name', hintText: 'e.g. Car, Holiday', border: OutlineInputBorder()),
               textCapitalization: TextCapitalization.words,
            ),
            actions: [
               TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
               FilledButton(onPressed: () async {
                  if (controller.text.isNotEmpty) {
                     account.buckets = [...account.buckets, AccountBucket()..name = controller.text..balance = 0];
                     await ref.read(accountsRepositoryProvider).updateAccount(account);
                     if (context.mounted) Navigator.pop(c);
                     setState(() {});
                  }
               }, child: const Text('Create')),
            ],
         )
      );
   }

   Future<void> _showBucketManagementDialog(BuildContext context, Account account, int index, double currentTotalBalance) async {
       final bucket = account.buckets[index];
       final controller = TextEditingController();
       
       // Calculate Spendable (Total Balance - Reserved - Other Buckets - This Bucket)
       // Wait, Spendable = Total Balance - Reserved - SUM(All Buckets)
       // If we want to ADD to this bucket, we take from Spendable.
       // If we want to WITHDRAW from this bucket, we add to Spendable.
       
       final totalBuckets = account.buckets.fold(0.0, (sum, b) => sum + b.balance);
       final spendable = currentTotalBalance - account.reservedBalance - totalBuckets; 
       
       bool isDeposit = true;

       await showDialog(
          context: context,
          builder: (context) {
             return StatefulBuilder(
                builder: (context, setStateSB) {
                   return AlertDialog(
                      title: Text(bucket.name ?? 'Bucket'),
                      content: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                             Text('Balance: ${ref.read(currencyProvider)}${bucket.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                             const Gap(16),
                             Row(
                                children: [
                                   Expanded(child: FilterChip(label: const Text('Add Funds'), selected: isDeposit, onSelected: (v) => setStateSB(() => isDeposit = true))),
                                   const Gap(8),
                                   Expanded(child: FilterChip(label: const Text('Withdraw'), selected: !isDeposit, onSelected: (v) => setStateSB(() => isDeposit = false))),
                                ],
                             ),
                             const Gap(16),
                             TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                   labelText: 'Amount',
                                   prefixText: '${ref.read(currencyProvider)} ',
                                   border: const OutlineInputBorder(),
                                   helperText: isDeposit 
                                      ? 'Available to Add: ${ref.read(currencyProvider)}${(spendable < 0 ? 0 : spendable).toStringAsFixed(2)}'
                                      : 'Available to Withdraw: ${ref.read(currencyProvider)}${bucket.balance.toStringAsFixed(2)}'
                                ),
                             ),
                         ],
                      ),
                      actions: [
                         TextButton(
                            onPressed: () {
                               // Delete confirmation
                               showDialog(context: context, builder: (d) => AlertDialog(
                                  title: const Text('Delete Bucket?'),
                                  content: Text('Funds (${ref.read(currencyProvider)}${bucket.balance.toStringAsFixed(2)}) will return to Spendable.'),
                                  actions: [
                                     TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                                     TextButton(onPressed: () async {
                                        // Return funds to spendable implicitly by deleting bucket (Spendable is calculated as Bal - Buckets)
                                        // So just remove bucket.
                                        final newBuckets = List<AccountBucket>.from(account.buckets);
                                        newBuckets.removeAt(index);
                                        account.buckets = newBuckets;
                                        await ref.read(accountsRepositoryProvider).updateAccount(account);
                                        if (context.mounted) {
                                           Navigator.pop(d); // Close confirm
                                           Navigator.pop(context); // Close main dialog
                                        }
                                        setState(() {});
                                     }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                               ));
                            }, 
                            child: const Text('Delete Bucket', style: TextStyle(color: Colors.red))
                         ),
                         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                         FilledButton(onPressed: () async {
                            final amount = double.tryParse(controller.text) ?? 0.0;
                            if (amount <= 0) return;

                            if (isDeposit) {
                               if (amount > spendable) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient Spendable funds')));
                                  return;
                               }
                               bucket.balance += amount;
                            } else {
                               if (amount > bucket.balance) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient Bucket funds')));
                                  return;
                               }
                               bucket.balance -= amount;
                            }
                            
                            // Save
                            // Isar embedded objects are updated when parent is put.
                            // We need to trigger update.
                            // However, we modified 'bucket' which is a reference from 'account.buckets'.
                            // So 'account' is updated locally.
                            await ref.read(accountsRepositoryProvider).updateAccount(account);
                            if (context.mounted) Navigator.pop(context);
                            setState(() {});
                         }, child: const Text('Save')),
                      ],
                   );
                }
             );
          }
       );
   }
}



class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final String currency;

  const _StatColumn({
    required this.label, 
    required this.amount, 
    required this.color, 
    required this.currency,
    this.isBold = false
  });

  @override
  Widget build(BuildContext context) {
    // Adjust color for dark mode if it's too dark
    Color finalColor = color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
       // If it's a deep shade, lighten it
       if (color == Colors.teal.shade800) finalColor = Colors.tealAccent.shade400;
       if (color == Colors.red.shade800) finalColor = Colors.redAccent.shade100;
       if (color == Colors.teal) finalColor = Colors.tealAccent;
       if (color == Colors.red) finalColor = Colors.redAccent;
    }

    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const Gap(2),
        Text(
          '$currency${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 14, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: finalColor
          ),
        ),
      ],
    );
  }
}

class _BucketItem extends StatelessWidget {
  const _BucketItem({
    required this.label, 
    required this.amount, 
    required this.color, 
    required this.icon,
    this.onTap,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           decoration: BoxDecoration(
             color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
           ),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
               const Gap(8),
               Text('$label: ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
               Consumer(builder: (context, ref, _) {
                  return Text(
                     '${ref.watch(currencyProvider)}${amount.toStringAsFixed(0)}',
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.primary)
                  );
               }),
             ],
           ),
        ),
      ),
    );
  }
}
