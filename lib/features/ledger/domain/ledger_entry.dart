import 'package:isar/isar.dart';

part 'ledger_entry.g.dart';

@collection
class LedgerEntry {
  Id id = Isar.autoIncrement;

  // The economic meaning implies a connection to a physical transaction, 
  // but it's nullable because some entries (like internal adjustments) might not have a cash flow transaction yet,
  // or might be "Ledger-only" adjustments described in the prompt.
  @Index()
  int? transactionId;

  @Index()
  late int partyId;

  // Amount in base currency.
  // Positive usually means "credit" to the nature? 
  // Let's stick to the prompt's example:
  // ME EXPENSE 350 -> Expense of 350.
  // ME RECEIVABLE 300 -> Others owe me 300?? No wait.
  // The prompt says: "ME EXPENSE 350", "FRIEND RECEIVABLE 300".
  // Actually, standard Accounting:
  // Expense is Debit (+)
  // Asset (Receivable) is Debit (+)
  // Liability (Payable) is Credit (-)
  // 
  // However, the prompt uses signedness in "Net Spend" calculation:
  // Outstanding = SUM(RECEIVABLE) - SUM(PAYABLE) - SUM(SETTLEMENT)
  // 
  // Let's store absolute amounts here and let the Nature dictate the sign in logic.
  double amount = 0.0;

  @Enumerated(EnumType.name)
  late LedgerNature nature;

  @Index()
  int? categoryId;

  String? note;
  
  @Index()
  late DateTime date; // For querying ledger history independently of transactions
}

enum LedgerNature {
  owe,     // Creates Obligation (I owe them, or They owe me). Direction decided by Amount sign or Party?
           // Convention: 
           // If Party is "Friend":
           // - Positive Amount + OWE = Friend Owes Me?
           // - Negative Amount + OWE = I Owe Friend?
           // Let's follow Prompt: "P1 OWE ME 100"
           // Entry stores: Party=P1, Nature=OWE, Amount=100. (Positive = They owe me).
           // If I owe P1? Party=P1, Nature=OWE, Amount=-100.
  
  paid,    // Resolves Obligation (Settlement).
           // If Party=P1, Nature=PAID, Amount=100 (They paid me).
           // If Party=P1, Nature=PAID, Amount=-100 (I paid them).
           
  internal // For Buckets / Reserved (Non-Ledger / Self)
}
