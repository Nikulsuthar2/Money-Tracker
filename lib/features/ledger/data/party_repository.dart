import 'package:isar/isar.dart';
import '../../../core/database/isar_service.dart';
import '../../ledger/domain/party.dart';

class PartyRepository {
  final IsarService _isarService;

  PartyRepository(this._isarService);

  Future<void> addParty(Party party) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.partys.put(party);
    });
  }

  Future<void> updateParty(Party party) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.partys.put(party);
    });
  }

  Future<void> deleteParty(int id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.partys.delete(id);
    });
  }

  Future<List<Party>> getAllParties() async {
    final isar = await _isarService.db;
    return await isar.partys.where().findAll();
  }
  
  Stream<List<Party>> watchAllParties() async* {
    final isar = await _isarService.db;
    yield* isar.partys.where().watch(fireImmediately: true);
  }
}
