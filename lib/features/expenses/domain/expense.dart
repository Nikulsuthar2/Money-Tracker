class Expense {
  int id = 0;
  int? transactionId;
  double totalAmount = 0.0;
  int? categoryId;
  String? note;
  DateTime date = DateTime.now();
  DateTime? createdAt;
}

class ExpenseSplit {
  int id = 0;
  int expenseId = 0;
  int personId = 0;
  double amount = 0.0;
}

class Settlement {
  int id = 0;
  int transactionId = 0;
  int fromPersonId = 0;
  int toPersonId = 0;
  double amount = 0.0;
  DateTime? createdAt;
}
