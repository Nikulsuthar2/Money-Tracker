import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/expenses/domain/expense.dart';

sealed class TimelineEntry {
  final DateTime date;
  TimelineEntry(this.date);
}

class TransactionTimelineEntry extends TimelineEntry {
  final Transaction transaction;
  final List<Expense> expenses;
  final Map<int, List<ExpenseSplit>> splits;
  
  TransactionTimelineEntry({
    required this.transaction,
    required this.expenses,
    required this.splits,
  }) : super(transaction.date);
}

class ExpenseOnlyTimelineEntry extends TimelineEntry {
  final List<Expense> expenses; // The logical grouping of an event where someone else paid
  final Map<int, List<ExpenseSplit>> splits;
  
  ExpenseOnlyTimelineEntry({
    required this.expenses,
    required this.splits,
  }) : super(expenses.isNotEmpty ? expenses.first.date : DateTime.now());
}

class SettlementTimelineEntry extends TimelineEntry {
  final Settlement settlement;
  
  SettlementTimelineEntry({
    required this.settlement,
  }) : super(settlement.createdAt ?? DateTime.now()); // Need to make sure Settlement has a date
}
