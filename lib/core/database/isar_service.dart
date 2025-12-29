import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';

class IsarService {
  static late Isar isar;

  // Instance getter for Dependency Injection / Mocking purposes
  Future<Isar> get db async => isar;

  // Opens the Isar database with all the schemas.
  // This must be called before accessing any data.
  static Future<void> openSchemas() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        AccountSchema,
        CategorySchema,
        TransactionSchema,
        SubscriptionSchema,
        PartySchema,
        LedgerEntrySchema,
      ],
      directory: dir.path,
    );
  }
  static Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
