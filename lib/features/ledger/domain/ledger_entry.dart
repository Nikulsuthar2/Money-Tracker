class LedgerEntry {
  int id = 0;
  double amount = 0.0;
  String note = '';
  DateTime date = DateTime.now();
  int? partyId;
  int? transactionId;
  LedgerNature nature = LedgerNature.owe;
  int? categoryId;
  int sortOrder = 0;
}

enum LedgerNature { paid, owe }
