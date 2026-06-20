import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupServiceProvider = Provider((ref) => BackupService());

class BackupService {
  Future<void> exportData() async {
    throw UnimplementedError('Backup is not supported in V1');
  }

  Future<void> importData() async {
    throw UnimplementedError('Restore is not supported in V1');
  }
}
