import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/core/providers/savings_provider.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.extra});

  final Object? extra; // Can be Transaction (edit) or Map (new with defaults)

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(); // New
  final _noteController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int? _selectedAccountId; // From Account
  int? _selectedToAccountId; // To Account (for transfer)
  int? _selectedCategoryId; // For Income/Expense

  // New Fields
  bool _skipFromStats = false;
  bool _hasTime = false;
  int? _relatedTransactionId;
  int? _subscriptionId;

  // Split Transaction State
  bool _isSplit = false;
  List<SubTransactionInput> _splits = [];
  
  bool _isRefundMode = false;

  // Income Bucket State
  String _incomeDestinationBucket = 'spendable'; // spendable, savings, investment
  bool _autoFillReserved = true; // For Income
  final _saveAmountController = TextEditingController(); // Reuse for bucket amount? No, bucket logic is simpler now.
  // Actually user requirement: "when income came first we fill reserved if its below setted limit, then if we have selected adding in custom category while adding income it will goes to custom and rest in spendable"
  // So for Income:
  // 1. Auto-fil Reserved (calculated in background or shown to user?) -> User said "first fill reserved".
  // 2. Select Custom (Savings/Investment) -> Optional.
  // 3. Rest -> Spendable.
  
  // UI for Income: 
  // - "Target Custom Bucket" (None, Savings, Investment)
  // - "Custom Amount" (if selected)
  String? _targetCustomBucket; // null, 'savings', 'investment'
  final _customBucketAmountController = TextEditingController();

  late TabController _tabController;
  
  // Settlement State
  int? _settlementPartyId;
  bool _settlementIPaid = true; // true = I Paid (Expense), false = They Paid (Income)
  
  // Experimental Inline Settlement
  bool _inlineSettlementMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Income, Expense, Transfer, Settlement
    
    Transaction? transactionToEdit;
    Map<String, dynamic>? defaults;

    if (widget.extra is Transaction) {
      transactionToEdit = widget.extra as Transaction;
    } else if (widget.extra is Map) {
      defaults = widget.extra as Map<String, dynamic>;
    }

    if (transactionToEdit != null) {
      final t = transactionToEdit;
      _amountController.text = t.amount.toString();
      _titleController.text = t.title ?? '';
      _noteController.text = t.note ?? '';
      _date = t.date;
      _type = t.type;
      _selectedCategoryId = t.categoryId; 
      _skipFromStats = t.skipFromStats;
      _skipFromStats = t.skipFromStats;
      _hasTime = t.hasTime;
      _subscriptionId = t.subscriptionId;

      // Load splits
      if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
        _isSplit = true;
        _splits = t.subTransactions!.map((s) => SubTransactionInput(
          amountController: TextEditingController(text: s.amount.toString()),
          noteController: TextEditingController(text: s.note ?? ''),
          categoryId: s.categoryId,
          isMine: s.isMine,
          partyId: s.partyId,
        )).toList();
      }

      // Map accounts based on type
      if (_type == TransactionType.income) {
        _selectedAccountId = t.toAccountId;
        _tabController.index = 0;
      } else if (_type == TransactionType.expense) {
        _selectedAccountId = t.fromAccountId;
        _tabController.index = 1;
      } else {
        _selectedAccountId = t.fromAccountId;
        _selectedToAccountId = t.toAccountId;
        _tabController.index = 2;
      }
    } else {
       // Defaults from Dashboard or Other
       if (defaults != null) {
         if (defaults['amount'] != null) _amountController.text = defaults['amount'].toString();
         if (defaults['note'] != null) _noteController.text = defaults['note'];
         if (defaults['categoryId'] != null) _selectedCategoryId = defaults['categoryId'] as int?;

         if (defaults['type'] == TransactionType.income) {
           _type = TransactionType.income;
           _tabController.index = 0;
           _selectedAccountId = defaults['accountId'];
         } else if (defaults['type'] == TransactionType.transfer) {
           _type = TransactionType.transfer;
           _tabController.index = 2;
           _selectedAccountId = defaults['accountId']; // From Account
         } else {
           // Expense
           _type = TransactionType.expense;
           _tabController.index = 1;
           _selectedAccountId = defaults['accountId'];
         }
       } else {
         // Default generic
       }
       // Default time: set current time but ensure _hasTime is true by default
       _date = DateTime.now();

       if (defaults != null && defaults.containsKey('relatedTransactionId')) {
          _relatedTransactionId = defaults['relatedTransactionId'];
       }
        if (defaults != null && defaults.containsKey('subscriptionId')) {
           _subscriptionId = defaults['subscriptionId'];
        }
    }
    
    // Lock logic if refund mode (Legacy support or just removing?)
    // User plan said remove refund mode. I will ignore _isRefundMode flags or convert them to standard income.
    
    _tabController.addListener(() {
       // Sync tab index with Transaction Type
       if (_tabController.indexIsChanging) {
         setState(() {
           if (_tabController.index == 0) _type = TransactionType.income;
           if (_tabController.index == 1) _type = TransactionType.expense;
           if (_tabController.index == 2) _type = TransactionType.transfer;
           if (_tabController.index == 3) {
              // Settlement Mode
              // Defaults to Expense (Me paying someone) or Income (They paying me)?
              // We'll decide type based on user input in the Settlement UI.
              // For now default to Expense (I pay).
              _type = TransactionType.expense; 
           }
           
           // Reset split if switching to transfer or settlement
           if (_type == TransactionType.transfer || _tabController.index == 3) {
              _isSplit = false;
              _splits.clear();
           }
         });
       }
    });

    ref.read(categoriesRepositoryProvider).seedDefaultCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _customBucketAmountController.dispose();
    _tabController.dispose();
    for (var s in _splits) {
      s.dispose();
    }
    super.dispose();
  }

  void _addSplit() {
    setState(() {
      _splits.add(SubTransactionInput());
    });
  }

  void _removeSplit(int index) {
    setState(() {
      _splits[index].dispose();
      _splits.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_selectedAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
          return;
        }
        if (_type == TransactionType.transfer && _selectedToAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select destination account')));
          return;
        }
        
        // Category Validation - Removed to allow "None"
        // if (!_isSplit && (_type == TransactionType.income || _type == TransactionType.expense) && _selectedCategoryId == null) {
        //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        //   return;
        // }

        final amount = double.tryParse(_amountController.text) ?? 0.0;

        // Split Validation
        if (_isSplit) {
          if (_splits.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one split item')));
             return;
          }
          double splitTotal = 0.0;
          for (var s in _splits) {
            if (s.categoryId == null) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All split items must have a category')));
               return;
            }
             splitTotal += double.tryParse(s.amountController.text) ?? 0.0;
          }
          if ((splitTotal - amount).abs() > 0.01) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Split total ($splitTotal) does not match Amount ($amount)')));
             return;
          }
        }

        double expenseDeductedFromSavings = 0.0;
        double expenseDeductedFromReserved = 0.0;

        // Check Balance vs Savings (Warning Logic & Deduction)
        if ((_type == TransactionType.expense || _type == TransactionType.transfer) && _selectedAccountId != null) {
            final repo = ref.read(transactionsRepositoryProvider);
            final accountRepo = ref.read(accountsRepositoryProvider);
            
            final accounts = await accountRepo.getAllAccounts(); 
            final account = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
            
            if (account != null) {
                double currentBalance = await repo.getAccountBalance(account.id, account.openingBalance);
                
                // If Editing: Add back the original amount to currentBalance (conceptually reverting the old tx)
                // to check if the NEW amount fits.
                if (widget.extra is Transaction) {
                    final t = widget.extra as Transaction;
                    // If we are still in the same account
                    if ((t.type == TransactionType.expense || t.type == TransactionType.transfer) && t.fromAccountId == account.id) {
                        currentBalance += t.amount; 
                    }
                }

                // Expense Priority Logic: Spendable -> Custom (Savings/Investment) -> Reserved
                // We need to know the breakdown.
                // Spendable = Current - Reserved - Savings - Investment
                
                final totalCustom = account.buckets.fold(0.0, (sum, b) => sum + b.balance);
                final spendable = currentBalance - account.reservedBalance - totalCustom;
                final reserved = account.reservedBalance;

                String warningMsg = '';
                double remainingAmount = amount;

                // 1. Deduct from Spendable
                if (remainingAmount <= spendable) {
                   // All good
                } else {
                   remainingAmount -= spendable; // Spendable depleted
                   
                   // 2. Deduct from Custom Buckets
                   if (remainingAmount <= totalCustom) {
                      warningMsg = 'This transaction exceeds Spendable balance.\nIt will deduct ${ref.read(currencyProvider)}${remainingAmount.toStringAsFixed(2)} from your Custom Buckets.';
                   }
                   // 3. Deduct from Reserved
                   else {
                      remainingAmount -= totalCustom; // Custom depleted
                      if (remainingAmount <= reserved) {
                         warningMsg = 'This transaction depletes Spendable AND Custom buckets.\nIt will deduct ${ref.read(currencyProvider)}${remainingAmount.toStringAsFixed(2)} from your RESERVED funds.';
                      } else {
                         warningMsg = 'This transaction exceeds ALL funds (Spendable + Custom + Reserved). Balance will go negative.';
                      }
                   }
                }

                if (warningMsg.isNotEmpty) {
                    bool proceed = false;
                    if (mounted) {
                        await showDialog(
                          context: context, 
                          builder: (c) => AlertDialog(
                            title: const Text('Fund Usage Warning'),
                            content: Text('$warningMsg\n\nProceed?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                              FilledButton(onPressed: () { proceed = true; Navigator.pop(c); }, child: const Text('Proceed')),
                            ],
                          )
                        );
                    }
                    if (!proceed) return;
                }
            }
        }

        final transaction = (widget.extra is Transaction) ? (widget.extra as Transaction) : Transaction();
        transaction
          ..amount = amount
          ..type = _type
          ..mode = (_tabController.index == 3 || _inlineSettlementMode) ? TransactionMode.settlement : TransactionMode.regular
          ..date = _hasTime ? _date : DateTime(_date.year, _date.month, _date.day) // Strip time if no time
          ..title = _titleController.text 
          ..note = _noteController.text
          ..categoryId = _isSplit || _tabController.index == 3 || _inlineSettlementMode ? null : _selectedCategoryId // Settlement/Split have no main category? Or Settlement defaults?
          ..skipFromStats = _skipFromStats
          ..hasTime = _hasTime
          ..relatedTransactionId = _relatedTransactionId
          ..subscriptionId = _subscriptionId;
       
        // Assign Splits or Settlement Party
        if (_tabController.index == 3 || _inlineSettlementMode) {
           // Settlement Mode
           if (_settlementPartyId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a party to settle with')));
              return;
           }
           // Create a single subtransaction to carry the Party ID
           transaction.subTransactions = [
              SubTransaction()
                ..amount = amount
                ..partyId = _settlementPartyId
                ..isMine = _type == TransactionType.expense // If Expense (I paid), isMine=true?
                ..note = 'Settlement'
           ];
           // Settlement usually has no category, or a system "Debt" category?
           // We'll leave categoryId null for now.
        }
        else if (_isSplit) {
          transaction.subTransactions = _splits.map((s) => SubTransaction()
            ..amount = double.parse(s.amountController.text)
            ..note = s.noteController.text
            ..categoryId = s.categoryId
            ..isMine = s.isMine
            ..partyId = s.partyId
          ).toList();
        } else {
          transaction.subTransactions = [];
        }

        if (_type == TransactionType.income) {
          transaction.toAccountId = _selectedAccountId;
          transaction.fromAccountId = null;
        } else if (_type == TransactionType.expense) {
          transaction.fromAccountId = _selectedAccountId;
          transaction.toAccountId = null;
        } else {
          // Transfer
          transaction.fromAccountId = _selectedAccountId;
          transaction.toAccountId = _selectedToAccountId;
        }

        if (widget.extra is Transaction) {
           await ref.read(transactionsRepositoryProvider).updateTransaction(transaction);
        } else {
           await ref.read(transactionsRepositoryProvider).addTransaction(transaction);
           
           // Logic to update Account Balance (Savings/Reserved)
           final accountRepo = ref.read(accountsRepositoryProvider);
           if (_selectedAccountId != null) {
               final accounts = await accountRepo.getAllAccounts();
               final account = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
               if (account != null) {
                  bool updated = false;
                  
                  // Income Logic (Bucket Fill)
                  if (_type == TransactionType.income) {
                      double remainingIncome = amount;
                      
                      // 1. Fill Reserved (up to limit)
                      if (account.reservedBalance < account.reservedLimit) {
                         final needed = account.reservedLimit - account.reservedBalance;
                         final toAdd = needed < remainingIncome ? needed : remainingIncome;
                         account.reservedBalance += toAdd;
                         remainingIncome -= toAdd;
                         updated = true;
                      }

                      // 2. Custom Bucket (if selected)
                      if (remainingIncome > 0 && _targetCustomBucket != null) {
                         final customAmount = double.tryParse(_customBucketAmountController.text) ?? 0.0;
                         final toAdd = customAmount < remainingIncome ? customAmount : remainingIncome;
                         
                         // Find bucket by name
                         final bucketIndex = account.buckets.indexWhere((b) => b.name == _targetCustomBucket);
                         if (bucketIndex != -1) {
                             account.buckets[bucketIndex].balance += toAdd;
                             updated = true;
                         }
                      }
                  }
                  
                  // Expense Logic (Bucket Deduction)
                  else if (_type == TransactionType.expense || _type == TransactionType.transfer) {
                      final currentBal = await ref.read(transactionsRepositoryProvider).getAccountBalance(account.id, account.openingBalance); 
                      
                      // Because we already added the transaction above within this same try-block, 
                      // getAccountBalance MIGHT include it if the watcher fired or if Isar is immediate.
                      // Actually AddTransaction is async. 
                      // Let's rely on the previous calculation logic used for warning? 
                      // No, that was BEFORE adding.
                      // Let's reuse the logic: We know we just spent 'amount'. Use that to deduct from buckets in memory and save.
                      
                      // RE-CALCULATE Pre-Txn Balance logic to match Warning Logic EXACTLY
                      // We need the balance BEFORE this transaction to know what we depleted.
                      // But we just added it. 
                      // So (Current Balance Including New Txn) - Amount = Pre-Txn Balance.
                      
                      // Wait, getAccountBalance sums up ALL transactions. So it includes the one we just added.
                      final balanceAfterTxn = await ref.read(transactionsRepositoryProvider).getAccountBalance(account.id, account.openingBalance); 
                      final preTxnBalance = balanceAfterTxn + amount; // Revert locally

                      final totalCustom = account.buckets.fold(0.0, (sum, b) => sum + b.balance);
                      final preTxnSpendable = preTxnBalance - account.reservedBalance - totalCustom;
                      
                      double amountRemaining = amount;
                      
                      // 1. Deduct from Spendable
                      if (amountRemaining <= preTxnSpendable) {
                         amountRemaining = 0;
                      } else {
                         amountRemaining -= preTxnSpendable; // Spendable exhausted
                      }
                      
                      // 2. Deduct from Custom Buckets
                      if (amountRemaining > 0) {
                          for (var i = 0; i < account.buckets.length; i++) {
                              if (amountRemaining <= 0) break;
                              if (account.buckets[i].balance > 0) {
                                  final deduct = amountRemaining < account.buckets[i].balance ? amountRemaining : account.buckets[i].balance;
                                  account.buckets[i].balance -= deduct;
                                  amountRemaining -= deduct;
                                  updated = true;
                              }
                          }
                      }
                      
                      // 3. Deduct from Reserved
                      if (amountRemaining > 0) {
                          if (account.reservedBalance > 0) {
                             final deduct = amountRemaining < account.reservedBalance ? amountRemaining : account.reservedBalance;
                             account.reservedBalance -= deduct;
                             amountRemaining -= deduct;
                             updated = true;
                          }
                      }
                  }
                  
                  if (updated) {
                     await accountRepo.updateAccount(account);
                  }
               }
           }
        }

        if (mounted) {
          context.pop(true);
        }
      } catch (e, stack) {
        debugPrint('Error saving transaction: $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Copy', onPressed: () {
             // Copy logic if needed
          }),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Categories depend on type
    AsyncValue<List<Category>> categoriesAsync;
    if (_type == TransactionType.income) {
        categoriesAsync = ref.watch(incomeCategoriesProvider);
    } else {
        categoriesAsync = ref.watch(expenseCategoriesProvider);
    }
    
    // Load Parties for Splits
    final partiesAsync = ref.watch(partiesStreamProvider);

    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extra is Transaction ? 'Edit Transaction' : (_isRefundMode ? 'Refund Transaction' : 'Add Transaction')),
        bottom: _isRefundMode ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
            Tab(text: 'Transfer'),
            Tab(text: 'Settlement'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
             // Settlement Mode UI
             if (_tabController.index == 3) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Column(
                    children: [
                      const Text('Settlement Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Track debt payments directly. No splits.', style: TextStyle(color: Colors.grey)),
                      const Gap(16),
                      // Direction Toggle
                      Row(
                         children: [
                            Expanded(child: ChoiceChip(
                              label: const Text('I Paid (They Owe Less)'),
                              selected: _settlementIPaid,
                              onSelected: (v) => setState(() { _settlementIPaid = true; _type = TransactionType.expense; }),
                              avatar: const Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                            )),
                            const Gap(8),
                            Expanded(child: ChoiceChip(
                              label: const Text('They Paid (I Owe Less)'),
                              selected: !_settlementIPaid,
                              onSelected: (v) => setState(() { _settlementIPaid = false; _type = TransactionType.income; }),
                              avatar: const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                            )),
                         ],
                      ),
                      const Gap(16),
                      // Party Selector
                      partiesAsync.when(
                        data: (parties) => DropdownButtonFormField<int>(
                             value: _settlementPartyId,
                             decoration: inputDecoration.copyWith(labelText: 'Select Party', prefixIcon: const Icon(Icons.person)),
                             items: parties.where((p) => !p.isMe()).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                             onChanged: (v) => setState(() => _settlementPartyId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_,__) => const Text('Error loading parties'),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
             ],
                
             Padding(
               padding: const EdgeInsets.all(16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                    // Amount
                   TextFormField(
                     controller: _amountController,
                     readOnly: _isRefundMode,
                     decoration: inputDecoration.copyWith(
                       labelText: 'Amount',
                       prefixText: '${ref.watch(currencyProvider)} ',
                       // Visual cue that it's disabled/fixed
                       fillColor: _isRefundMode ? Theme.of(context).disabledColor.withOpacity(0.05) : null,
                       filled: _isRefundMode,
                     ),
                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                     validator: (v) {
                       if (v == null || v.isEmpty) return 'Required';
                       if (double.tryParse(v) == null) return 'Invalid';
                       return null;
                     },
                   ),
            const Gap(16),

           // Title Field
            TextFormField(
              controller: _titleController,
              decoration: inputDecoration.copyWith(
                labelText: 'Title',
                hintText: 'e.g. Salary, Groceries',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const Gap(16),

            // Inline Settlement Switch (Experimental)
            if (_tabController.index != 2 && _tabController.index != 3 && !_isRefundMode) ...[
               SwitchListTile(
                 title: const Text('Settlement Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: const Text('Link this to a person (Ledger) instead of a category'),
                 value: _inlineSettlementMode,
                 onChanged: (val) {
                    setState(() {
                       _inlineSettlementMode = val;
                       if (val) {
                          _isSplit = false;
                          _splits.clear();
                       }
                    });
                 },
                 secondary: const Icon(Icons.handshake),
                 dense: true,
                 contentPadding: EdgeInsets.zero,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               const Gap(16),
            ],

            // Date & Time Picker
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context, 
                        initialDate: _date, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() {
                          _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                        labelText: 'Date',
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        DateFormat.yMMMd().format(_date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _hasTime ? InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context, 
                        initialTime: TimeOfDay.fromDateTime(_date),
                      );
                      if (t != null) {
                        setState(() {
                          _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: inputDecoration.copyWith(
                        labelText: 'Time',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                          onPressed: () => setState(() => _hasTime = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      child: Text(
                        DateFormat.jm().format(_date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ) : SizedBox(
                    height: 47,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _hasTime = true),
                      icon: const Icon(Icons.access_time),
                      label: const Text('Add Time'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            
            const Gap(16),
            
            // Party Selector (Inline Settlement)
            if (_inlineSettlementMode && _tabController.index != 3)
                 partiesAsync.when(
                    data: (parties) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<int>(
                           value: _settlementPartyId,
                           decoration: inputDecoration.copyWith(labelText: 'Select Party', prefixIcon: const Icon(Icons.person)),
                           items: parties.where((p) => !p.isMe()).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                           onChanged: (v) => setState(() => _settlementPartyId = v),
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_,__) => const Text('Error loading parties'),
                 ),

            // Account Selection (From)
            StreamBuilder<List<Account>>(
              stream: ref.read(accountsRepositoryProvider).watchActiveAccounts(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const LinearProgressIndicator();
                 final accounts = snapshot.data!;
                 return DropdownButtonFormField<int>(
                   initialValue: _selectedAccountId,
                   decoration: inputDecoration.copyWith(
                     labelText: _type == TransactionType.income ? 'Deposit To' : 'Pay From',
                   ),
                   items: accounts.map((a) => DropdownMenuItem(
                     value: a.id,
                     child: Text(a.name),
                   )).toList(),
                   onChanged: (v) => setState(() => _selectedAccountId = v),
                 );
              },
            ),
            const Gap(16),
            
            // To Account (Transfer only)
             if (_type == TransactionType.transfer)
              StreamBuilder<List<Account>>(
                stream: ref.read(accountsRepositoryProvider).watchActiveAccounts(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData) return const SizedBox.shrink();
                   final accounts = snapshot.data!;
                   return DropdownButtonFormField<int>(
                     initialValue: _selectedToAccountId,
                     decoration: inputDecoration.copyWith(
                       labelText: 'Transfer To',
                     ),
                     items: accounts.where((a) => a.id != _selectedAccountId).map((a) => DropdownMenuItem(
                       value: a.id,
                       child: Text(a.name),
                   )).toList(),
                     onChanged: (v) => setState(() => _selectedToAccountId = v),
                   );
                },
              ),
            
            const Gap(16),

            // Category Selection (Normal Mode AND Not Inline Settlement)
            if (_type != TransactionType.transfer && !_isSplit && !_inlineSettlementMode) 
              categoriesAsync.when(
                data: (categories) {
                     // specific validation to prevent crash if pre-filled category (e.g. from Refund) doesn't exist in this type list
                     if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                        // We can't setState during build, but we can coerce the value for the dropdown
                        // Ideally we should use a post-frame callback or just pass null to value
                        // But local variable modification doesn't affect state. 
                        // Let's just pass null if not found.
                     }

                     final effectiveCategoryId = (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId)) 
                        ? _selectedCategoryId 
                        : null;

                     return DropdownButtonFormField<int?>(
                       initialValue: effectiveCategoryId,
                        decoration: inputDecoration.copyWith(
                         labelText: 'Category',
                       ),
                       items: [
                         const DropdownMenuItem(value: null, child: Text('None')),
                         ...categories.map((c) => DropdownMenuItem(
                           value: c.id,
                           child: Row(
                             children: [
                               Icon(IconData(c.icon, fontFamily: 'MaterialIcons')), 
                               const Gap(8),
                               Text(c.name),
                             ],
                           ),
                         ))
                       ].toList(),
                       onChanged: (v) => setState(() => _selectedCategoryId = v),
                     );
                },
                loading: () => const LinearProgressIndicator(), 
                error: (_,__) => const Text('Error loading categories'),
              ),
            
             if (_type == TransactionType.income) ...[
                 const Gap(8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: StreamBuilder<List<Account>>(
                      stream: ref.read(accountsRepositoryProvider).watchActiveAccounts(),
                      builder: (context, snapshot) {
                         final account = snapshot.data?.where((a) => a.id == _selectedAccountId).firstOrNull;
                         final buckets = account?.buckets ?? [];

                         return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bucket Allocation', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Gap(8),
                              const Text('Auto-fills Reserved (to limit) first.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const Gap(8),
                              DropdownButtonFormField<String>(
                                value: _targetCustomBucket,
                                decoration: inputDecoration.copyWith(labelText: 'Fill Custom Bucket (Optional)'),
                                items: [
                                   const DropdownMenuItem(value: null, child: Text('None (Rest to Spendable)')),
                                   ...buckets.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name ?? 'Unnamed'))),
                                ],
                                onChanged: (v) => setState(() => _targetCustomBucket = v),
                              ),
                              if (_targetCustomBucket != null) ...[
                                 const Gap(8),
                                 TextFormField(
                                   controller: _customBucketAmountController,
                                   decoration: inputDecoration.copyWith(labelText: 'Amount to Custom', prefixText: ref.watch(currencyProvider)),
                                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                 ),
                              ]
                            ],
                         );
                      }
                   ),
                 ),
                 const Gap(16),
             ],
             
             // Refund Toggle for Income
             if (_tabController.index == 0) ...[
                const Gap(8),
                SwitchListTile(
                   title: const Text('Mark as Refund'),
                   subtitle: const Text('Exclude from Net Income stats'),
                   value: _skipFromStats,
                   onChanged: (v) => setState(() => _skipFromStats = v),
                   secondary: const Icon(Icons.replay),
                   contentPadding: EdgeInsets.zero,
                ),
                const Gap(8),
             ],

             if (_type != TransactionType.transfer && _tabController.index != 3) ...[
                const Gap(8),
                Row(
                  children: [
                     const Text('Split Transaction?'),
                     const Spacer(),
                     Switch(
                        value: _isSplit,
                        onChanged: (v) => setState(() {
                          _isSplit = v;
                          if (_isSplit && _splits.isEmpty) {
                            _addSplit();
                          }
                        })
                     ),
                  ],
                ),
             ],

             // SPLIT LIST
            if (_isSplit) ...[
               const Text('Split Details', style: TextStyle(fontWeight: FontWeight.bold)),
               const Gap(8),
               categoriesAsync.when(
                 data: (categories) => Column(
                   children: [
                     for (int i = 0; i < _splits.length; i++) 
                       Card(
                         margin: const EdgeInsets.only(bottom: 8),
                         child: Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Column(
                             children: [
                               Row(
                                 children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        initialValue: _splits[i].categoryId,
                                        decoration: const InputDecoration(labelText: 'Category', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                                        items: [
                                           const DropdownMenuItem(value: null, child: Text('None')),
                                           ...categories.map((c) => DropdownMenuItem(
                                             value: c.id,
                                             child: Text(c.name),
                                           ))
                                        ].toList(),
                                        onChanged: (v) => setState(() => _splits[i].categoryId = v),
                                      ),
                                   ),
                                   IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeSplit(i))
                                 ],
                               ),
                               const Gap(8),
                               Row(
                                 children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _splits[i].amountController,
                                        decoration: InputDecoration(labelText: 'Amount', prefixText: ref.watch(currencyProvider), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    const Gap(8),
                                   Expanded(
                                      child: TextFormField(
                                        controller: _splits[i].noteController,
                                        decoration: const InputDecoration(labelText: 'Note', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                                      ),
                                    ),
                                 ],
                               ),
                               const Gap(8),
                               const Gap(8),
                               Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                 child: Row(
                                   children: [
                                      // Party Selector
                                      Expanded(
                                        child: partiesAsync.when(
                                           data: (parties) {
                                              return DropdownButtonFormField<int?>(
                                                value: _splits[i].partyId,
                                                decoration: const InputDecoration(labelText: 'Assign To', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                                                items: [
                                                   const DropdownMenuItem(value: null, child: Text('Me (My Expense)')),
                                                   ...parties.where((p) => p.type != PartyType.self).map((p) => DropdownMenuItem(
                                                      value: p.id,
                                                      child: Text(p.name),
                                                   )),
                                                ],
                                                onChanged: (v) => setState(() {
                                                   _splits[i].partyId = v;
                                                   _splits[i].isMine = (v == null);
                                                }),
                                              );
                                           },
                                           loading: () => const LinearProgressIndicator(), // Minimal loader
                                           error: (_,__) => const Text('Error loading parties'),
                                        ),
                                      ),
                                   ],
                                 ),
                               )
                             ],
                           ),
                         )
                       ),
                   ],
                 ),
                 loading: () => const CircularProgressIndicator(),
                 error: (_, __) => const SizedBox(),
               ),
               TextButton.icon(onPressed: _addSplit, icon: const Icon(Icons.add), label: const Text('Add Split Line')),
            ],

             const Gap(16),
             TextFormField(
               controller: _noteController,
               decoration: inputDecoration.copyWith(
                 labelText: 'Note',
               ),
               maxLines: 2,
             ),
             
             const Gap(16),
             SwitchListTile(
               value: _skipFromStats,
               onChanged: (v) => setState(() => _skipFromStats = v),
               title: const Text('Ignore in Calculation'),
               subtitle: const Text('Don\'t include in Analytics or Totals'),
               activeThumbColor: Colors.orange,
               tileColor: Colors.grey.withOpacity(0.1),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),

             const Gap(24),
             ElevatedButton(
               onPressed: _save,
               style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 textStyle: const TextStyle(fontSize: 18),
                 backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                 foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text('Save Transaction'),
             ),
             const Gap(40),
           ],
               ), // Column
             ), // Padding
          ], // ListView children
        ), // ListView
      ), // Form
    ); // Scaffold
  }
}

class SubTransactionInput {
  final TextEditingController amountController;
  final TextEditingController noteController;
  int? categoryId;
  bool isMine;
  int? partyId;

  SubTransactionInput({
    TextEditingController? amountController,
    TextEditingController? noteController,
    this.categoryId,
    this.isMine = true,
    this.partyId,
  }) : 
    amountController = amountController ?? TextEditingController(),
    noteController = noteController ?? TextEditingController();

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}
