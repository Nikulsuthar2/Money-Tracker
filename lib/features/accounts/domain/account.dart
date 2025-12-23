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
}

enum AccountType {
  wallet,
  bank,
  cash,
  savings,
  salary,
  others
}
