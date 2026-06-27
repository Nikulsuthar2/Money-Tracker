import 'package:money_manager/features/budgets/domain/budget.dart';

class BudgetAllocation {
  int id = 0;
  BudgetPeriod periodType = BudgetPeriod.monthly;
  String periodKey = '';
  double amount = 0.0;
}
