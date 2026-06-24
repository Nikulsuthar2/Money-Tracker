import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/expenses/data/expenses_repository.dart';

final analyticsTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final txRepo = ref.watch(transactionsRepositoryProvider);
  final expRepo = ref.watch(expensesRepositoryProvider);

  return Rx.combineLatest3(
     txRepo.watchAllTransactions(),
     expRepo.watchAllExpenses(),
     expRepo.watchAllExpenseSplits(),
     (rawTxns, allExpenses, allSplits) {
        final List<Transaction> trueTransactions = [];

        for (var t in rawTxns) {
           if (t.isSettlement) continue; // Settlements are ignored in analytics

           // If it's an expense or income, check if it has a linked Expense row
           if (t.type == TransactionType.expense || t.type == TransactionType.income) {
               final linkedExpenses = allExpenses.where((exp) => exp.transactionId == t.id).toList();
               if (linkedExpenses.isNotEmpty) {
                  // This transaction has one or more Expense items (split or categorized)
                  for (final e in linkedExpenses) {
                     final splits = allSplits.where((s) => s.expenseId == e.id).toList();
                     final mySplit = splits.where((s) => s.personId == 0).firstOrNull;
                     
                     // If there are no splits, it means I paid the full amount for this specific item
                     final double myTrueExpenseAmount = mySplit != null ? mySplit.amount : e.totalAmount;

                     if (myTrueExpenseAmount > 0) {
                        final adjustedTxn = Transaction()
                           ..id = t.id // Note: Duplicate IDs in UI might occur, but it's fine for analytics sum
                           ..type = t.type
                           ..amount = myTrueExpenseAmount
                           ..currency = t.currency
                           ..fromAccountId = t.fromAccountId
                           ..toAccountId = t.toAccountId
                           ..categoryId = e.categoryId ?? t.categoryId
                           ..note = e.note ?? t.note
                           ..date = t.date
                           ..isSettlement = false
                           ..skipFromStats = t.skipFromStats;
                        trueTransactions.add(adjustedTxn);
                     }
                  }
               } else {
                  // Standard Expense/Income (no linked expense rows)
                  trueTransactions.add(t);
               }
           } else {
               // Transfer, etc.
               trueTransactions.add(t);
           }
        }

        // Now add Expenses where I owe money but NO money left my bank (transactionId == null)
        for (var e in allExpenses) {
           if (e.transactionId == null) {
              final splits = allSplits.where((s) => s.expenseId == e.id).toList();
              final mySplit = splits.where((s) => s.personId == 0).firstOrNull;
              final double myTrueExpenseAmount = mySplit?.amount ?? 0.0;

              if (myTrueExpenseAmount > 0) {
                 final syntheticTxn = Transaction()
                    ..id = -e.id! // Negative ID to indicate synthetic
                    ..type = TransactionType.expense
                    ..amount = myTrueExpenseAmount
                    ..currency = 'INR' // Assuming INR, or fetch from somewhere
                    ..fromAccountId = null
                    ..toAccountId = null
                    ..categoryId = e.categoryId
                    ..note = e.note ?? 'Friend Paid'
                    ..date = e.date
                    ..isSettlement = false
                    ..skipFromStats = false;
                 trueTransactions.add(syntheticTxn);
              }
           }
        }

        return trueTransactions;
     }
  );
});
