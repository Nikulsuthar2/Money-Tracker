import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

@DataClassName('AccountData')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, bank, creditCard, etc.
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get reservedBalance => real().withDefault(const Constant(0.0))();
  RealColumn get interestRate => real().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFF2196F3))();
  TextColumn get iconData => text().withDefault(const Constant('material:57522'))();
  RealColumn get currentValue => real().withDefault(const Constant(0.0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('CategoryData')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income, expense, common
  IntColumn get icon => integer()();
  IntColumn get color => integer()();
  TextColumn get iconData => text().withDefault(const Constant('material:57522'))();
}

@DataClassName('PersonData')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('TransactionData')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // expense, income, transfer
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  IntColumn get fromAccountId => integer().nullable()();
  IntColumn get toAccountId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isSettlement => boolean().withDefault(const Constant(false))();
  RealColumn get principalAmount => real().nullable()(); // Added for investment sells
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('InvestmentHoldingData')
class InvestmentHoldings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer()();
  TextColumn get symbol => text()();
  TextColumn get type => text().withDefault(const Constant('Equity'))(); // e.g., Equity, ETF, Index, Commodity
  RealColumn get quantity => real()();
  RealColumn get averageBuyPrice => real()();
  RealColumn get currentPrice => real()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ExpenseData')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().nullable()();
  RealColumn get totalAmount => real()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get paidByPersonId => integer().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('ExpenseSplitData')
class ExpenseSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get expenseId => integer()();
  IntColumn get personId => integer()();
  RealColumn get amount => real()();
}

@DataClassName('SettlementData')
class Settlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer()();
  IntColumn get fromPersonId => integer()();
  IntColumn get toPersonId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime()();
}


@DataClassName('BudgetAllocationData')
class BudgetAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get periodType => text()(); // weekly, monthly, yearly
  TextColumn get periodKey => text()(); // e.g. "2026-06" for Monthly, "2026-W24" for Weekly
  RealColumn get amount => real()();
}

@DataClassName('AssetItemData')
class AssetItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // e.g., real estate, vehicle, jewelry, etc.
  RealColumn get value => real()();
  TextColumn get iconData => text().withDefault(const Constant('material:57522'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF2196F3))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('GoalData')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // saving, debtRepayment, purchase, retirement, other
  TextColumn get name => text()();
  TextColumn get iconData => text()();
  IntColumn get color => integer()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get frequency => text().nullable()();

  RealColumn get totalDebt => real().nullable()();
  RealColumn get remainingBalance => real().nullable()();
  RealColumn get interestRate => real().nullable()();
  RealColumn get minimumPayment => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('GoalContributionData')
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  IntColumn get accountId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
}

@DataClassName('BudgetData')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer()(); // Linked to category
  RealColumn get amount => real()(); // Budget limit
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // 'weekly', 'monthly', 'yearly'
  DateTimeColumn get startDate => dateTime().nullable()(); // Optional custom start date
  DateTimeColumn get createdAt => dateTime()();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [
  Accounts,
  Categories,
  People,
  Transactions,
  Expenses,
  ExpenseSplits,
  Settlements,
  Goals,
  GoalContributions,
  InvestmentHoldings,
  Budgets,
  BudgetAllocations,
  AssetItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(accounts, accounts.interestRate);
          await m.addColumn(accounts, accounts.color);
          await m.addColumn(accounts, accounts.iconData);
        }
        if (from < 3) {
          await m.addColumn(categories, categories.iconData);
        }
        if (from < 4) {
          await m.createTable(goals);
          await m.createTable(goalContributions);
        }
        if (from < 5) {
          await m.addColumn(goals, goals.minimumPayment);
        }
        if (from < 6) {
          await m.addColumn(accounts, accounts.currentValue);
        }
        if (from < 7) {
          await m.createTable(investmentHoldings);
          await m.addColumn(transactions, transactions.principalAmount);
        }
        if (from < 8) {
          await m.addColumn(expenses, expenses.paidByPersonId);
        }
        if (from < 9) {
          await m.addColumn(transactions, transactions.title);
        }
        if (from < 10) {
          await m.createTable(budgets);
        }
        if (from < 11) {
          await m.createTable(budgetAllocations);
        }
        if (from < 12) {
          await m.addColumn(investmentHoldings, investmentHoldings.type);
        }
        if (from < 13) {
          await m.createTable(assetItems);
        }
      },
    );
  }

  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(accounts).go();
      await delete(categories).go();
      await delete(people).go();
      await delete(transactions).go();
      await delete(expenses).go();
      await delete(expenseSplits).go();
      await delete(settlements).go();
      await delete(goals).go();
      await delete(goalContributions).go();
      await delete(investmentHoldings).go();
      await delete(budgets).go();
      await delete(assetItems).go();
    });
  }

  Future<File> get dbFile async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return File(p.join(dbFolder.path, 'app.db'));
  }
}
