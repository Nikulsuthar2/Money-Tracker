import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupService(db);
});

class BackupService {
  final AppDatabase _db;
  String? _backupDestinationPath;
  static const _prefKey = 'backup_destination_path';

  BackupService(this._db) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _backupDestinationPath = prefs.getString(_prefKey);
    
    // Fallback to documents directory if null
    if (_backupDestinationPath == null) {
      final docDir = await getApplicationDocumentsDirectory();
      _backupDestinationPath = docDir.path;
      await prefs.setString(_prefKey, _backupDestinationPath!);
    }

    // Listen to table updates to auto backup
    _db.tableUpdates().listen((_) {
      _triggerAutoBackup();
    });
  }

  // Simple debounce logic
  bool _backupScheduled = false;
  void _triggerAutoBackup() {
    if (_backupScheduled) return;
    _backupScheduled = true;
    Future.delayed(const Duration(seconds: 2), () async {
      _backupScheduled = false;
      await _performBackup();
    });
  }

  Future<void> _performBackup() async {
    if (_backupDestinationPath == null) return;
    try {
      final dbFile = await _db.dbFile;
      if (await dbFile.exists()) {
        final backupFile = File(p.join(_backupDestinationPath!, 'MoneyTrackerBackup.sqlite'));
        await dbFile.copy(backupFile.path);
      }
    } catch (e) {
      // Silently fail auto backup to prevent crashing
      print('Auto Backup failed: $e');
    }
  }

  Future<String> get backupDestinationPath async {
    if (_backupDestinationPath == null) {
      final prefs = await SharedPreferences.getInstance();
      _backupDestinationPath = prefs.getString(_prefKey);
      if (_backupDestinationPath == null) {
        final docDir = await getApplicationDocumentsDirectory();
        _backupDestinationPath = docDir.path;
        await prefs.setString(_prefKey, _backupDestinationPath!);
      }
    }
    return _backupDestinationPath!;
  }

  Future<void> setBackupDestination() async {
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        if (!await Permission.storage.request().isGranted) {
          throw Exception('Storage permission required for auto backup');
        }
      }
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, selectedDirectory);
      _backupDestinationPath = selectedDirectory;
      // Trigger an immediate backup to the new location
      await _performBackup();
    }
  }

  Future<void> exportData() async {
    final dbFile = await _db.dbFile;
    if (await dbFile.exists()) {
       await Share.shareXFiles([XFile(dbFile.path)], text: 'Money Tracker Backup');
    } else {
       throw Exception('Database file not found');
    }
  }

  Future<void> importData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final dbFile = await _db.dbFile;
      
      // Basic validation
      if (!sourceFile.path.endsWith('.sqlite') && !sourceFile.path.endsWith('.db')) {
        throw Exception('Invalid file format. Expected .sqlite or .db file');
      }

      // Close the database to release file locks
      await _db.close();

      // Delete the existing database file and any associated WAL/SHM files
      if (await dbFile.exists()) await dbFile.delete();
      final walFile = File('${dbFile.path}-wal');
      if (await walFile.exists()) await walFile.delete();
      final shmFile = File('${dbFile.path}-shm');
      if (await shmFile.exists()) await shmFile.delete();

      await sourceFile.copy(dbFile.path);
      
      // Since the db connection is closed, the app will need a restart.
    } else {
      throw Exception('Import cancelled');
    }
  }
}
