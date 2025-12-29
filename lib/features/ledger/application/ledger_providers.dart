import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ledger/data/ledger_service.dart';
import '../../../core/database/isar_service.dart';
import 'package:isar/isar.dart';

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  return LedgerService(IsarService());
});
