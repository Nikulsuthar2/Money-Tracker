import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/domain/investment_holding.dart';
import 'package:money_manager/features/accounts/data/investment_holdings_repository.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:collection/collection.dart';

class HoldingsCard extends ConsumerWidget {
  final Account account;
  
  const HoldingsCard({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (account.isCash) return const SizedBox.shrink();

    final holdingsAsync = ref.watch(accountHoldingsProvider(account.id));
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider).valueOrNull ?? [];
    final item = accountsWithBalance.firstWhereOrNull((a) => a.account.id == account.id);
    final fundBalance = item?.balance ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Row(
                   children: [
                      Icon(Icons.show_chart, color: theme.colorScheme.primary),
                      const Gap(12),
                      const Text('Holdings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   ],
                 ),
                 TextButton.icon(
                   onPressed: () => _showAddHoldingDialog(context, ref, account, fundBalance),
                   icon: const Icon(Icons.add, size: 18),
                   label: const Text('Add'),
                 )
               ],
             ),
             const Gap(16),
             holdingsAsync.when(
               data: (holdings) {
                  if (holdings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No holdings tracked. Add your stocks/assets here for reference.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      )
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: holdings.length,
                    separatorBuilder: (ctx, idx) => Divider(height: 16, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    itemBuilder: (ctx, idx) {
                       final h = holdings[idx];
                       final invested = h.quantity * h.averageBuyPrice;
                       final current = h.quantity * h.currentPrice;
                       final plAmount = current - invested;
                       final pl = invested != 0 ? (plAmount / invested) * 100 : 0;
                       
                       return InkWell(
                         onTap: () => _showAddHoldingDialog(context, ref, account, fundBalance, holding: h),
                         child: Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4.0),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const Gap(4),
                                      Text('${h.type} • Qty: ${h.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                      const Gap(2),
                                      Text('Buy: $currency${h.averageBuyPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Gap(8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$currency${current.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Gap(4),
                                    Text('${plAmount >= 0 ? '+' : '-'}$currency${plAmount.abs().toStringAsFixed(2)} (${pl >= 0 ? '+' : ''}${pl.toStringAsFixed(2)}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: plAmount >= 0 ? Colors.green.shade600 : Colors.red.shade600)),
                                    const Gap(2),
                                    Text('LTP: $currency${h.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                             ],
                           ),
                         ),
                       );
                    },
                  );
               },
               loading: () => const Center(child: CircularProgressIndicator()),
               error: (e, s) => Text('Error: $e'),
             ),
          ]
    );
  }

  void _showAddHoldingDialog(BuildContext context, WidgetRef ref, Account account, double fundBalance, {InvestmentHolding? holding}) {
    final symbolCtrl = TextEditingController(text: holding?.symbol ?? '');
    final quantityCtrl = TextEditingController(text: holding?.quantity.toString() ?? '');
    final buyPriceCtrl = TextEditingController(text: holding?.averageBuyPrice.toString() ?? '');
    final currentPriceCtrl = TextEditingController(text: holding?.currentPrice.toString() ?? '');
    String selectedType = holding?.type ?? 'Equity';

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(holding == null ? 'Add Holding' : 'Edit Holding'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: symbolCtrl, 
                    decoration: const InputDecoration(labelText: 'Symbol / Name', hintText: 'e.g. AAPL, TCS'), 
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                       TextInputFormatter.withFunction((oldValue, newValue) => TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection))
                    ]
                  ),
                   const Gap(12),
                   DropdownButtonFormField<String>(
                     value: selectedType,
                     decoration: const InputDecoration(labelText: 'Holding Type'),
                     items: ['Equity', 'ETF', 'Index', 'Commodity', 'Crypto', 'Bonds'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                     onChanged: (v) => setState(() => selectedType = v!),
                   ),
                   const Gap(12),
                   TextField(controller: quantityCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                   const Gap(12),
                   TextField(controller: buyPriceCtrl, decoration: const InputDecoration(labelText: 'Average Buy Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                   const Gap(12),
                   TextField(controller: currentPriceCtrl, decoration: const InputDecoration(labelText: 'Current Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ],
              ),
            ),
            actions: [
               if (holding != null)
                 TextButton(
                   onPressed: () async {
                      await ref.read(investmentHoldingsRepositoryProvider).deleteHolding(holding.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                   },
                   child: const Text('Delete', style: TextStyle(color: Colors.red)),
                 ),
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
               FilledButton(
                 onPressed: () async {
                    if (symbolCtrl.text.isEmpty || quantityCtrl.text.isEmpty || buyPriceCtrl.text.isEmpty || currentPriceCtrl.text.isEmpty) {
                       return;
                    }
                    
                    final isNew = holding == null;
                    final h = holding ?? InvestmentHolding()..accountId = account.id;
                      
                    h.symbol = symbolCtrl.text;
                    h.type = selectedType;
                    h.quantity = double.tryParse(quantityCtrl.text) ?? 0;
                    h.averageBuyPrice = double.tryParse(buyPriceCtrl.text) ?? 0;
                    h.currentPrice = double.tryParse(currentPriceCtrl.text) ?? 0;
                    
                    if (isNew) {
                       final tradeValue = h.quantity * h.averageBuyPrice;
                       if (tradeValue > fundBalance) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Insufficient funds in Fund Wallet')));
                          return;
                       }
                       
                       // Create Transaction
                       final categoriesRepo = ref.read(categoriesRepositoryProvider);
                       final categories = await categoriesRepo.getAllCategories();
                       final investCategory = categories.firstWhereOrNull((c) => c.name.toLowerCase().contains('invest'));

                       final t = Transaction()
                         ..type = TransactionType.buyInvestment
                         ..amount = tradeValue
                         ..date = DateTime.now()
                         ..title = 'Buy ${h.quantity} ${h.symbol}'
                         ..note = 'Buy ${h.quantity} ${h.symbol}'
                         ..categoryId = investCategory?.id
                         ..fromAccountId = account.id;
                         
                       await ref.read(transactionsRepositoryProvider).addTransaction(t);
                       
                       // Add holding
                       await ref.read(investmentHoldingsRepositoryProvider).addHolding(h);
                    } else {
                       await ref.read(investmentHoldingsRepositoryProvider).updateHolding(h);
                    }
                    
                    if (ctx.mounted) Navigator.pop(ctx);
                 }, 
                 child: const Text('Save')
               ),
            ],
          );
        }
      )
    );
  }
}
