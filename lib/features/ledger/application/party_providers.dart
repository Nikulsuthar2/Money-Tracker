
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ledger/data/party_repository.dart';
import '../../ledger/domain/party.dart';
import '../../../core/database/isar_service.dart';

// Check if IsarService is exposed as a provider elsewhere, usually likely.
// But for now, I'll instantiate it simply or look for a provider.
// Given previous files, I didn't see a global isarServiceProvider.
// I will create a simple provider for the Repository.

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepository(IsarService());
});

final partiesStreamProvider = StreamProvider.autoDispose<List<Party>>((ref) async* {
  final repo = ref.watch(partyRepositoryProvider);
  yield* repo.watchAllParties();
});

// Using generator syntax ideally if project uses it, but manual is fine for speed.
