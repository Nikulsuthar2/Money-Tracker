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

  @Index()
  late DateTime date;

  bool isRecurring = false;
  
  // For subscriptions tracking?
  int? subscriptionId;

  List<SubTransaction>? subTransactions;

  bool skipFromStats = false;
  bool hasTime = true;
}

@embedded
class SubTransaction {
  double amount = 0.0;
  String? note;
  
  // Each split can have its own category
  int? categoryId;

  // Is this split my personal expense?
  bool isMine = true;
}

enum TransactionType {
  income,
  expense,
  transfer
}
