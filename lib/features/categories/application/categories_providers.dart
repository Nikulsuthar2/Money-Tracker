import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/categories/data/categories_repository.dart';

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchAllCategories();
});

final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchIncomeCategories();
});

final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchExpenseCategories();
});

