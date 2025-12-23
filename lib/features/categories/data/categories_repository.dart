import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/core/database/isar_service.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(IsarService.isar);
});

class CategoriesRepository {
  final Isar _isar;

  CategoriesRepository(this._isar);

  Stream<List<Category>> watchAllCategories() {
    return _isar.categorys.where().watch(fireImmediately: true);
  }
  
  Stream<List<Category>> watchIncomeCategories() {
    return _isar.categorys.filter().typeEqualTo(CategoryType.income).watch(fireImmediately: true);
  }
  
  Stream<List<Category>> watchExpenseCategories() {
    return _isar.categorys.filter().typeEqualTo(CategoryType.expense).watch(fireImmediately: true);
  }

  Future<void> addCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> updateCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(id);
    });
  }

  Future<void> seedDefaultCategories() async {
    final count = await _isar.categorys.count();
    if (count == 0) {
      final defaultCategories = [
        // Income
        Category()..name = 'Salary'..type = CategoryType.income..icon = 57522, // wallet
        Category()..name = 'Business'..type = CategoryType.income..icon = 58120, // business
        Category()..name = 'Investment'..type = CategoryType.income..icon = 58535, // trending_up
        Category()..name = 'Gift'..type = CategoryType.income..icon = 57526, // card_giftcard
        Category()..name = 'Refund'..type = CategoryType.income..icon = 58667, // restore
        Category()..name = 'Money Back'..type = CategoryType.income..icon = 57361, // attach_money
        
        // Expense
        Category()..name = 'Food'..type = CategoryType.expense..icon = 57946, // restaurant
        Category()..name = 'Transport'..type = CategoryType.expense..icon = 58673, // directions_bus
        Category()..name = 'Shopping'..type = CategoryType.expense..icon = 58694, // shopping_cart
        Category()..name = 'Entertainment'..type = CategoryType.expense..icon = 58309, // movie
        Category()..name = 'Bills'..type = CategoryType.expense..icon = 58632, // receipt
        Category()..name = 'Education'..type = CategoryType.expense..icon = 58723, // school
        Category()..name = 'Health'..type = CategoryType.expense..icon = 58345, // local_hospital
      ];
      await _isar.writeTxn(() async {
        await _isar.categorys.putAll(defaultCategories);
      });
    }
  }
}
