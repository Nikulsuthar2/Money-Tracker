import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';

class AccountStats {
  final Account account;
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final double netExpense;
  final double reimbursed;

  AccountStats(this.account, this.balance, this.totalIncome, this.totalExpense, this.netIncome, this.netExpense, this.reimbursed);
}

final accountsWithBalanceProvider = StreamProvider.autoDispose<List<AccountStats>>((ref) async* {
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  // Combine streams to rebuild on any change
  final accountsStream = accountsRepo.watchAllAccounts();
  final transactionChanges = transactionsRepo.watchTransactions();
  
  // We yield initially and then on every change
  await for (final _ in StreamGroup.merge([accountsStream, transactionChanges])) {
     final accounts = await accountsRepo.getAllAccounts();
     final List<AccountStats> list = [];
     for (final account in accounts) {
       final stats = await transactionsRepo.getAccountStats(account.id, account.openingBalance);
       final balance = stats['balance'] ?? 0;
       final income = stats['income'] ?? 0;
       final expense = stats['expense'] ?? 0;
       final reimbursed = stats['reimbursed'] ?? 0;

       // Logic: Net Spend = Expense - Reimbursed
       // Logic: Net Income = Income - Reimbursed (assuming Reimbursed is part of Income)
       // Wait, 'income' from 'getAccountStats' includes ALL income (including repayments).
       // So Net Income = Total Income - Reimbursed.
       // Net Expense = Total Expense - Reimbursed.
       
       list.add(AccountStats(
         account, 
         balance, 
         income, 
         expense, 
         income - reimbursed, 
         expense - reimbursed, 
         reimbursed
       ));
     }
     yield list;
  }
});
