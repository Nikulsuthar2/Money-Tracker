import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart'; // Standard DataTable is okay but responsive is better. Using standard for now to avoid dep if simple.
// Actually standard DataTable in SingleChildScrollView is fine.

class AllTransactionsTablePage extends ConsumerWidget {
  const AllTransactionsTablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          color: Theme.of(context).cardTheme.color,
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) return const Center(child: Text('No transactions'));

              return categoriesAsync.when(
                data: (categories) {
                  return accountsAsync.when(
                    data: (accounts) {
                      return DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                        columns: const [
                          DataColumn2(label: Text('Date'), size: ColumnSize.S),
                          DataColumn2(label: Text('Type'), size: ColumnSize.S),
                          DataColumn2(label: Text('Amount'), size: ColumnSize.S, numeric: true),
                          DataColumn2(label: Text('Category'), size: ColumnSize.L),
                          DataColumn2(label: Text('Account'), size: ColumnSize.M),
                          DataColumn2(label: Text('Note'), size: ColumnSize.L),
                        ],
                        rows: transactions.map((t) {
                          final cat = categories.where((c) => c.id == t.categoryId).firstOrNull;
                          final accountId = t.type == TransactionType.income ? t.toAccountId : t.fromAccountId;
                          final acc = accounts.where((a) => a.id == accountId).firstOrNull;
                          
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('MM/dd HH:mm').format(t.date))),
                            DataCell(Text(t.type.name.toUpperCase().substring(0, 3))),
                            DataCell(Text('\$${t.amount.toStringAsFixed(0)}', style: TextStyle(
                              color: t.type == TransactionType.expense ? Colors.red : (t.type == TransactionType.income ? Colors.green : Colors.blue),
                              fontWeight: FontWeight.bold
                            ))),
                            DataCell(Row(children: [
                               if (t.subTransactions != null && t.subTransactions!.isNotEmpty)
                                  const Text('Split Transaction', style: TextStyle(fontStyle: FontStyle.italic))
                               else ...[
                                 if(cat!=null) Icon(IconData(cat.icon, fontFamily: 'MaterialIcons'), size: 16, color: Color(cat.color)),
                                 const SizedBox(width: 4),
                                 Text(cat?.name ?? '-', overflow: TextOverflow.ellipsis)
                               ]
                            ])),
                            DataCell(Text(acc?.name ?? '-', overflow: TextOverflow.ellipsis)), 
                            DataCell(Text(t.note ?? '-', overflow: TextOverflow.ellipsis)),
                          ]);
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()), 
                    error: (_,__) => const Text('Error loading accounts')
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()), 
                error: (_,__) => const Text('Error loading categories')
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}
