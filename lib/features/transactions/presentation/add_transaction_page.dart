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

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.extra});

  final Object? extra; // Can be Transaction (edit) or Map (new with defaults)

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int? _selectedAccountId; // From Account
  int? _selectedToAccountId; // To Account (for transfer)
  int? _selectedCategoryId; // For Income/Expense

  // New Fields
  bool _skipFromStats = false;
  bool _hasTime = true;

  // Split Transaction State
  bool _isSplit = false;
  List<SubTransactionInput> _splits = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
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
      _noteController.text = t.note ?? '';
      _date = t.date;
      _type = t.type;
      _selectedCategoryId = t.categoryId; 
      _skipFromStats = t.skipFromStats;
      _hasTime = t.hasTime;

      // Load splits
      if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
        _isSplit = true;
        _splits = t.subTransactions!.map((s) => SubTransactionInput(
          amountController: TextEditingController(text: s.amount.toString()),
          noteController: TextEditingController(text: s.note ?? ''),
          categoryId: s.categoryId,
          isMine: s.isMine,
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
         _tabController.animateTo(1);
       }
       // Default time: set current time but ensure _hasTime is true by default
       _date = DateTime.now();
    }

    _tabController.addListener(() {
       // Sync tab index with Transaction Type
       if (_tabController.indexIsChanging) {
         setState(() {
           if (_tabController.index == 0) _type = TransactionType.income;
           if (_tabController.index == 1) _type = TransactionType.expense;
           if (_tabController.index == 2) _type = TransactionType.transfer;
           // Reset split if switching to transfer
           if (_type == TransactionType.transfer) {
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
    _noteController.dispose();
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
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
        return;
      }
      if (_type == TransactionType.transfer && _selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select destination account')));
        return;
      }
      
      // Category Validation
      if (!_isSplit && (_type == TransactionType.income || _type == TransactionType.expense) && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }

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

      final transaction = (widget.extra is Transaction) ? (widget.extra as Transaction) : Transaction();
      transaction
        ..amount = amount
        ..type = _type
        ..date = _hasTime ? _date : DateTime(_date.year, _date.month, _date.day) // Strip time if no time
        ..note = _noteController.text
        ..categoryId = _isSplit ? null : _selectedCategoryId
        ..skipFromStats = _skipFromStats
        ..hasTime = _hasTime;
     
      // Assign Splits
      if (_isSplit) {
        transaction.subTransactions = _splits.map((s) => SubTransaction()
          ..amount = double.parse(s.amountController.text)
          ..note = s.noteController.text
          ..categoryId = s.categoryId
          ..isMine = s.isMine
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
      }

      if (mounted) {
        context.pop();
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

    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extra is Transaction ? 'Edit Transaction' : 'Add Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
             // Amount
            TextFormField(
              controller: _amountController,
              decoration: inputDecoration.copyWith(
                labelText: 'Amount',
                prefixText: '${ref.watch(currencyProvider)} ',
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
                    height: 56,
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
            
            // Account Selection (From)
            StreamBuilder<List<Account>>(
              stream: ref.read(accountsRepositoryProvider).watchActiveAccounts(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const LinearProgressIndicator();
                 final accounts = snapshot.data!;
                 return DropdownButtonFormField<int>(
                   value: _selectedAccountId,
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
                     value: _selectedToAccountId,
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

            // Category Selection (Normal Mode)
            if (_type != TransactionType.transfer && !_isSplit) 
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

                     return DropdownButtonFormField<int>(
                       value: effectiveCategoryId,
                        decoration: inputDecoration.copyWith(
                         labelText: 'Category',
                       ),
                       items: categories.map((c) => DropdownMenuItem(
                         value: c.id,
                         child: Row(
                           children: [
                             Icon(IconData(c.icon, fontFamily: 'MaterialIcons')), 
                             const Gap(8),
                             Text(c.name),
                           ],
                         ),
                       )).toList(),
                       onChanged: (v) => setState(() => _selectedCategoryId = v),
                     );
                },
                loading: () => const LinearProgressIndicator(), 
                error: (_,__) => const Text('Error loading categories'),
              ),
            
             if (_type != TransactionType.transfer) ...[
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
                                      child: DropdownButtonFormField<int>(
                                        value: _splits[i].categoryId,
                                        decoration: const InputDecoration(labelText: 'Category', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                                        items: categories.map((c) => DropdownMenuItem(
                                           value: c.id,
                                           child: Text(c.name),
                                        )).toList(),
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
                                        decoration: InputDecoration(labelText: 'Amount', prefixText: '${ref.watch(currencyProvider)}', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
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
                               Row(
                                 children: [
                                   Checkbox(
                                     value: _splits[i].isMine, 
                                     onChanged: (v) => setState(() => _splits[i].isMine = v ?? true),
                                   ),
                                   Text(_type == TransactionType.income ? 'My Income' : 'My Expense'),
                                 ],
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
                activeColor: Colors.orange,
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
        ),
      ),
    );
  }
}

class SubTransactionInput {
  final TextEditingController amountController;
  final TextEditingController noteController;
  int? categoryId;
  bool isMine;

  SubTransactionInput({
    TextEditingController? amountController,
    TextEditingController? noteController,
    this.categoryId,
    this.isMine = true,
  }) : 
    this.amountController = amountController ?? TextEditingController(),
    this.noteController = noteController ?? TextEditingController();

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}
