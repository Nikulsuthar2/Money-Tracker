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
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isSettlement => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ExpenseData')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().nullable()();
  RealColumn get totalAmount => real()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get note => text().nullable()();
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
      },
    );
  }
}
