import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/investment_holdings_repository.dart';
import 'package:money_manager/features/accounts/domain/investment_holding.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart' as intl;

class TradeStockSheet extends ConsumerStatefulWidget {
  const TradeStockSheet({super.key, required this.account, required this.fundBalance});

  final Account account;
  final double fundBalance;

  @override
  ConsumerState<TradeStockSheet> createState() => _TradeStockSheetState();
}

class _TradeStockSheetState extends ConsumerState<TradeStockSheet> {
  bool _isBuy = true;
  String _holdingType = 'Equity';
  
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _date = DateTime.now();

  InvestmentHolding? _selectedHolding;

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final tradeValue = quantity * price;

    if (_isBuy) {
      if (tradeValue > widget.fundBalance) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient funds in Fund Wallet')));
         return;
      }
      
      final symbol = _symbolController.text.toUpperCase();
      
      final categoriesRepo = ref.read(categoriesRepositoryProvider);
      final categories = await categoriesRepo.getAllCategories();
      final investCategory = categories.firstWhereOrNull((c) => c.name.toLowerCase().contains('invest'));

      // 1. Create Transaction
      final t = Transaction()
        ..type = TransactionType.buyInvestment
        ..amount = tradeValue
        ..date = _date
        ..title = 'Buy $quantity $symbol'
        ..note = 'Buy $quantity $symbol'
        ..categoryId = investCategory?.id
        ..fromAccountId = widget.account.id;
        
      await ref.read(transactionsRepositoryProvider).addTransaction(t);
      
      // 2. Add or Update Holding
      final holdingsRepo = ref.read(investmentHoldingsRepositoryProvider);
      final holdings = await holdingsRepo.getAccountHoldings(widget.account.id);
      final existing = holdings.where((h) => h.symbol == symbol).firstOrNull;
      
      if (existing != null) {
         // Update average buy price
         final totalCost = (existing.quantity * existing.averageBuyPrice) + tradeValue;
         existing.quantity += quantity;
         existing.averageBuyPrice = totalCost / existing.quantity;
         await holdingsRepo.updateHolding(existing);
      } else {
         final newHolding = InvestmentHolding()
           ..accountId = widget.account.id
           ..symbol = symbol
           ..type = _holdingType
           ..quantity = quantity
           ..averageBuyPrice = price
           ..currentPrice = price; // Set initial current price to buy price
         await holdingsRepo.addHolding(newHolding);
      }
      
    } else {
       // Sell
       if (_selectedHolding == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a stock to sell')));
          return;
       }
       if (quantity > _selectedHolding!.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough quantity to sell')));
          return;
       }
       
       final symbol = _selectedHolding!.symbol;
       
       // 1. Create Transaction
        final categoriesRepo = ref.read(categoriesRepositoryProvider);
        final categories = await categoriesRepo.getAllCategories();
        final investCategory = categories.firstWhereOrNull((c) => c.name.toLowerCase().contains('invest'));

        final t = Transaction()
         ..type = TransactionType.sellInvestment
         ..amount = tradeValue
         ..date = _date
         ..title = 'Sell $quantity $symbol'
         ..note = 'Sell $quantity $symbol'
         ..categoryId = investCategory?.id
         ..toAccountId = widget.account.id;
        
      await ref.read(transactionsRepositoryProvider).addTransaction(t);
      
      // 2. Reduce Holding
      final holdingsRepo = ref.read(investmentHoldingsRepositoryProvider);
      _selectedHolding!.quantity -= quantity;
      
      if (_selectedHolding!.quantity <= 0) {
         await holdingsRepo.deleteHolding(_selectedHolding!.id);
      } else {
         await holdingsRepo.updateHolding(_selectedHolding!);
      }
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final holdingsAsync = ref.watch(holdingsForAccountProvider(widget.account.id));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  const Text('Trade Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Fund: $currency${widget.fundBalance.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
               ],
            ),
            const Gap(16),
            
            // Toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Buy'),
                    selected: _isBuy,
                    onSelected: (v) => setState(() => _isBuy = true),
                    selectedColor: Colors.blue.withOpacity(0.2),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sell'),
                    selected: !_isBuy,
                    onSelected: (v) => setState(() {
                       _isBuy = false;
                       _selectedHolding = null;
                       _quantityController.clear();
                       _priceController.clear();
                    }),
                    selectedColor: Colors.orange.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const Gap(16),

            if (_isBuy) ...[
               TextFormField(
                 controller: _symbolController,
                 textCapitalization: TextCapitalization.characters,
                 decoration: const InputDecoration(labelText: 'Stock Symbol', hintText: 'e.g. AAPL', border: OutlineInputBorder()),
                 validator: (v) => v == null || v.isEmpty ? 'Required' : null,
               ),
               const Gap(16),
               DropdownButtonFormField<String>(
                 value: _holdingType,
                 decoration: const InputDecoration(labelText: 'Holding Type', border: OutlineInputBorder()),
                 items: ['Equity', 'ETF', 'Index', 'Commodity', 'Crypto', 'Bonds'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                 onChanged: (v) => setState(() => _holdingType = v!),
               ),
            ] else ...[
               holdingsAsync.when(
                 data: (holdings) {
                    if (holdings.isEmpty) return const Text('No holdings available to sell.');
                    return DropdownButtonFormField<InvestmentHolding>(
                      value: _selectedHolding,
                      decoration: const InputDecoration(labelText: 'Select Stock', border: OutlineInputBorder()),
                      items: holdings.map((h) => DropdownMenuItem(value: h, child: Text('${h.symbol} (Qty: ${h.quantity})'))).toList(),
                      onChanged: (v) => setState(() {
                         _selectedHolding = v;
                         _quantityController.text = v?.quantity.toString() ?? '';
                      }),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                 },
                 loading: () => const CircularProgressIndicator(),
                 error: (_,__) => const Text('Error loading holdings'),
               ),
            ],
            const Gap(16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Price', prefixText: '$currency ', border: const OutlineInputBorder()),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                  ),
                ),
              ],
            ),
            const Gap(16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _date = date;
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const Gap(12),
                    Text(
                      'Date: ${intl.DateFormat.yMMMd().format(_date)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            FilledButton(
              onPressed: _onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isBuy ? Colors.blue : Colors.orange,
              ),
              child: Text(_isBuy ? 'Confirm Buy' : 'Confirm Sell'),
            ),
          ],
        ),
      ),
    );
  }
}

final holdingsForAccountProvider = StreamProvider.family<List<InvestmentHolding>, int>((ref, accountId) {
  final repo = ref.watch(investmentHoldingsRepositoryProvider);
  return repo.watchAllHoldings().map((holdings) => holdings.where((h) => h.accountId == accountId).toList());
});
