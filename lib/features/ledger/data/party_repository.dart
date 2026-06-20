import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/ledger/domain/party.dart';

final partyRepositoryProvider = Provider((ref) => FakePartyRepository());

class FakePartyRepository {
  Future<Party?> getParty(int id) async => null;
  Future<List<Party>> getAllParties() async => [];
}
