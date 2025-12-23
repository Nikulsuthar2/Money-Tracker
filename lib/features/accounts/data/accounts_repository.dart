import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/core/database/isar_service.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(IsarService.isar);
});

class AccountsRepository {
  final Isar _isar;

  AccountsRepository(this._isar);

  Future<List<Account>> getAllAccounts() async {
    return _isar.accounts.where().findAll();
  }

  Stream<List<Account>> watchAllAccounts() {
    return _isar.accounts.where().watch(fireImmediately: true);
  }
  
  Stream<List<Account>> watchActiveAccounts() {
    return _isar.accounts.filter().isArchivedEqualTo(false).watch(fireImmediately: true);
  }

  Future<void> addAccount(Account account) async {
    await _isar.writeTxn(() async {
      await _isar.accounts.put(account);
    });
  }

  Future<void> updateAccount(Account account) async {
    await _isar.writeTxn(() async {
      await _isar.accounts.put(account);
    });
  }

  Future<void> deleteAccount(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.accounts.delete(id);
    });
  }
  
  Future<void> archiveAccount(Id id) async {
    final account = await _isar.accounts.get(id);
    if (account != null) {
      account.isArchived = true;
      await updateAccount(account);
    }
  }
}
