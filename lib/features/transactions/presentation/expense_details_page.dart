import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:money_manager/core/widgets/icon_utils.dart';
class ExpenseDetailsPage extends ConsumerWidget {
  const ExpenseDetailsPage({super.key, required this.entry});

  final ExpenseOnlyTimelineEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    
    final expenses = entry.expenses;
    if (expenses.isEmpty) return const Scaffold(body: Center(child: Text('No details')));

    final firstExp = expenses.first;
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.totalAmount);
    final date = firstExp.date;
    final paidByPersonId = firstExp.paidByPersonId ?? 0;
    
    final categoryAsync = ref.watch(categoriesStreamProvider);
    Category? category;
    if (firstExp.categoryId != null && categoryAsync.hasValue) {
       category = categoryAsync.value!.where((c) => c.id == firstExp.categoryId).firstOrNull;
    }
    final personAsync = ref.watch(peopleStreamProvider);
    
    String personName = 'Friend';
    if (personAsync.hasValue) {
       final p = personAsync.value!.where((p) => p.id == paidByPersonId).firstOrNull;
       if (p != null) personName = p.name;
    }

    final title = firstExp.note?.isNotEmpty == true ? firstExp.note! : 
                  (expenses.length > 1 ? 'Multiple Expenses' : (category?.name ?? 'Expense'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Convert Expense to Transaction-like structure for AdvancedSplitPage
              final t = Transaction()
                ..id = 0 // new transaction
                ..date = date
                ..title = title
                ..note = firstExp.note;
                
              final inputItems = <Expense>[];
              for (var e in expenses) {
                 final inputE = Expense()
                    ..id = e.id
                    ..categoryId = e.categoryId
                    ..note = e.note
                    ..totalAmount = e.totalAmount
                    ..paidByPersonId = e.paidByPersonId;
                 inputItems.add(inputE);
              }
              t.subTransactions = inputItems;
              
              // We pass it to split page
              context.push('/advanced-split', extra: t).then((_) {
                 // Might need to refresh or pop if deleted/modified
                 context.pop(); 
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref, expenses),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Gap(16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, size: 40, color: Colors.orange),
            ),
            const Gap(16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              '$currency${formatAmount(totalAmount)}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              !(date.hour == 0 && date.minute == 0 && date.second == 0) ? DateFormat('MMMM d, yyyy - h:mm a').format(date) : DateFormat('MMMM d, yyyy').format(date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(32),

            // Who Paid
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerHighest,
                 borderRadius: BorderRadius.circular(16)
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Paid By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text(personName, style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                 ],
               ),
            ),
            const Gap(16),
            
            // Splits Breakdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Split Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(8),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: expenses.map((e) {
                     final splits = entry.splits[e.id] ?? [];
                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          if (expenses.length > 1) ...[
                             Text(e.note?.isNotEmpty == true ? e.note! : 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                             const Gap(4),
                          ],
                          ...splits.map((s) {
                             String sName = 'Me';
                             if (s.personId != null && s.personId != 0 && personAsync.hasValue) {
                                final sp = personAsync.value!.where((p) => p.id == s.personId).firstOrNull;
                                if (sp != null) sName = sp.name;
                             }
                             return Padding(
                               padding: const EdgeInsets.symmetric(vertical: 4),
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Expanded(child: Text(sName, overflow: TextOverflow.ellipsis)),
                                   const Gap(16),
                                   Text('$currency${formatAmount(s.amount)}'),
                                 ],
                               ),
                             );
                          }),
                          if (e != expenses.last) const Divider(height: 16),
                       ],
                     );
                  }).toList(),
                ),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, List<Expense> expenses) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This will permanently delete this expense and update balances. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final repo = ref.read(expensesRepositoryProvider);
      for (var e in expenses) {
         await repo.deleteExpense(e.id!);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted')),
        );
      }
    }
  }
}
