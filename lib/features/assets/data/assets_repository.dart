import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/database/app_database.dart';
import 'package:money_manager/core/database/database_provider.dart';
import 'package:money_manager/features/assets/domain/asset_item.dart';
import 'package:drift/drift.dart' as drift;

final assetsRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return AssetsRepository(db);
});

class AssetsRepository {
  final AppDatabase _db;

  AssetsRepository(this._db);

  Stream<List<AssetItem>> watchAllAssets() {
    return _db.select(_db.assetItems).watch().map((rows) {
      return rows.map((row) => _mapRowToAssetItem(row)).toList();
    });
  }

  Future<int> addAssetItem(AssetItem asset) {
    return _db.into(_db.assetItems).insert(
      AssetItemsCompanion.insert(
        name: asset.name,
        type: asset.type,
        value: asset.value,
        iconData: drift.Value(asset.iconData),
        color: drift.Value(asset.color),
        createdAt: asset.createdAt,
        updatedAt: asset.updatedAt,
      )
    );
  }

  Future<bool> updateAssetItem(AssetItem asset) {
    return _db.update(_db.assetItems).replace(
      AssetItemData(
        id: asset.id,
        name: asset.name,
        type: asset.type,
        value: asset.value,
        iconData: asset.iconData,
        color: asset.color,
        createdAt: asset.createdAt,
        updatedAt: DateTime.now(),
      )
    );
  }

  Future<int> deleteAssetItem(int id) {
    return (_db.delete(_db.assetItems)..where((tbl) => tbl.id.equals(id))).go();
  }

  AssetItem _mapRowToAssetItem(AssetItemData row) {
    return AssetItem(
      id: row.id,
      name: row.name,
      type: row.type,
      value: row.value,
      iconData: row.iconData,
      color: row.color,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
