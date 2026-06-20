import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
