import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

extension CategoryDataMapper on CategoryData {
  Category toDomain() {
    return Category()
      ..id = id
      ..name = name
      ..type = CategoryType.values.firstWhere((e) => e.name == type)
      ..color = color
      ..icon = icon
      ..iconData = iconData;
  }
}

class CategoriesRepository {
  final AppDatabase _db;

  CategoriesRepository(this._db);

  Stream<List<Category>> watchAllCategories() {
    return _db.select(_db.categories).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }
  
  Stream<List<Category>> watchIncomeCategories() {
    return (_db.select(_db.categories)..where((c) => c.type.equals('income') | c.type.equals('common')))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }
  
  Stream<List<Category>> watchExpenseCategories() {
    return (_db.select(_db.categories)..where((c) => c.type.equals('expense') | c.type.equals('common')))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<void> addCategory(Category category) async {
    await _db.into(_db.categories).insert(CategoriesCompanion.insert(
      name: category.name,
      type: category.type.name,
      color: category.color,
      icon: category.icon,
      iconData: drift.Value(category.iconData),
    ));
  }

  Future<void> updateCategory(Category category) async {
    await _db.update(_db.categories).replace(CategoryData(
      id: category.id,
      name: category.name,
      type: category.type.name,
      color: category.color,
      icon: category.icon,
      iconData: category.iconData,
    ));
  }

  Future<void> deleteCategory(int id) async {
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  Future<Category?> getCategory(int id) async {
    final data = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();
    return data?.toDomain();
  }

  Future<List<Category>> getAllCategories() async {
    final list = await _db.select(_db.categories).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<void> seedDefaultCategories() async {
    final list = await getAllCategories();
    if (list.isEmpty) {
      final defaultCategories = [
        // Expenses
        Category()..name = 'Food'..type = CategoryType.expense..iconData = 'emoji:🍔'..color = 0xFFFF9800,
        Category()..name = 'Restaurants'..type = CategoryType.expense..iconData = 'emoji:🍽️'..color = 0xFFFF5722,
        Category()..name = 'Snacks & Drinks'..type = CategoryType.expense..iconData = 'emoji:🥤'..color = 0xFFFFC107,
        Category()..name = 'Groceries'..type = CategoryType.expense..iconData = 'emoji:🛒'..color = 0xFF4CAF50,
        Category()..name = 'Transport'..type = CategoryType.expense..iconData = 'emoji:🚌'..color = 0xFF2196F3,
        Category()..name = 'Fuel'..type = CategoryType.expense..iconData = 'emoji:⛽'..color = 0xFF607D8B,
        Category()..name = 'Shopping'..type = CategoryType.expense..iconData = 'emoji:🛍️'..color = 0xFFE91E63,
        Category()..name = 'Clothing'..type = CategoryType.expense..iconData = 'emoji:👕'..color = 0xFF9C27B0,
        Category()..name = 'Electronics'..type = CategoryType.expense..iconData = 'emoji:📱'..color = 0xFF3F51B5,
        Category()..name = 'Home Items'..type = CategoryType.expense..iconData = 'emoji:🏠'..color = 0xFF795548,
        Category()..name = 'Healthcare'..type = CategoryType.expense..iconData = 'emoji:🏥'..color = 0xFFF44336,
        Category()..name = 'Medicines'..type = CategoryType.expense..iconData = 'emoji:💊'..color = 0xFFE57373,
        Category()..name = 'Fitness'..type = CategoryType.expense..iconData = 'emoji:🏋️'..color = 0xFF009688,
        Category()..name = 'Entertainment'..type = CategoryType.expense..iconData = 'emoji:🎉'..color = 0xFF9C27B0,
        Category()..name = 'Movies'..type = CategoryType.expense..iconData = 'emoji:🎬'..color = 0xFF673AB7,
        Category()..name = 'Games'..type = CategoryType.expense..iconData = 'emoji:🎮'..color = 0xFF3F51B5,
        Category()..name = 'Subscriptions'..type = CategoryType.expense..iconData = 'emoji:🔄'..color = 0xFF00BCD4,
        Category()..name = 'Education'..type = CategoryType.expense..iconData = 'emoji:🎓'..color = 0xFFFFC107,
        Category()..name = 'Books'..type = CategoryType.expense..iconData = 'emoji:📚'..color = 0xFFFF9800,
        Category()..name = 'Courses'..type = CategoryType.expense..iconData = 'emoji:💻'..color = 0xFF03A9F4,
        Category()..name = 'Travel'..type = CategoryType.expense..iconData = 'emoji:✈️'..color = 0xFF00BCD4,
        Category()..name = 'Hotels'..type = CategoryType.expense..iconData = 'emoji:🏨'..color = 0xFF009688,
        Category()..name = 'Rent'..type = CategoryType.expense..iconData = 'emoji:🔑'..color = 0xFF795548,
        Category()..name = 'Family'..type = CategoryType.expense..iconData = 'emoji:👪'..color = 0xFFFF5722,
        Category()..name = 'Gifts'..type = CategoryType.expense..iconData = 'emoji:🎁'..color = 0xFFE91E63,
        Category()..name = 'Insurance'..type = CategoryType.expense..iconData = 'emoji:🛡️'..color = 0xFF607D8B,
        Category()..name = 'Taxes'..type = CategoryType.expense..iconData = 'emoji:🧾'..color = 0xFF9E9E9E,
        Category()..name = 'Loan Payment'..type = CategoryType.expense..iconData = 'emoji:💳'..color = 0xFFF44336,
        Category()..name = 'Bills'..type = CategoryType.expense..iconData = 'emoji:🧾'..color = 0xFF607D8B,

        // Income
        Category()..name = 'Salary'..type = CategoryType.income..iconData = 'emoji:💰'..color = 0xFF4CAF50,
        Category()..name = 'Bonus'..type = CategoryType.income..iconData = 'emoji:🎊'..color = 0xFF8BC34A,
        Category()..name = 'Freelance'..type = CategoryType.income..iconData = 'emoji:💻'..color = 0xFF009688,
        Category()..name = 'Business Income'..type = CategoryType.income..iconData = 'emoji:🏢'..color = 0xFF3F51B5,
        Category()..name = 'Dividend'..type = CategoryType.income..iconData = 'emoji:📈'..color = 0xFF00BCD4,
        Category()..name = 'Interest'..type = CategoryType.income..iconData = 'emoji:🏦'..color = 0xFF03A9F4,
        Category()..name = 'Capital Gain'..type = CategoryType.income..iconData = 'emoji:💹'..color = 0xFF8BC34A,
        Category()..name = 'Refund'..type = CategoryType.income..iconData = 'emoji:🔙'..color = 0xFF9E9E9E,
        Category()..name = 'Cashback'..type = CategoryType.income..iconData = 'emoji:💸'..color = 0xFFFFC107,
        Category()..name = 'Gift Received'..type = CategoryType.income..iconData = 'emoji:🎁'..color = 0xFFE91E63,
        Category()..name = 'Other Income'..type = CategoryType.income..iconData = 'emoji:➕'..color = 0xFF757575,
        Category()..name = 'Money Back'..type = CategoryType.income..iconData = 'emoji:🤑'..color = 0xFF4CAF50,

        // Common
        Category()..name = 'Transfer'..type = CategoryType.common..iconData = 'emoji:🔄'..color = 0xFF2196F3,
        Category()..name = 'Adjustment'..type = CategoryType.common..iconData = 'emoji:⚖️'..color = 0xFF9E9E9E,
        Category()..name = 'Investment'..type = CategoryType.common..iconData = 'emoji:📈'..color = 0xFF4CAF50,
        Category()..name = 'Loan'..type = CategoryType.common..iconData = 'emoji:🤝'..color = 0xFFFF9800,
        Category()..name = 'Gift'..type = CategoryType.common..iconData = 'emoji:🎁'..color = 0xFFE91E63,
        Category()..name = 'Miscellaneous'..type = CategoryType.common..iconData = 'emoji:✨'..color = 0xFF607D8B,
      ];
      
      await _db.batch((batch) {
        batch.insertAll(_db.categories, defaultCategories.map((c) => CategoriesCompanion.insert(
          name: c.name,
          type: c.type.name,
          color: c.color,
          icon: c.icon,
          iconData: drift.Value(c.iconData),
        )));
      });
    }
  }
}
