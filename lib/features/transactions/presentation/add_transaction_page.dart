import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/presentation/advanced_split_page.dart';
import 'package:money_manager/core/widgets/icon_utils.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/core/providers/savings_provider.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';
import 'package:money_manager/features/transactions/presentation/advanced_split_page.dart';
import 'package:money_manager/core/utils/math_evaluator.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.extra});

  final Object? extra; // Can be Transaction (edit) or Map (new with defaults)

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(); // New
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
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
  List<AdvancedExpenseItem>? _advancedSplits;

  bool _isRefundMode = false;

  // Income Bucket State
  String _incomeDestinationBucket =
      'spendable'; // spendable, savings, investment
  bool _autoFillReserved = true; // For Income
  final _saveAmountController =
      TextEditingController(); // Reuse for bucket amount? No, bucket logic is simpler now.
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
  bool _settlementIPaid =
      true; // true = I Paid (Expense), false = They Paid (Income)

  Widget _buildSelector({
    required String label,
    required Widget leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            leading,
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),
            ],
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker(
    List<AccountStats> accounts,
    bool isToAccount,
    String currency,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isToAccount ? 'Transfer To' : 'Select Account'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: accounts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No accounts available'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final a = accounts[index];
                    return ListTile(
                      leading: buildIconWidget(
                        a.account.iconData,
                        Color(a.account.color),
                        size: 40,
                      ),
                      title: Text(a.account.name),
                      trailing: Text(
                        '$currency${a.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isToAccount) {
                            _selectedToAccountId = a.account.id;
                          } else {
                            _selectedAccountId = a.account.id;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Category'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length + 1, // +1 for "None"
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Icon(Icons.do_not_disturb_alt),
                  ),
                  title: const Text('None'),
                  onTap: () {
                    setState(() => _selectedCategoryId = null);
                    Navigator.pop(ctx);
                  },
                );
              }
              final c = categories[index - 1];
              return ListTile(
                leading: buildIconWidget(c.iconData, Color(c.color), size: 40),
                title: Text(c.name),
                onTap: () {
                  setState(() => _selectedCategoryId = c.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPersonPicker(List<Person> people, bool isWhoPaid, int? splitIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isWhoPaid ? 'Who Paid?' : 'Split For'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: people.length + 2, // +1 for "Me", +1 for "+ Add Person"
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.account_balance_wallet),
                  ),
                  title: const Text('Me (My Account)'),
                  onTap: () {
                    Navigator.pop(ctx, 0); // Return 0 for Me
                  },
                );
              }
              if (index == people.length + 1) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: const Icon(Icons.person_add),
                  ),
                  title: const Text(
                    '+ Add Person',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddPersonDialog();
                  },
                );
              }
              final p = people[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(p.name),
                onTap: () {
                  Navigator.pop(ctx, p.id); // Return person ID
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPersonDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Person'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                // To avoid circular dependencies if we just import people repository here:
                // We'll just push to the repository via the provider
                final person = Person()..name = name;
                await ref.read(peopleRepositoryProvider).addPerson(person);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Income, Expense, Transfer, Settlement

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
      _hasTime = t.hasTime;

      _loadSplitsAsync(t.id);

      if (t.isSettlement) {
        _tabController.index = 3;
        _settlementIPaid = t.type == TransactionType.expense;
        _selectedAccountId = _settlementIPaid ? t.fromAccountId : t.toAccountId;
        _loadSettlementAsync(t.id);
      } else if (_type == TransactionType.income) {
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
        if (defaults['amount'] != null)
          _amountController.text = defaults['amount'].toString();
        if (defaults['note'] != null) _noteController.text = defaults['note'];
        if (defaults['categoryId'] != null)
          _selectedCategoryId = defaults['categoryId'] as int?;

        if (defaults['type'] == TransactionType.income) {
          _type = TransactionType.income;
          _tabController.index = 0;
          _selectedAccountId = defaults['accountId'];
        } else if (defaults['type'] == TransactionType.transfer) {
          _type = TransactionType.transfer;
          _tabController.index = 2;
        } else if (defaults['type'] == 'settlement') {
          _type =
              TransactionType.expense; // Settlement mode controls its own logic
          _tabController.index = 3;
          _selectedAccountId = defaults['accountId'];
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
          }
        });
      }
    });

    ref.read(categoriesRepositoryProvider).seedDefaultCategories();
  }

  Future<void> _loadSplitsAsync(int transactionId) async {
    final expRepo = ref.read(expensesRepositoryProvider);
    final expenses = await expRepo.getExpensesForTransaction(transactionId);
    if (expenses.isNotEmpty) {
      List<AdvancedExpenseItem> advancedSplits = [];
      for (var exp in expenses) {
        final splits = await expRepo.getSplitsForExpense(exp.id);
        advancedSplits.add(
          AdvancedExpenseItem(
            amount: exp.totalAmount,
            categoryId: exp.categoryId,
            note: exp.note ?? '',
            paidByPersonId: exp.paidByPersonId ?? 0,
            splits: splits
                .map(
                  (s) => ExpenseSplitInput(
                    personId: s.personId,
                    amountController: TextEditingController(
                      text: s.amount.toStringAsFixed(2),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isSplit = true;
          _advancedSplits = advancedSplits;
        });
      }
    }
  }

  Future<void> _loadSettlementAsync(int transactionId) async {
    final expRepo = ref.read(expensesRepositoryProvider);
    final settlements = await expRepo.getSettlementsForTransaction(transactionId);
    if (settlements.isNotEmpty) {
      final s = settlements.first;
      if (mounted) {
        setState(() {
          _settlementPartyId = _settlementIPaid ? s.toPersonId : s.fromPersonId;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _customBucketAmountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_selectedAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an account')),
          );
          return;
        }
        if (_type == TransactionType.transfer && _selectedToAccountId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select destination account')),
          );
          return;
        }

        final amount = double.tryParse(_amountController.text) ?? 0.0;

        // Split Validation
        if (_isSplit) {
          if (_advancedSplits == null || _advancedSplits!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please add split items or disable split transaction.',
                ),
              ),
            );
            return;
          }

          double myPaidTotal = 0;
          for (var item in _advancedSplits!) {
            if (item.paidByPersonId == 0) {
              myPaidTotal += item.amount;
            }

            double splitSum = 0;
            for (var s in item.splits)
              splitSum += double.tryParse(s.amountController.text) ?? 0;
            if ((splitSum - item.amount).abs() > 0.01) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Item amount (${item.amount}) does not match the sum of its splits ($splitSum)',
                  ),
                ),
              );
              return;
            }
          }

          if ((myPaidTotal - amount).abs() > 0.01) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The amount you paid in splits ($myPaidTotal) does not match Transaction Amount ($amount)',
                ),
              ),
            );
            return;
          }
        }

        double expenseDeductedFromSavings = 0.0;
        double expenseDeductedFromReserved = 0.0;

        // Check Balance vs Savings (Warning Logic & Deduction)
        if ((_type == TransactionType.expense ||
                _type == TransactionType.transfer) &&
            _selectedAccountId != null) {
          final repo = ref.read(transactionsRepositoryProvider);
          final accountRepo = ref.read(accountsRepositoryProvider);

          final accounts = await accountRepo.getAllAccounts();
          final account = accounts
              .where((a) => a.id == _selectedAccountId)
              .firstOrNull;

          if (account != null) {
            double currentBalance = await repo.getAccountBalance(
              account.id,
              account.openingBalance,
            );

            // If Editing: Add back the original amount to currentBalance (conceptually reverting the old tx)
            // to check if the NEW amount fits.
            if (widget.extra is Transaction) {
              final t = widget.extra as Transaction;
              // If we are still in the same account
              if ((t.type == TransactionType.expense ||
                      t.type == TransactionType.transfer) &&
                  t.fromAccountId == account.id) {
                currentBalance += t.amount;
              }
            }

            // Expense Priority Logic: Spendable -> Reserved
            final spendable = currentBalance - account.reservedBalance;
            final reserved = account.reservedBalance;

            String warningMsg = '';
            double remainingAmount = amount;

            if (remainingAmount > spendable) {
              remainingAmount -= spendable; // Spendable depleted
              if (remainingAmount <= reserved) {
                warningMsg =
                    'This transaction exceeds Spendable balance.\nIt will deduct ${ref.read(currencyProvider)}${remainingAmount.toStringAsFixed(2)} from your RESERVED funds.';
              } else {
                warningMsg =
                    'This transaction exceeds ALL funds (Spendable + Reserved). Balance will go negative.';
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
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          proceed = true;
                          Navigator.pop(c);
                        },
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                );
              }
              if (!proceed) return;
            }
          }
        }

        int? resolvedCategoryId = _selectedCategoryId;
        if (_isSplit &&
            _advancedSplits != null &&
            _advancedSplits!.isNotEmpty) {
          final firstCat = _advancedSplits!.first.categoryId;
          if (firstCat != null &&
              _advancedSplits!.every((e) => e.categoryId == firstCat)) {
            resolvedCategoryId = firstCat;
          } else if (_advancedSplits!.length == 1) {
            resolvedCategoryId = _advancedSplits!.first.categoryId;
          }
        }

        final transaction = (widget.extra is Transaction)
            ? (widget.extra as Transaction)
            : Transaction();
        transaction
          ..amount = amount
          ..type = _type
          ..mode = (_tabController.index == 3)
              ? TransactionMode.settlement
              : TransactionMode.regular
          ..date = _hasTime
              ? _date
              : DateTime(
                  _date.year,
                  _date.month,
                  _date.day,
                ) // Strip time if no time
          ..title = _titleController.text
          ..note = _noteController.text
          ..categoryId = _isSplit
              ? resolvedCategoryId
              : (_tabController.index == 3 ? null : _selectedCategoryId)
          ..skipFromStats = _skipFromStats
          ..hasTime = _hasTime
          ..relatedTransactionId = _relatedTransactionId;

        if (_type == TransactionType.expense) {
          transaction.fromAccountId = _selectedAccountId;
          transaction.toAccountId = null;
        } else if (_type == TransactionType.income) {
          transaction.toAccountId = _selectedAccountId;
          transaction.fromAccountId = null;
        } else {
          // Transfer
          transaction.fromAccountId = _selectedAccountId;
          transaction.toAccountId = _selectedToAccountId;
        }

        final txRepo = ref.read(transactionsRepositoryProvider);
        final expRepo = ref.read(expensesRepositoryProvider);
        int? txId;

        bool isUpdate = widget.extra is Transaction;

        if (isUpdate) {
          await txRepo.updateTransaction(transaction);
          txId = transaction.id;
        }

        if (_tabController.index == 3) {
          // Settlement Mode
          if (_settlementPartyId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a party to settle with'),
              ),
            );
            return;
          }
          transaction.isSettlement = true;
          transaction.type = _settlementIPaid ? TransactionType.expense : TransactionType.income;
          if (_settlementIPaid) {
            transaction.fromAccountId = _selectedAccountId;
            transaction.toAccountId = null;
          } else {
            transaction.toAccountId = _selectedAccountId;
            transaction.fromAccountId = null;
          }

          if (isUpdate) {
            await txRepo.updateTransaction(transaction);
          } else {
            txId = await txRepo.addTransaction(transaction);
            final s = Settlement()
              ..transactionId = txId
              ..fromPersonId = _settlementIPaid ? 0 : _settlementPartyId!
              ..toPersonId = _settlementIPaid ? _settlementPartyId! : 0
              ..amount = amount;
            await expRepo.addSettlement(s);
          }
        } else if (_isSplit) {
          if (_advancedSplits != null && _advancedSplits!.isNotEmpty) {
            double myTotalPaid = 0.0;
            for (var item in _advancedSplits!) {
              if (item.paidByPersonId == 0) myTotalPaid += item.amount;
            }

            if (myTotalPaid > 0) {
              transaction.amount = myTotalPaid;
              if (isUpdate) {
                await txRepo.updateTransaction(transaction);
              } else {
                txId = await txRepo.addTransaction(transaction);
              }
            }

            if (isUpdate && txId != null) {
              final existingExpenses = await expRepo.getExpensesForTransaction(
                txId,
              );
              for (var e in existingExpenses) {
                await expRepo.deleteExpense(e.id);
              }
            }

            for (var item in _advancedSplits!) {
              final e = Expense()
                ..transactionId = item.paidByPersonId == 0 ? txId : null
                ..paidByPersonId = item.paidByPersonId
                ..totalAmount = item.amount
                ..categoryId = item.categoryId ?? _selectedCategoryId
                ..note = item.note.isNotEmpty ? item.note : _noteController.text
                ..date = _date;
              final expenseId = await expRepo.addExpense(e);

              final splitList = item.splits
                  .map(
                    (s) => ExpenseSplit()
                      ..expenseId = expenseId
                      ..personId = s.personId
                      ..amount = double.parse(s.amountController.text),
                  )
                  .toList();
              await expRepo.addExpenseSplits(splitList);
            }
          }
        } else {
          // Standard Transaction
          if (!isUpdate) {
            txId = await txRepo.addTransaction(transaction);
          } else if (txId != null) {
            final existingExpenses = await expRepo.getExpensesForTransaction(
              txId,
            );
            for (var e in existingExpenses) {
              await expRepo.deleteExpense(e.id);
            }
          }
        }

        // Logic to update Account Balance (Savings/Reserved)
        final accountRepo = ref.read(accountsRepositoryProvider);
        if (_selectedAccountId != null && txId != null) {
          final accounts = await accountRepo.getAllAccounts();
          final account = accounts
              .where((a) => a.id == _selectedAccountId)
              .firstOrNull;
          if (account != null) {
            bool updated = false;
            // Expense Logic (Reserved Deduction)
            if (_type == TransactionType.expense ||
                _type == TransactionType.transfer) {
              final balanceAfterTxn = await ref
                  .read(transactionsRepositoryProvider)
                  .getAccountBalance(account.id, account.openingBalance);
              final preTxnBalance = balanceAfterTxn + amount; // Revert locally

              final preTxnSpendable = preTxnBalance - account.reservedBalance;

              double amountRemaining = amount;

              // 1. Deduct from Spendable
              if (amountRemaining <= preTxnSpendable) {
                amountRemaining = 0;
              } else {
                amountRemaining -= preTxnSpendable; // Spendable exhausted
              }

              // 3. Deduct from Reserved
              if (amountRemaining > 0) {
                if (account.reservedBalance > 0) {
                  final deduct = amountRemaining < account.reservedBalance
                      ? amountRemaining
                      : account.reservedBalance;
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

        if (mounted) {
          context.pop(true);
        }
      } catch (e, stack) {
        debugPrint('Error saving transaction: $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy logic if needed
              },
            ),
          ),
        );
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

    // Load People for Splits
    final peopleAsync = ref.watch(peopleStreamProvider);

    // Accounts with Balance
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final currency = ref.watch(currencyProvider);

    final inputDecoration = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.extra is Transaction
              ? 'Edit Transaction'
              : (_isRefundMode ? 'Refund Transaction' : 'Add Transaction'),
        ),
        actions: [],
        bottom: _isRefundMode
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: false,
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
                    const Text(
                      'Settlement Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Track debt payments directly. No splits.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Gap(16),
                    // Direction Toggle
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('I Paid (They Owe Less)'),
                            selected: _settlementIPaid,
                            onSelected: (v) => setState(() {
                              _settlementIPaid = true;
                              _type = TransactionType.expense;
                            }),
                            avatar: const Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('They Paid (I Owe Less)'),
                            selected: !_settlementIPaid,
                            onSelected: (v) => setState(() {
                              _settlementIPaid = false;
                              _type = TransactionType.income;
                            }),
                            avatar: const Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // Party Selector
                    peopleAsync.when(
                      data: (people) {
                        // Ensure the selected party ID actually exists in the list to avoid crash
                        int? validPartyId = _settlementPartyId;
                        if (validPartyId != null && !people.any((p) => p.id == validPartyId)) {
                          validPartyId = null;
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: validPartyId,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Select Person',
                            prefixIcon: const Icon(Icons.person),
                          ),
                          items: people
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _settlementPartyId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading people'),
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
                      fillColor: _isRefundMode
                          ? Theme.of(context).disabledColor.withOpacity(0.05)
                          : null,
                      filled: _isRefundMode,
                    ),
                    keyboardType: TextInputType.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (MathEvaluator.evaluate(v) == null)
                        return 'Invalid Amount';
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
                                _date = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  _date.hour,
                                  _date.minute,
                                );
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: inputDecoration.copyWith(
                              labelText: 'Date',
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 20,
                              ),
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
                        child: _hasTime
                            ? InkWell(
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_date),
                                  );
                                  if (t != null) {
                                    setState(() {
                                      _date = DateTime(
                                        _date.year,
                                        _date.month,
                                        _date.day,
                                        t.hour,
                                        t.minute,
                                      );
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: inputDecoration.copyWith(
                                    labelText: 'Time',
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () =>
                                          setState(() => _hasTime = false),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat.jm().format(_date),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 47,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _hasTime = true),
                                  icon: const Icon(Icons.access_time),
                                  label: const Text('Add Time'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  const Gap(16),

                  // Account Selection (From)
                  accountsAsync.when(
                    data: (accounts) {
                      final selected = accounts
                          .where((a) => a.account.id == _selectedAccountId)
                          .firstOrNull;
                      return _buildSelector(
                        label: _type == TransactionType.income
                            ? 'Deposit To'
                            : 'Pay From',
                        title: selected?.account.name ?? 'Select Account',
                        subtitle: selected != null
                            ? '$currency${selected.balance.toStringAsFixed(2)}'
                            : null,
                        leading: selected != null
                            ? buildIconWidget(
                                selected.account.iconData,
                                Color(selected.account.color),
                                size: 48,
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                        onTap: () =>
                            _showAccountPicker(accounts, false, currency),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading accounts'),
                  ),
                  const Gap(16),

                  // To Account (Transfer only)
                  if (_type == TransactionType.transfer) ...[
                    accountsAsync.when(
                      data: (accounts) {
                        final selected = accounts
                            .where((a) => a.account.id == _selectedToAccountId)
                            .firstOrNull;
                        final filteredAccounts = accounts
                            .where((a) => a.account.id != _selectedAccountId)
                            .toList();
                        return _buildSelector(
                          label: 'Transfer To',
                          title: selected?.account.name ?? 'Select Account',
                          subtitle: selected != null
                              ? '$currency${selected.balance.toStringAsFixed(2)}'
                              : null,
                          leading: selected != null
                              ? buildIconWidget(
                                  selected.account.iconData,
                                  Color(selected.account.color),
                                  size: 48,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                          onTap: () => _showAccountPicker(
                            filteredAccounts,
                            true,
                            currency,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const Gap(16),
                  ],

                  // Category Selection (Normal Mode)
                  if (_type != TransactionType.transfer && !_isSplit)
                    categoriesAsync.when(
                      data: (categories) {
                        final effectiveCategoryId =
                            (_selectedCategoryId != null &&
                                categories.any(
                                  (c) => c.id == _selectedCategoryId,
                                ))
                            ? _selectedCategoryId
                            : null;

                        final selected = categories
                            .where((c) => c.id == effectiveCategoryId)
                            .firstOrNull;
                        return _buildSelector(
                          label: 'Category',
                          title: selected?.name ?? 'None',
                          leading: selected != null
                              ? buildIconWidget(
                                  selected.iconData,
                                  Color(selected.color),
                                  size: 48,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                  child: const Icon(Icons.do_not_disturb_alt),
                                ),
                          onTap: () => _showCategoryPicker(categories),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),

                  if (_type == TransactionType.income) ...[
                    const Gap(8),
                    // Removed Bucket Allocation UI since buckets feature is deprecated
                  ],

                  if (_type != TransactionType.transfer &&
                      _tabController.index != 3) ...[
                    const Gap(8),
                    Row(
                      children: [
                        const Text('Split Transaction?'),
                        const Spacer(),
                        Switch(
                          value: _isSplit,
                          onChanged: (v) async {
                            setState(() {
                              _isSplit = v;
                            });
                            if (_isSplit &&
                                (_advancedSplits == null ||
                                    _advancedSplits!.isEmpty)) {
                              // Instantly open advanced split page
                              final people =
                                  ref.read(peopleStreamProvider).value ?? [];
                              final result = await context
                                  .push<List<AdvancedExpenseItem>>(
                                    '/advanced-split',
                                    extra: {
                                      'initialItems': _advancedSplits ?? [],
                                      'people': people,
                                      'isIncome':
                                          _type == TransactionType.income,
                                      'categories':
                                          _type == TransactionType.income
                                          ? (ref
                                                    .read(
                                                      incomeCategoriesProvider,
                                                    )
                                                    .value ??
                                                [])
                                          : (ref
                                                    .read(
                                                      expenseCategoriesProvider,
                                                    )
                                                    .value ??
                                                []),
                                    },
                                  );
                              if (result != null && result.isNotEmpty) {
                                setState(() {
                                  _advancedSplits = result;
                                });
                              } else if (_advancedSplits == null ||
                                  _advancedSplits!.isEmpty) {
                                // If they cancelled and it's still empty, toggle switch off
                                setState(() {
                                  _isSplit = false;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  // ADVANCED SPLIT SUMMARY CARD
                  if (_isSplit) ...[
                    const Gap(16),
                    Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.blue,
                                ),
                                const Gap(8),
                                const Text(
                                  'Split Items',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () async {
                                    final people =
                                        ref.read(peopleStreamProvider).value ??
                                        [];
                                    final result = await context
                                        .push<List<AdvancedExpenseItem>>(
                                          '/advanced-split',
                                          extra: {
                                            'initialItems':
                                                _advancedSplits ?? [],
                                            'people': people,
                                            'isIncome':
                                                _type == TransactionType.income,
                                            'categories':
                                                _type == TransactionType.income
                                                ? (ref
                                                          .read(
                                                            incomeCategoriesProvider,
                                                          )
                                                          .value ??
                                                      [])
                                                : (ref
                                                          .read(
                                                            expenseCategoriesProvider,
                                                          )
                                                          .value ??
                                                      []),
                                          },
                                        );
                                    if (result != null) {
                                      setState(() {
                                        _advancedSplits = result;
                                        if (_advancedSplits!.isEmpty)
                                          _isSplit = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const Gap(8),

                            if (_advancedSplits != null &&
                                _advancedSplits!.isNotEmpty) ...[
                              ..._advancedSplits!.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.note.isNotEmpty
                                              ? item.note
                                              : 'Item',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${ref.watch(currencyProvider)}${item.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Split',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${ref.watch(currencyProvider)}${_advancedSplits!.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Text(
                                'No splits added. Tap edit to add.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Gap(16),
                  TextFormField(
                    controller: _noteController,
                    decoration: inputDecoration.copyWith(labelText: 'Note'),
                    maxLines: 2,
                  ),

                  const Gap(16),
                  SwitchListTile(
                    value: _skipFromStats,
                    onChanged: (v) => setState(() => _skipFromStats = v),
                    title: const Text('Ignore in Calculation'),
                    subtitle: const Text(
                      'Don\'t include in Analytics or Totals',
                    ),
                    activeThumbColor: Colors.orange,
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  const Gap(24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

class ExpenseSplitInput {
  final TextEditingController amountController;
  int personId; // 0 = Me

  ExpenseSplitInput({
    TextEditingController? amountController,
    this.personId = 0,
  }) : amountController = amountController ?? TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}
