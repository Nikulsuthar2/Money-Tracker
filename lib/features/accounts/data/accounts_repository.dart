import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(ref.watch(databaseProvider));
});

final accountsStreamProvider = StreamProvider((ref) {
  return ref.watch(accountsRepositoryProvider).watchAllAccounts();
});

extension AccountDataMapper on AccountData {
  Account toDomain() {
    return Account()
      ..id = id
      ..name = name
      ..type = AccountType.values.firstWhere((e) => e.name == type)
      ..currency = currency
      ..initialBalance = initialBalance
      ..reservedBalance = reservedBalance
      ..interestRate = interestRate
      ..color = color
      ..iconData = iconData
      ..currentValue = currentValue
      ..isArchived = isArchived
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

class AccountsRepository {
  final AppDatabase _db;

  AccountsRepository(this._db);

  Future<List<Account>> getAllAccounts() async {
    final list = await _db.select(_db.accounts).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Stream<List<Account>> watchAllAccounts() {
    return _db.select(_db.accounts).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }
  
  Stream<List<Account>> watchActiveAccounts() {
    return (_db.select(_db.accounts)..where((a) => a.isArchived.equals(false)))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<void> addAccount(Account account) async {
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
      name: account.name,
      type: account.type.name,
      currency: drift.Value(account.currency),
      initialBalance: drift.Value(account.initialBalance),
      reservedBalance: drift.Value(account.reservedBalance),
      interestRate: drift.Value(account.interestRate),
      color: drift.Value(account.color),
      iconData: drift.Value(account.iconData),
      currentValue: drift.Value(account.currentValue),
      isArchived: drift.Value(account.isArchived),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateAccount(Account account) async {
    await _db.update(_db.accounts).replace(AccountData(
      id: account.id,
      name: account.name,
      type: account.type.name,
      currency: account.currency,
      initialBalance: account.initialBalance,
      reservedBalance: account.reservedBalance,
      interestRate: account.interestRate,
      color: account.color,
      iconData: account.iconData,
      currentValue: account.currentValue,
      isArchived: account.isArchived,
      createdAt: account.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteAccount(int id) async {
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
  }
  
  Future<void> archiveAccount(int id) async {
    final accountData = await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
    if (accountData != null) {
      final updated = accountData.copyWith(isArchived: true, updatedAt: DateTime.now());
      await _db.update(_db.accounts).replace(updated);
    }
  }
}
