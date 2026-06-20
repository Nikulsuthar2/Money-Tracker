class Account {
  int id = 0;
  String name = '';
  AccountType type = AccountType.wallet;
  String currency = 'INR';
  double initialBalance = 0.0;
  double reservedBalance = 0.0;
  double reservedLimit = 0.0;
  bool isArchived = false;
  int color = 0xFF2196F3;
  int icon = 57522;
  DateTime? createdAt;
  DateTime? updatedAt;

  // --- Legacy UI Stubs ---
  double get openingBalance => initialBalance;
  set openingBalance(double v) => initialBalance = v;
  List<AccountBucket> buckets = [];
  bool autoSaveEnabled = false;
  int? autoSaveTargetAccountId;
  double autoSaveAmount = 0.0; 
  bool autoSaveIsPercentage = true; 
}

enum AccountType {
  wallet,
  bank,
  cash,
  savings,
  salary,
  others
}

class AccountBucket {
  String? name;
  double balance = 0.0;
}
