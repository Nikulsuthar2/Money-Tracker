import 'package:isar/isar.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  double amount = 0.0;

  @Enumerated(EnumType.name)
  late TransactionType type;

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
