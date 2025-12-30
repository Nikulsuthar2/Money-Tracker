import 'package:isar/isar.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  double amount = 0.0;

  @Enumerated(EnumType.name)
  late TransactionType type; // Keeping for backward compatibility & high-level cat? Or should Mode replace Type?
  // User Prompt: "Transaction must be either Split Mode or Ledger Mode".
  // Realistically: 
  // - Expense (Split Mode) -> Type: expense
  // - Settlement (Ledger Mode) -> Type: expense OR income (depending on direction)
  // - Income -> Type: income
  // Let's keep Type for Accounting (Income/Expense/Transfer) and use Mode for "Behavior" (Standard/Split vs Settlement).
  
  @Enumerated(EnumType.name)
  TransactionMode mode = TransactionMode.regular; // default

  @Index()
  int? fromAccountId;

  // Used for Transfer (destination) and Income (destination)
  @Index()
  int? toAccountId;

  @Index()
  int? categoryId;

  String? note;
  String? title;

  @Index()
  late DateTime date;

  bool isRecurring = false;
  
  // For subscriptions tracking?
  int? subscriptionId;

  List<SubTransaction>? subTransactions;

  bool skipFromStats = false;
  bool hasTime = true;
  
  bool isRefunded = false;

  @Index()
  int? relatedTransactionId;

  // Ledger V2 Compatibility
  bool hasLedgerEntries = false;
}

@embedded
class SubTransaction {
  double amount = 0.0;
  String? note;
  
  // Each split can have its own category
  int? categoryId;

  // Is this split my personal expense?
  bool isMine = true;

  // Link to a Party (for Ledger)
  int? partyId;

  bool isRefunded = false;
}

enum TransactionType {
  income,
  expense,
  transfer
}

enum TransactionMode {
  regular, // Standard Income/Expense (can have splits if Expense)
  settlement, // Debt Resolution (No splits, specific Ledger logic)
}
