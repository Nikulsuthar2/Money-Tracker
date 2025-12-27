import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  @Enumerated(EnumType.name)
  late CategoryType type;

  int color = 0xFF4CAF50;

  int icon = 57522; // default icon
}

enum CategoryType {
  income,
  expense,
  common
}
