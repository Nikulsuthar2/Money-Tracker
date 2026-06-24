class Category {
  int id = 0;
  String name = '';
  CategoryType type = CategoryType.expense;
  int color = 0xFF4CAF50;
  int icon = 57522;
  String iconData = 'material:57522';
}

enum CategoryType {
  income,
  expense,
  common
}
