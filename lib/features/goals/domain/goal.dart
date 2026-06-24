enum GoalType {
  saving,
  debtRepayment,
  purchase,
  retirement,
  other
}

class Goal {
  int id = 0;
  GoalType type = GoalType.saving;
  String name = '';
  String iconData = 'emoji:🎯';
  int color = 0xFF2196F3;
  double targetAmount = 0.0;
  double currentAmount = 0.0; // Cached from contributions
  DateTime? startDate;
  DateTime? endDate;
  String? frequency; // flexible, daily, weekly, bi-weekly, monthly

  // Debt specific fields
  double? totalDebt;
  double? remainingBalance;
  double? interestRate;
  double? minimumPayment;

  DateTime? createdAt;
  DateTime? updatedAt;
}
