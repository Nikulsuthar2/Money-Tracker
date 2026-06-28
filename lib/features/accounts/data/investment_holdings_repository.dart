import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/domain/investment_holding.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

final investmentHoldingsRepositoryProvider = Provider<InvestmentHoldingsRepository>((ref) {
  return InvestmentHoldingsRepository(ref.watch(databaseProvider));
});

final accountHoldingsProvider = StreamProvider.family<List<InvestmentHolding>, int>((ref, accountId) {
  return ref.watch(investmentHoldingsRepositoryProvider).watchAccountHoldings(accountId);
});

extension InvestmentHoldingMapper on InvestmentHoldingData {
  InvestmentHolding toDomain() {
    return InvestmentHolding()
      ..id = id
      ..accountId = accountId
      ..symbol = symbol
      ..type = type
      ..quantity = quantity
      ..averageBuyPrice = averageBuyPrice
      ..currentPrice = currentPrice
      ..updatedAt = updatedAt;
  }
}

class InvestmentHoldingsRepository {
  final AppDatabase _db;

  InvestmentHoldingsRepository(this._db);

  Stream<List<InvestmentHolding>> watchAccountHoldings(int accountId) {
    return (_db.select(_db.investmentHoldings)..where((h) => h.accountId.equals(accountId)))
        .watch()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  Stream<List<InvestmentHolding>> watchAllHoldings() {
    return _db.select(_db.investmentHoldings).watch().map((list) => list.map((e) => e.toDomain()).toList());
  }

  Future<List<InvestmentHolding>> getAccountHoldings(int accountId) async {
    final list = await (_db.select(_db.investmentHoldings)..where((h) => h.accountId.equals(accountId))).get();
    return list.map((e) => e.toDomain()).toList();
  }

  Future<void> addHolding(InvestmentHolding holding) async {
    await _db.into(_db.investmentHoldings).insert(InvestmentHoldingsCompanion.insert(
      accountId: holding.accountId,
      symbol: holding.symbol,
      type: drift.Value(holding.type),
      quantity: holding.quantity,
      averageBuyPrice: holding.averageBuyPrice,
      currentPrice: holding.currentPrice,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateHolding(InvestmentHolding holding) async {
    await _db.update(_db.investmentHoldings).replace(InvestmentHoldingData(
      id: holding.id,
      accountId: holding.accountId,
      symbol: holding.symbol,
      type: holding.type,
      quantity: holding.quantity,
      averageBuyPrice: holding.averageBuyPrice,
      currentPrice: holding.currentPrice,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteHolding(int id) async {
    await (_db.delete(_db.investmentHoldings)..where((h) => h.id.equals(id))).go();
  }
}
