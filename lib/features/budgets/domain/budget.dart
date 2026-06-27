class Budget {
  int id = 0;
  int categoryId = 0;
  double amount = 0.0;
  BudgetPeriod period = BudgetPeriod.monthly;
  DateTime? startDate;
  DateTime createdAt = DateTime.now();

  // For UI convenience
  String categoryName = '';
  int categoryColor = 0xFF2196F3;
  String categoryIconData = 'material:57522';
}

enum BudgetPeriod {
  weekly,
  monthly,
  yearly
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get name {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }
}

BudgetPeriod parseBudgetPeriod(String period) {
  switch (period) {
    case 'weekly':
      return BudgetPeriod.weekly;
    case 'yearly':
      return BudgetPeriod.yearly;
    case 'monthly':
    default:
      return BudgetPeriod.monthly;
  }
}
