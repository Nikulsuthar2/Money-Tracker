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

    double owe = 0;
    double paid = 0;

    for (var entry in entries) {
      switch (entry.nature) {
        case LedgerNature.owe:
          owe += entry.amount;
          break;
        case LedgerNature.paid:
          paid += entry.amount;
          break;
        default:
          break;
      }
    }

    return owe - paid;
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


  // 4. Watch All Entries (For Global Page)
  Stream<List<LedgerEntry>> watchAllLedgerEntries() async* {
    final isar = await _isarService.db;
    yield* isar.ledgerEntrys.where().sortBySortOrder().thenByDateDesc().watch(fireImmediately: true);
  }


  Future<void> updateLedgerEntry(LedgerEntry entry) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.ledgerEntrys.put(entry);
    });
  }

  Future<void> updateLedgerEntries(List<LedgerEntry> entries) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.ledgerEntrys.putAll(entries);
    });
  }


  Future<void> deleteLedgerEntry(int id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.ledgerEntrys.delete(id);
    });
  }
}
