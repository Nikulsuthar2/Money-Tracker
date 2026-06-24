import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/accounts/data/investment_holdings_repository.dart';

import 'package:money_manager/features/goals/data/goals_repository.dart';

class AccountStats {
  final Account account;
  final double balance;
  final double spendableBalance;
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final double netExpense;
  final double reimbursed;
  
  // Custom metrics based on AccountType
  final double totalContributionToNetWorth;
  final double pl;
  final double investedBalance;

  AccountStats(this.account, this.balance, this.spendableBalance, this.totalIncome, this.totalExpense, this.netIncome, this.netExpense, this.reimbursed, this.totalContributionToNetWorth, this.pl, this.investedBalance);
}

final accountsWithBalanceProvider = StreamProvider.autoDispose<List<AccountStats>>((ref) async* {
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);
  final goalsRepo = ref.watch(goalsRepositoryProvider);
  final investmentHoldingsRepo = ref.watch(investmentHoldingsRepositoryProvider);

  // Combine streams to rebuild on any change
  final accountsStream = accountsRepo.watchAllAccounts();
  final transactionChanges = transactionsRepo.watchTransactions();
  final goalContributionsChanges = goalsRepo.watchAllGoalContributions();
  final holdingsChanges = investmentHoldingsRepo.watchAllHoldings();
  
  // We yield initially and then on every change
  await for (final _ in StreamGroup.merge([accountsStream, transactionChanges, goalContributionsChanges, holdingsChanges])) {
     final accounts = await accountsRepo.getAllAccounts();
     final List<AccountStats> list = [];
     for (final account in accounts) {
       final stats = await transactionsRepo.getAccountMonthlyStats(account.id, account.openingBalance, DateTime.now());
       final balance = stats['balance'] ?? 0;
       final income = stats['income'] ?? 0;
       final expense = stats['expense'] ?? 0;
       final reimbursed = stats['reimbursed'] ?? 0;

       final goalContributions = await goalsRepo.getTotalContributionsForAccount(account.id);
       
       double spendableBalance = 0;
       double totalContributionToNetWorth = 0;
       double pl = 0;
       double investedBalance = 0;

       if (!account.isCash) {
         final holdings = await investmentHoldingsRepo.getAccountHoldings(account.id);
         investedBalance = holdings.fold(0.0, (sum, item) => sum + (item.quantity * item.averageBuyPrice));
       }

       if (account.isCash) {
         spendableBalance = balance - account.reservedBalance - goalContributions;
         totalContributionToNetWorth = balance;
       } else if (account.isAsset) {
         pl = account.interestRate ?? 0;
         totalContributionToNetWorth = balance + investedBalance + (investedBalance * pl / 100);
       } else if (account.isLiability) {
         pl = account.interestRate ?? 0;
         totalContributionToNetWorth = -(balance + investedBalance + (investedBalance * pl / 100));
       }
       
       list.add(AccountStats(
         account, 
         balance, 
         spendableBalance,
         income, 
         expense, 
         income - reimbursed, 
         expense - reimbursed, 
         reimbursed,
         totalContributionToNetWorth,
         pl,
         investedBalance
       ));
     }
     yield list;
  }
});
