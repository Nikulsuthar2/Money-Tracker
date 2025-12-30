import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ledger/data/ledger_service.dart';
import '../../../core/database/isar_service.dart';
import 'package:isar/isar.dart';
import '../../ledger/domain/ledger_entry.dart';

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  return LedgerService(IsarService());
});

final allLedgerEntriesProvider = StreamProvider.autoDispose<List<LedgerEntry>>((ref) {
  final service = ref.watch(ledgerServiceProvider);
  return service.watchAllLedgerEntries();
});
