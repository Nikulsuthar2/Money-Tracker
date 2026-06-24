class Account {
  int id = 0;
  String name = '';
  AccountType type = AccountType.cash;
  String currency = 'INR';
  double initialBalance = 0.0;
  double reservedBalance = 0.0;
  bool isArchived = false;
  int color = 0xFF2196F3;
  String iconData = 'material:57522'; // Default wallet icon
  double currentValue = 0.0;
  double? interestRate; // Used for Interest Rate or P/L
  DateTime? createdAt;
  DateTime? updatedAt;

  bool get isAsset => type == AccountType.investment || type == AccountType.pf;
  bool get isLiability => type == AccountType.loan || type == AccountType.creditCard;
  bool get isCash => !isAsset && !isLiability;

  // --- Legacy UI Stubs (to be removed safely later) ---
  double get openingBalance => initialBalance;
  set openingBalance(double v) => initialBalance = v;
}

enum AccountType {
  cash,
  bank,
  creditCard,
  pf,
  investment,
  loan,
  eWallet,
  other
}
