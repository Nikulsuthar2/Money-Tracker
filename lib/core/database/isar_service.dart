import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';

class IsarService {
  static late Isar isar;

  static Future<void> openSchemas() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        AccountSchema,
        CategorySchema,
        TransactionSchema,
        SubscriptionSchema,
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
