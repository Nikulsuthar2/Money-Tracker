import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/database/isar_service.dart';
import 'package:isar/isar.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final backupServiceProvider = Provider((ref) => BackupService());

class BackupService {
  Future<void> exportData() async {
    final isar = IsarService.isar;
    
    final accounts = await isar.accounts.where().anyId().watch(fireImmediately: true).first;
    final categories = await isar.categorys.where().anyId().watch(fireImmediately: true).first;
    final transactions = await isar.transactions.where().anyId().watch(fireImmediately: true).first;
    final subscriptions = await isar.subscriptions.where().anyId().watch(fireImmediately: true).first;

    final data = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'accounts': accounts.map((e) => {
        'id': e.id,
        'name': e.name,
        'type': e.type.name,
        'openingBalance': e.openingBalance,
        'color': e.color,
        'icon': e.icon,
        'isArchived': e.isArchived,
      }).toList(),
      'categories': categories.map((e) => {
        'id': e.id,
        'name': e.name,
        'type': e.type.name,
        'color': e.color,
        'icon': e.icon,
      }).toList(),
      'transactions': transactions.map((e) => {
        'id': e.id,
        'amount': e.amount,
        'type': e.type.name,
        'fromAccountId': e.fromAccountId,
        'toAccountId': e.toAccountId,
        'categoryId': e.categoryId,
        'note': e.note,
        'date': e.date.toIso8601String(),
        'isRecurring': e.isRecurring,
        'subscriptionId': e.subscriptionId,
        'subTransactions': e.subTransactions?.map((s) => { // Added split support export
           'amount': s.amount,
           'note': s.note,
           'categoryId': s.categoryId,
           'isMine': s.isMine,
        }).toList(),
      }).toList(),
      'subscriptions': subscriptions.map((e) => {
        'id': e.id,
        'name': e.name,
        'amount': e.amount,
        'repeat': e.repeat.name,
        'startDate': e.startDate.toIso8601String(),
        'lastPaymentDate': e.lastPaymentDate?.toIso8601String(),
        'accountId': e.accountId,
        'categoryId': e.categoryId,
        'isActive': e.isActive,
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    // Remove extension from name because FileSaver adds it?? No, usually explicitly needed or handled by ext param.
    // FileSaver adds extension if not present.
    final filename = 'money_manager_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
    
    if (Platform.isAndroid || Platform.isIOS) {
       // Use Share Sheet to allow user to pick location/app
       final tempDir = await getTemporaryDirectory();
       final file = File('${tempDir.path}/$filename.json');
       await file.writeAsString(jsonString);
       await Share.shareXFiles(
         [XFile(file.path)], 
         text: 'Money Tracker Backup',
         subject: 'Money Tracker Backup $filename',
       );
    } else {
       // Desktop: Save File Dialog
       final outputFile = await FilePicker.platform.saveFile(
         dialogTitle: 'Save Backup',
         fileName: '$filename.json',
         allowedExtensions: ['json'],
         type: FileType.custom,
       );
       
       if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(jsonString);
       }
    }
  }

  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      if (data['version'] == 1) {
        final isar = IsarService.isar;
        await isar.writeTxn(() async {
          await isar.clear(); // Wipe existing data
          
          // Import Accounts
          final accountsData = (data['accounts'] as List);
          for (final item in accountsData) {
             final account = Account()
               ..name = item['name']
               ..type = AccountType.values.byName(item['type'])
               ..openingBalance = (item['openingBalance'] as num).toDouble()
               ..color = item['color']
               ..icon = item['icon']
               ..isArchived = item['isArchived'];
             account.id = item['id']; 
             await isar.accounts.put(account);
          }
          
          // Import Categories
          final categoriesData = (data['categories'] as List);
          for (final item in categoriesData) {
            final category = Category()
               ..id = item['id']
               ..name = item['name']
               ..type = CategoryType.values.byName(item['type'])
               ..color = item['color']
               ..icon = item['icon'];
            await isar.categorys.put(category);
          }
          
          // Import Transactions
          final transactionsData = (data['transactions'] as List);
          for (final item in transactionsData) {
            final transaction = Transaction()
               ..id = item['id']
               ..amount = (item['amount'] as num).toDouble()
               ..type = TransactionType.values.byName(item['type'])
               ..fromAccountId = item['fromAccountId']
               ..toAccountId = item['toAccountId']
               ..categoryId = item['categoryId']
               ..note = item['note']
               ..date = DateTime.parse(item['date'])
               ..isRecurring = item['isRecurring']
               ..subscriptionId = item['subscriptionId'];
            
            // Import Splits
            if (item['subTransactions'] != null) {
               transaction.subTransactions = (item['subTransactions'] as List).map((s) => SubTransaction()
                 ..amount = (s['amount'] as num).toDouble()
                 ..note = s['note']
                 ..categoryId = s['categoryId']
                 ..isMine = s['isMine'] ?? true
               ).toList();
            }

            await isar.transactions.put(transaction);
          }
          
          // Import Subscriptions
          final subscriptionsData = (data['subscriptions'] as List);
          for (final item in subscriptionsData) {
            final subscription = Subscription()
               ..id = item['id']
               ..name = item['name']
               ..amount = (item['amount'] as num).toDouble()
               ..repeat = SubscriptionRepeat.values.byName(item['repeat'])
               ..startDate = DateTime.parse(item['startDate'])
               ..lastPaymentDate = item['lastPaymentDate'] != null ? DateTime.parse(item['lastPaymentDate']) : null
               ..accountId = item['accountId']
               ..categoryId = item['categoryId']
               ..isActive = item['isActive'];
            await isar.subscriptions.put(subscription);
          }
        });
      }
    }
  }
}
