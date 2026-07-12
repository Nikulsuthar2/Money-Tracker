class Transaction {
  int id = 0;
  double amount = 0.0;
  String currency = 'INR';
  TransactionType type = TransactionType.expense;
  int? fromAccountId;
  int? toAccountId;
  int? categoryId;
  String? note;
  DateTime date = DateTime.now();
  bool isSettlement = false;
  double? principalAmount;
  DateTime? createdAt;
  DateTime? updatedAt;

  // --- Legacy UI Stubs ---
  String? title;
  List<dynamic>? subTransactions;
  bool hasTime = true;
  bool skipFromStats = false;
  bool isRefunded = false;
  int? relatedTransactionId;
  bool hasLedgerEntries = false;
  TransactionMode mode = TransactionMode.regular;

  double get effectiveAmount {
    if (subTransactions != null && subTransactions!.isNotEmpty) {
      double myAmount = 0;
      for (var sub in subTransactions!) {
        if (sub is SubTransaction && sub.isMine) {
          myAmount += sub.amount;
        } else if (sub is Map) {
          if (sub['isMine'] == true) {
             myAmount += (sub['amount'] as num).toDouble();
          }
        } else if (sub.runtimeType.toString() == 'SubTransaction' || sub.runtimeType.toString() == 'SubTransactionItem') {
           try {
             if (sub.isMine == true) myAmount += (sub.amount as num).toDouble();
           } catch (_) {}
        }
      }
      return myAmount;
    }
    return amount;
  }
}

enum TransactionType {
  income,
  expense,
  transfer,
  buyInvestment,
  sellInvestment
}

enum TransactionMode { regular, settlement }

class SubTransaction {
  double amount = 0.0;
  String? note;
  int? categoryId;
  bool isMine = true;
  int? partyId;
  bool isRefunded = false;
}
