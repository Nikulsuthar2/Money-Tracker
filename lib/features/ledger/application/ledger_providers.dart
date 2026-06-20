import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/ledger/domain/ledger_entry.dart';

final allLedgerEntriesProvider = StreamProvider<List<LedgerEntry>>((ref) => Stream.value([]));
final ledgerServiceProvider = Provider((ref) => FakeLedgerService());

class FakeLedgerService {
  Future<List<LedgerEntry>> getLedgerEntries(int id) async => [];
}
