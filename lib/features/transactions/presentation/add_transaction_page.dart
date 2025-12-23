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

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.transactionToEdit});

  final Transaction? transactionToEdit;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  int? _selectedAccountId; // From Account
  int? _selectedToAccountId; // To Account (for transfer)
  int? _selectedCategoryId; // For Income/Expense

  // Split Transaction State
  bool _isSplit = false;
  List<SubTransactionInput> _splits = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _date = t.date;
      _type = t.type;
      _selectedCategoryId = t.categoryId; 
      
      // Load splits
      if (t.subTransactions != null && t.subTransactions!.isNotEmpty) {
        _isSplit = true;
        _splits = t.subTransactions!.map((s) => SubTransactionInput(
          amountController: TextEditingController(text: s.amount.toString()),
          noteController: TextEditingController(text: s.note ?? ''),
          categoryId: s.categoryId,
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
       // Set default expense
       _tabController.animateTo(1);
    }

    _tabController.addListener(() {
       // Sync tab index with Transaction Type
       if (_tabController.indexIsChanging) {
         setState(() {
           if (_tabController.index == 0) _type = TransactionType.income;
           if (_tabController.index == 1) _type = TransactionType.expense;
           if (_tabController.index == 2) _type = TransactionType.transfer;
           // Reset split if switching to transfer (usually splits are for expense/income)
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

      final transaction = widget.transactionToEdit ?? Transaction();
      transaction
        ..amount = amount
        ..type = _type
        ..date = _date
        ..note = _noteController.text
        ..categoryId = _isSplit ? null : _selectedCategoryId; // Main category is null if split? Or maybe use first split? Let's keep null.
     
      // Assign Splits
      if (_isSplit) {
        transaction.subTransactions = _splits.map((s) => SubTransaction()
          ..amount = double.parse(s.amountController.text)
          ..note = s.noteController.text
          ..categoryId = s.categoryId
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

      if (widget.transactionToEdit != null) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit == null ? 'Add Transaction' : 'Edit Transaction'),
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
            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context, 
                  initialDate: _date, 
                  firstDate: DateTime(2000), 
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const Divider(),
            
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
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
            
            // Account Selection (From)
            StreamBuilder<List<Account>>(
              stream: ref.read(accountsRepositoryProvider).watchActiveAccounts(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const LinearProgressIndicator();
                 final accounts = snapshot.data!;
                 return DropdownButtonFormField<int>(
                   value: _selectedAccountId,
                   decoration: InputDecoration(
                     labelText: _type == TransactionType.income ? 'Deposit To' : 'Pay From',
                     border: const OutlineInputBorder(),
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
                     decoration: const InputDecoration(
                       labelText: 'Transfer To',
                       border: OutlineInputBorder(),
                     ),
                     items: accounts.where((a) => a.id != _selectedAccountId).map((a) => DropdownMenuItem(
                       value: a.id,
                       child: Text(a.name),
                   )).toList(),
                     onChanged: (v) => setState(() => _selectedToAccountId = v),
                   );
                },
              ),
            
            // Note
             const Gap(16),
             TextFormField(
               controller: _noteController,
               decoration: const InputDecoration(
                 labelText: 'Note',
                 border: OutlineInputBorder(),
               ),
               maxLines: 1,
             ),

            const Gap(16),

             // SPLIT TOGGLE
             if (_type != TransactionType.transfer) ...[
                SwitchListTile(
                  title: const Text('Split Transaction?'),
                  value: _isSplit, 
                  onChanged: (v) => setState(() {
                    _isSplit = v;
                    if (_isSplit && _splits.isEmpty) {
                      _addSplit();
                    }
                  })
                ),
                const Gap(8),
             ],
            
            // Category Selection (Normal Mode)
            if (_type != TransactionType.transfer && !_isSplit) 
              categoriesAsync.when(
                data: (categories) {
                   return DropdownButtonFormField<int>(
                     value: _selectedCategoryId,
                      decoration: const InputDecoration(
                       labelText: 'Category',
                       border: OutlineInputBorder(),
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
                                        decoration: const InputDecoration(labelText: 'Category', isDense: true),
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
                               Row(
                                 children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _splits[i].amountController,
                                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _splits[i].noteController,
                                        decoration: const InputDecoration(labelText: 'Note'),
                                      ),
                                    ),
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

             const Gap(24),
             ElevatedButton(
               onPressed: _save,
               style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 textStyle: const TextStyle(fontSize: 18),
                 backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                 foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
               ),
               child: const Text('Save Transaction'),
             ),
             const Gap(40), // Bottom padding
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

  SubTransactionInput({
    TextEditingController? amountController,
    TextEditingController? noteController,
    this.categoryId,
  }) : 
    this.amountController = amountController ?? TextEditingController(),
    this.noteController = noteController ?? TextEditingController();

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}
