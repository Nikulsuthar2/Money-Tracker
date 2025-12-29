import 'package:isar/isar.dart';
import '../../../core/database/isar_service.dart';
import '../domain/party.dart';
import '../domain/ledger_entry.dart';
import '../../transactions/domain/transaction.dart' as model; // Alias to avoid conflict

class LedgerService {
  final IsarService _isarService;

  LedgerService(this._isarService);

  // 1. Get Outstanding Balance for a Party
  // Formula: SUM(RECEIVABLE) - SUM(PAYABLE) - SUM(SETTLEMENT)
  // Wait, the prompt says:
  // "Outstanding = SUM(RECEIVABLE) - SUM(PAYABLE) - SUM(SETTLEMENT)"
  // Let's interpret "Settlement":
  // If I paid someone to settle, that's a SETTLEMENT entry for THEM?
  // Let's look at the scenario:
  // Transaction 2 - Settlement IN 240
  // Ledger: FRIEND SETTLEMENT 300, ME SETTLEMENT -60 (No, ME SETTLEMENT -60 is weird, usually Settlement is positive for the payer?)
  // Let's re-read carefully: "Friend settles by paying 240".
  // Ledger: FRIEND SETTLEMENT 300.
  // Friend owed 300. Paying 300 reduces debt.
  // So: RECEIVABLE (positive, they owe me) - SETTLEMENT (they paid me) = Remaining Receivable.
  
  // Implementation:
  // We need to query LedgerEntries for a given partyId.
  Future<double> getOutstandingBalance(int partyId) async {
    final isar = await _isarService.db;
    
    final entries = await isar.ledgerEntrys
        .filter()
        .partyIdEqualTo(partyId)
        .findAll();

    double receivable = 0;
    double payable = 0;
    double settlement = 0;

    for (var entry in entries) {
      switch (entry.nature) {
        case LedgerNature.receivable:
          receivable += entry.amount;
          break;
        case LedgerNature.payable:
          payable += entry.amount;
          break;
        case LedgerNature.settlement:
          // The prompt is slightly ambiguous on "Settlement" sign.
          // Usually Settlement reduces the balance.
          // "Friend settles by paying 240". Entry: FRIEND SETTLEMENT 300.
          // If Receiving 300 from Friend (receivable was 300).
          // Result should be 0.
          // So Outstanding = Receivable - Settlement. (If settlement is +)
          // What if I pay them? I had Payable. I pay. Settlement.
          // Outstanding (My Debt) = Payable - Settlement.
          
          // Let's assume standardized direction:
          // If I am tracking "Net Balance" of a Party (Positive = They owe me, Negative = I owe them).
          // Receivable: +
          // Payable: -
          // Settlement? 
          // If Friend Pays me (Settlement), it reduces Receivable (-).
          // If I Pay Friend (Settlement), it reduces Payable (+ to move towards 0).
          
          // Actually, the LedgerEntry doesn't assume WHO paid in the entry itself, just "Settlement".
          // We might need to know the context or direction.
          // OR, we use Signed amounts in the DB?
          // Prompt says "Transaction IN 240".
          // "Friend settles".
          // If we stick to Prompt's formula: "Outstanding = SUM(RECEIVABLE) - SUM(PAYABLE) - SUM(SETTLEMENT)"
          // This implies Settlement ALWAYS reduces the dominant balance?
          // Or maybe Settlement has a sign?
          
          // Let's look at the example result:
          // Shopping: ME EXPENSE 350. FRIEND RECEIVABLE 300.
          // Friend pays Auto: ME PAYABLE 60. FRIEND EXPENSE 60.
          // Friend Settles: FRIEND SETTLEMENT 300. ME SETTLEMENT -60 ?? (Prompt says ME SETTLEMENT -60)
          
          // Wait, "Transaction 2 - Settlement IN 240".
          // Friend owed 300. Friend paid for ME (60). Net Friend owes 240.
          // Friend pays 240.
          // Ledger entries: FRIEND SETTLEMENT 300 (Clears Receivable). ME SETTLEMENT -60 (Clears Payable?)
          
          // If Formula is strict:
          // Friend: Receivable(300) - Payable(0) - Settlement(300) = 0. Correct.
          // Me: Receivable(0) - Payable(60) - Settlement(-60) = 0. Correct.
          
          // So Settlement amount CAN be negative if it's clearing a Payable for "Me"? 
          // Or strictly: The formula is for THE party.
          // Friend Party:
          // Receivable: 300.
          // Payment: 240 cash.
          // But wait, the Settlement Entry is 300?
          // Yes, because 60 was offset?
          
          // This implies the "Settlement" entry value is calculated to clear the balance, NOT just the cash amount.
          // This is the "Economic Meaning".
          
          settlement += entry.amount; 
          break;
          
        default:
          break;
      }
    }

    return receivable - payable - settlement;
  }
  
  Future<List<LedgerEntry>> getLedgerEntriesForParty(int partyId) async {
    final isar = await _isarService.db;
    return await isar.ledgerEntrys
        .filter()
        .partyIdEqualTo(partyId)
        .findAll();
  }
  
  // 2. Record Transaction with Ledger Entries
  Future<void> recordTransaction({
    required model.Transaction transaction,
    required List<LedgerEntry> entries,
  }) async {
    final isar = await _isarService.db;

    await isar.writeTxn(() async {
      // 1. Save Transaction (Physical Cash Flow)
      await isar.transactions.put(transaction); 
      
      // 2. Save Ledger Entries (Economic Meaning)
      for (var entry in entries) {
        entry.transactionId = transaction.id; // Link them
        await isar.ledgerEntrys.put(entry);
      }
    });
  }

  // 3. Record Economic Event (No self-cash-flow, e.g. Friend pays)
  Future<void> recordEconomicEvent({
    required List<LedgerEntry> entries,
    model.Transaction? transaction, // Optional: If we want to store a "Shadow Transaction" or just link to existing
  }) async {
    final isar = await _isarService.db;

    await isar.writeTxn(() async {
      if (transaction != null) {
         await isar.transactions.put(transaction);
         for (var entry in entries) {
            entry.transactionId = transaction.id;
         }
      }
      
      for (var entry in entries) {
        await isar.ledgerEntrys.put(entry);
      }
    });
  }
}
