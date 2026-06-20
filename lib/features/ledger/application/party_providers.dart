import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/ledger/domain/party.dart';

final partiesStreamProvider = StreamProvider<List<Party>>((ref) => Stream.value([]));
