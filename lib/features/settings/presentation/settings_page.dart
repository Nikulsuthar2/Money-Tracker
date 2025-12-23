import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/settings/data/backup_service.dart';
import 'package:money_manager/core/database/isar_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            subtitle: const Text('Manage your categories'),
            onTap: () {
              context.push('/categories');
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Backup to a JSON file'),
            onTap: () async {
              try {
                await BackupService().exportData();
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export functionality invoked (check console/platform specific)')));
                   // Note: BackupService logs path.
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from a JSON file'),
            onTap: () async {
               try {
                await BackupService().importData();
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful. Please restart app if state looks stale.')));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Data', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(context: context, builder: (c) => AlertDialog(
                title: const Text('Reset All Data?'),
                content: const Text('This will delete ALL accounts, transactions, and categories. This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                  TextButton(onPressed: () async {
                      await IsarService.clearAll();
                      if (context.mounted) {
                        Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been reset.')));
                      }
                  }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ));
            },
          ),
        ],
      ),
    );
  }
}
