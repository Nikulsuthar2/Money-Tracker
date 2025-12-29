import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/core/database/isar_service.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(IsarService.isar);
});

final transactionsStreamProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAllTransactions();
});

final recentTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchRecentTransactions();
});

class TransactionsRepository {
  final Isar _isar;

  TransactionsRepository(this._isar);

  Stream<List<Transaction>> watchRecentTransactions() {
    return _isar.transactions.where().sortByDateDesc().limit(20).watch(fireImmediately: true);
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return _isar.transactions.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Stream<void> watchTransactions() {
    return _isar.transactions.watchLazy();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      final id = await _isar.transactions.put(transaction);
      transaction.id = id; // Ensure ID is set for linking
      
      // Ledger Logic: Generate Entries from Splits
      if (transaction.subTransactions != null) {
          final ledgerEntries = <LedgerEntry>[];
          
          for (final split in transaction.subTransactions!) {
             if (split.partyId != null) {
                 // Determine Nature
                 // Case T1: Expense, I Paid (Implicit in this flow), Split is for Friend.
                 // Friend Owes Me -> Receivable.
                 
                 LedgerNature? nature;
                 String note = split.note ?? 'Split Share';
                 
                 if (transaction.type == TransactionType.expense) {
                     if (!split.isMine) {
                        nature = LedgerNature.receivable;
                        note = 'Owed to Me for ${transaction.title}';
                     }
                 }
                 // TODO: Handle Income/Settlement cases later
                 
                 if (nature != null) {
                    ledgerEntries.add(LedgerEntry()
                       ..transactionId = id
                       ..partyId = split.partyId!
                       ..amount = split.amount
                       ..nature = nature
                       ..date = transaction.date
                       ..note = note
                       ..categoryId = split.categoryId
                    );
                 }
             }
          }
          
          if (ledgerEntries.isNotEmpty) {
             await _isar.ledgerEntrys.putAll(ledgerEntries);
             transaction.hasLedgerEntries = true;
             await _isar.transactions.put(transaction); // Update flag
          }
      }
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<void> deleteTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.delete(id);
    });
  }
  
  Future<Transaction?> getTransaction(Id id) async {
    return await _isar.transactions.get(id);
  }
  
  // Balance Calculation Logic
  Future<double> getAccountBalance(Id accountId, double openingBalance) async {
    final income = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.income)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final expense = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.expense)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    final transferOut = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final transferIn = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    return openingBalance + income - expense - transferOut + transferIn;
  }

  Future<void> revertRefund(Id refundTransactionId) async {
    await _isar.writeTxn(() async {
      final refundTxn = await _isar.transactions.get(refundTransactionId);
      if (refundTxn != null && refundTxn.relatedTransactionId != null) {
         final originalTxn = await _isar.transactions.get(refundTxn.relatedTransactionId!);
         if (originalTxn != null) {
            originalTxn.isRefunded = false;
            await _isar.transactions.put(originalTxn);
         }
      }
      await _isar.transactions.delete(refundTransactionId);
    });
  }

  Future<void> revertRefundForOriginal(Id originalTransactionId) async {
    await _isar.writeTxn(() async {
       // Find the refund transaction (the one that points to this original)
       final refundTxn = await _isar.transactions
           .filter()
           .relatedTransactionIdEqualTo(originalTransactionId)
           .findFirst();
           
       if (refundTxn != null) {
          await _isar.transactions.delete(refundTxn.id);
       }
       
       final original = await _isar.transactions.get(originalTransactionId);
       if (original != null) {
         original.isRefunded = false;
         if (original.subTransactions != null) {
            // Need to create new list or iterate? Isar embedded objects are mutable via the parent.
            // But we might need to re-assign the list if modifying elements doesn't trigger. 
            // Isar usually handles embedded modification if we put the parent.
            final updatedSplits = original.subTransactions!.map((s) {
               // s.isRefunded = false; // direct modify might not work if 's' is read-only view?
               // Safest to copy or modify
               s.isRefunded = false;
               return s;
            }).toList();
            original.subTransactions = updatedSplits;
         }
         await _isar.transactions.put(original); 
       }
    });
  }

  Future<Map<String, double>> getAccountStats(Id accountId, double openingBalance) async {
    final income = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.income)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final expense = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.expense)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    final transferOut = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .fromAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
        
    final transferIn = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.transfer)
        .and()
        .toAccountIdEqualTo(accountId)
        .amountProperty()
        .sum();
    
    // Calculate Reimbursed (Income linked to another txn)
    // Note: This relies on relatedTransactionId being set (New Feature).
    // For Backward compatibility, we could also check notes, but user wants new feature.
    final reimbursed = await _isar.transactions
        .filter()
        .skipFromStatsEqualTo(false)
        .typeEqualTo(TransactionType.income)
        .and()
        .toAccountIdEqualTo(accountId)
        .and()
        .relatedTransactionIdIsNotNull()
        .amountProperty()
        .sum();

    final totalBalance = openingBalance + income - expense - transferOut + transferIn;
    final totalIn = income + transferIn;
    final totalOut = expense + transferOut;

    return {
      'balance': totalBalance,
      'income': totalIn,
      'expense': totalOut,
      'reimbursed': reimbursed,
    };
  }

  Future<List<Transaction>> getRefundTransactions(Id originalId) async {
    return await _isar.transactions
        .filter()
        .relatedTransactionIdEqualTo(originalId)
        .findAll();
  }
  
  Future<List<LedgerEntry>> getLedgerEntries(Id transactionId) async {
    return await _isar.ledgerEntrys
        .filter()
        .transactionIdEqualTo(transactionId)
        .findAll();
  }
}
