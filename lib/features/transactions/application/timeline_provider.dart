import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';

final timelineProvider = StreamProvider<List<TimelineEntry>>((ref) {
  final transactionsStream = ref.watch(transactionsRepositoryProvider).watchAllTransactions();
  final expensesStream = ref.watch(expensesRepositoryProvider).watchAllExpenses();
  final splitsStream = ref.watch(expensesRepositoryProvider).watchAllExpenseSplits();
  final settlementsStream = ref.watch(expensesRepositoryProvider).watchAllSettlements();

  return Rx.combineLatest4(
    transactionsStream,
    expensesStream,
    splitsStream,
    settlementsStream,
    (transactions, expenses, allSplits, settlements) {
      final List<TimelineEntry> entries = [];

      // 1. Process Transactions (which may have associated Expenses)
      for (final tx in transactions) {
        // Find expenses linked to this transaction
        final linkedExpenses = expenses.where((e) => e.transactionId == tx.id).toList();
        final Map<int, List<ExpenseSplit>> linkedSplits = {};
        for (final e in linkedExpenses) {
           linkedSplits[e.id] = allSplits.where((s) => s.expenseId == e.id).toList();
        }
        
        entries.add(TransactionTimelineEntry(
          transaction: tx,
          expenses: linkedExpenses,
          splits: linkedSplits,
        ));
      }

      // 2. Process Friend-Paid Expenses (No Transaction)
      // Group them by their exact date/time so multiple items in one bill are grouped
      final friendPaidExpenses = expenses.where((e) => e.transactionId == null).toList();
      final Map<int, List<Expense>> groupedFriendPaid = {};
      
      for (final exp in friendPaidExpenses) {
        final key = exp.date.millisecondsSinceEpoch;
        if (!groupedFriendPaid.containsKey(key)) {
          groupedFriendPaid[key] = [];
        }
        groupedFriendPaid[key]!.add(exp);
      }

      for (final group in groupedFriendPaid.values) {
        if (group.isNotEmpty) {
          final Map<int, List<ExpenseSplit>> linkedSplits = {};
          for (final e in group) {
             linkedSplits[e.id] = allSplits.where((s) => s.expenseId == e.id).toList();
          }
          entries.add(ExpenseOnlyTimelineEntry(
            expenses: group,
            splits: linkedSplits,
          ));
        }
      }

      // 3. Process Settlements
      for (final settlement in settlements) {
        entries.add(SettlementTimelineEntry(settlement: settlement));
      }

      // Sort all entries by date descending
      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries;
    },
  );
});
