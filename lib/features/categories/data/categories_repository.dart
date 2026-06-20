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
      ..icon = icon;
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
    ));
  }

  Future<void> updateCategory(Category category) async {
    await _db.update(_db.categories).replace(CategoryData(
      id: category.id,
      name: category.name,
      type: category.type.name,
      color: category.color,
      icon: category.icon,
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
        Category()..name = 'Salary'..type = CategoryType.income..icon = 57522,
        Category()..name = 'Business'..type = CategoryType.income..icon = 58120,
        Category()..name = 'Investment'..type = CategoryType.income..icon = 58535,
        Category()..name = 'Gift'..type = CategoryType.income..icon = 57526,
        Category()..name = 'Refund'..type = CategoryType.income..icon = 58667,
        Category()..name = 'Money Back'..type = CategoryType.income..icon = 57361,
        Category()..name = 'Food'..type = CategoryType.expense..icon = 57946,
        Category()..name = 'Transport'..type = CategoryType.expense..icon = 58673,
        Category()..name = 'Shopping'..type = CategoryType.expense..icon = 58694,
        Category()..name = 'Entertainment'..type = CategoryType.expense..icon = 58309,
        Category()..name = 'Bills'..type = CategoryType.expense..icon = 58632,
        Category()..name = 'Education'..type = CategoryType.expense..icon = 58723,
        Category()..name = 'Health'..type = CategoryType.expense..icon = 58345,
        Category()..name = 'Others'..type = CategoryType.common..icon = 57685,
        Category()..name = 'Transfer'..type = CategoryType.common..icon = 58814,
        Category()..name = 'Reimbursement'..type = CategoryType.common..icon = 58661,
      ];
      
      await _db.batch((batch) {
        batch.insertAll(_db.categories, defaultCategories.map((c) => CategoriesCompanion.insert(
          name: c.name,
          type: c.type.name,
          color: c.color,
          icon: c.icon,
        )));
      });
    }
  }
}
