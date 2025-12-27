import 'package:isar/isar.dart';

part 'account.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name;

  @Enumerated(EnumType.name)
  late AccountType type;

  double openingBalance = 0.0;
  
  // Note: Current balance is calculated, not stored, as per requirements.
  // But for performance, one might cache it. Use calculated property for now? 
  // Requirement says: "currentBalance (calculated)".
  // We can add a method to calculate it but that requires fetching all transactions.
  // For the list view, we might need a separate service or cache.

  int color = 0xFF2196F3; // Default blue

  int icon = 57522; // Default icon codepoint (e.g. wallet)

  bool isArchived = false;
  
  // Amount set aside as Savings (not to be spent freely)
  // "Reserved Saving" in user terms - Manual lock
  // "Reserved Saving" in user terms - Manual lock or filled by priority logic
  double reservedBalance = 0.0;
  
  // New: Limit for Reserved bucket. If income comes, fills this up to limit.
  double reservedLimit = 0.0;
  
  // Dynamic Custom Buckets
  List<AccountBucket> buckets = [];

  // Auto-Savings Configuration
  bool autoSaveEnabled = false;
  int? autoSaveTargetAccountId;
  double autoSaveAmount = 0.0; 
  bool autoSaveIsPercentage = true; 
  
  // Pivot Logic:
  // "Spendable (default all balance - all categories)"
  // Since we don't store currentBalance on the model (it's calculated), we need to pass currentBalance.
  // BUT the UI needs to know spendable.
  // We'll calculate spendable in the UI/Logic layer by (currentBalance - reserved - savings - investment).
}

enum AccountType {
  wallet,
  bank,
  cash,
  savings,
  salary,
  others
}

@embedded
class AccountBucket {
  String? name;
  double balance = 0.0;
  
  // Could add more fields like target, icon, etc. later
}
