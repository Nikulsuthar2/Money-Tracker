import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart' as model;
import 'package:gap/gap.dart';

import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/core/utils/math_evaluator.dart';

class AddLedgerTransactionPage extends ConsumerStatefulWidget {
  const AddLedgerTransactionPage({super.key});

  @override
  ConsumerState<AddLedgerTransactionPage> createState() => _AddLedgerTransactionPageState();
}

class _AddLedgerTransactionPageState extends ConsumerState<AddLedgerTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Party? _paidBy;
  Account? _selectedAccount;
  
  final Set<int> _selectedPartyIds = {}; 
  final Map<int, TextEditingController> _shareControllers = {};
  
  String _splitType = 'Equal'; // Equal or Custom
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _amountController.addListener(_onAmountChanged);
  }
  
  void _onAmountChanged() {
    if (_splitType == 'Equal') {
      _distributeEqualShares();
    }
  }

  void _distributeEqualShares() {
    if (_selectedPartyIds.isEmpty) return;
    final total = MathEvaluator.evaluate(_amountController.text) ?? 0.0;
    final share = total / _selectedPartyIds.length;
    
    for (var id in _selectedPartyIds) {
       if (!_shareControllers.containsKey(id)) {
          _shareControllers[id] = TextEditingController();
       }
       _shareControllers[id]!.text = share.toStringAsFixed(2);
    }
    setState(() {});
  }
  
  Future<void> _loadAccounts() async {
     final accounts = await ref.read(accountsRepositoryProvider).getAllAccounts();
     if (mounted) {
       setState(() {
         _accounts = accounts;
       });
     }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    for (var c in _shareControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
       if (_paidBy == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select who paid')));
          return;
       }
       if (_selectedPartyIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one person involved')));
          return;
       }
       
       if (_paidBy!.isMe() && _selectedAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select which account you paid from')));
          return;
       }

       final amount = MathEvaluator.evaluate(_amountController.text) ?? 0.0;
       
       // Verify Custom Split Sum
       if (_splitType == 'Custom') {
           double sum = 0;
           for (var id in _selectedPartyIds) {
               sum += double.tryParse(_shareControllers[id]?.text ?? '0') ?? 0;
           }
           if ((sum - amount).abs() > 0.1) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sum of shares ($sum) does not match Total ($amount)')));
              return;
           }
       }
       
       final description = _descriptionController.text;
       final date = DateTime.now();
       
       List<LedgerEntry> entries = [];
       
       // 2. Generate Ledger Entries
       for (final consumerId in _selectedPartyIds) {
          final isConsumerMe = ref.read(partiesStreamProvider).value?.firstWhere((p) => p.id == consumerId).isMe() ?? false; 
          final isPayerMe = _paidBy!.isMe();
          
          final shareAmount = double.tryParse(_shareControllers[consumerId]?.text ?? '0') ?? 0;

          // A. Expense Recording (Optional / Internal)
          // We don't strictly need 'expense' nature anymore for debt tracking.
          // But if we want to log it?
          // entries.add(LedgerEntry()
          //   ..partyId = consumerId
          //   ..nature = LedgerNature.internal 
          //   ..amount = shareAmount
          //   ..date = date
          //   ..note = '$description (Share)'
          // );
          
          // B. Debt/Asset Recording
          if (consumerId != _paidBy!.id) {
              if (isPayerMe) {
                 // I Paid -> Friend Owes Me (Receivable)
                 entries.add(LedgerEntry()
                    ..partyId = consumerId
                    ..nature = LedgerNature.owe
                    ..amount = shareAmount
                    ..date = date
                    ..note = 'Owed to Me for $description'
                 );
              } else if (isConsumerMe) {
                 // Friend Paid -> I Owe Friend (Payable) -> Friend has Receivable?
                 // Wait, strict rule: OWE = Creating Debt.
                 // Friend Paid. I consumed. I owe Friend.
                 // Entry should be for Friend Party?
                 // If I view Friend's Ledger:
                 // Amount should be -100? (I Owe).
                 
                 entries.add(LedgerEntry()
                    ..partyId = _paidBy!.id
                    ..nature = LedgerNature.owe
                    ..amount = -shareAmount // Negative OWE = I Owe Them
                    ..date = date
                    ..note = 'Owed to ${_paidBy!.name} for $description'
                 );
              }
          }
       }
       
       // 3. Create Physical Transaction (Removed - User wants Ledger Only)
       // model.Transaction? transaction;
       
       // 4. Save
       try {
           final ledgerService = ref.read(ledgerServiceProvider);
           await ledgerService.recordEconomicEvent(entries: entries, transaction: null);
           
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
              context.pop();
           }
       } catch (e) {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
           }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesStreamProvider);
    
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Ledger Entry')),
      body: partiesAsync.when(
        data: (parties) {
             if (parties.isEmpty) return const Center(child: Text('Add Parties first!'));
             
             return Form(
               key: _formKey,
               child: ListView(
                 padding: const EdgeInsets.all(24),
                 children: [
                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text('Amount', style: TextStyle(fontSize: 16)),
                          const Gap(8),
                             TextFormField(
                                 controller: _amountController,
                                 textAlign: TextAlign.center,
                                 keyboardType: TextInputType.text,
                                 style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                 decoration: const InputDecoration(
                                   border: InputBorder.none,
                                   hintText: '0.00',
                                 ),
                                 onFieldSubmitted: (v) {
                                    final val = MathEvaluator.evaluate(v);
                                    if (val != null) {
                                        _amountController.text = val.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                                    }
                                 },
                                 onTapOutside: (_) {
                                    final val = MathEvaluator.evaluate(_amountController.text);
                                    if (val != null) {
                                        _amountController.text = val.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                                    }
                                 },
                                 validator: (v) => MathEvaluator.evaluate(v ?? '') == null ? 'Invalid' : null,
                              ),
                        ],
                      ),
                    ),
                    const Gap(24),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const Gap(24),
                    
                    // Paid By
                    DropdownButtonFormField<Party>(
                      decoration: InputDecoration(
                         labelText: 'Paid By',
                         prefixIcon: const Icon(Icons.wallet),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      value: _paidBy,
                      items: parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (p) => setState(() { 
                        _paidBy = p;
                        if (p != null) _selectedPartyIds.add(p.id);
                      }),
                    ),
                    const Gap(16),
                    
                    // Account Selector (Only if I Paid)
                    if (_paidBy != null && _paidBy!.isMe()) 
                        DropdownButtonFormField<Account>(
                          decoration: InputDecoration(
                             labelText: 'Paid From Account',
                             prefixIcon: const Icon(Icons.account_balance_wallet), // Different icon
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          value: _selectedAccount,
                          items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                          onChanged: (a) => setState(() => _selectedAccount = a),
                        ),
                    
                     const Gap(16),
                     SegmentedButton<String>(
                       segments: const [
                         ButtonSegment(value: 'Equal', label: Text('Equal Split'), icon: Icon(Icons.calculate)),
                         ButtonSegment(value: 'Custom', label: Text('Custom Amount'), icon: Icon(Icons.edit)),
                       ],
                       selected: {_splitType},
                       onSelectionChanged: (s) {
                          setState(() {
                             _splitType = s.first;
                             if (_splitType == 'Equal') _distributeEqualShares();
                          });
                       },
                     ),
                     const Gap(16),
                     
                     const Text('Split With', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const Gap(8),
                     
                     // Party List with Share Input
                     ...parties.map((p) {
                         final isSelected = _selectedPartyIds.contains(p.id);
                         final controller = _shareControllers[p.id];
                         
                         return Card(
                           margin: const EdgeInsets.only(bottom: 8),
                           elevation: 0,
                           color: isSelected ? theme.colorScheme.secondaryContainer.withOpacity(0.4) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                           child: CheckboxListTile(
                             value: isSelected,
                             onChanged: (v) {
                               setState(() {
                                 if (v == true) {
                                    _selectedPartyIds.add(p.id);
                                    if (!_shareControllers.containsKey(p.id)) {
                                       _shareControllers[p.id] = TextEditingController();
                                    }
                                 } else {
                                    _selectedPartyIds.remove(p.id);
                                 }
                                 if (_splitType == 'Equal') _distributeEqualShares();
                               });
                             },
                             title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                             secondary: CircleAvatar(child: Text(p.name[0])),
                             subtitle: isSelected ? Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: TextFormField(
                                 controller: controller,
                                 enabled: _splitType == 'Custom',
                                 keyboardType: TextInputType.number,
                                 decoration: const InputDecoration(
                                   prefixText: '₹',
                                   isDense: true,
                                   border: OutlineInputBorder(),
                                   labelText: 'Share Amount',
                                 ),
                                 onChanged: (_) {
                                    // Verify sum?
                                 },
                               ),
                             ) : null,
                           ),
                         );
                     }),
                    
                     const Gap(40),
                     FilledButton.icon(
                       onPressed: _save,
                       icon: const Icon(Icons.check),
                       label: const Text('Save to Ledger'),
                       style: FilledButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                       ),
                     ),
                  ],
                ),
              );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
