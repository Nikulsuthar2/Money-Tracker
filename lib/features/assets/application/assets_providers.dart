import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/assets/domain/asset_item.dart';
import 'package:money_manager/features/assets/data/assets_repository.dart';

final assetsStreamProvider = StreamProvider<List<AssetItem>>((ref) {
  final repository = ref.watch(assetsRepositoryProvider);
  return repository.watchAllAssets();
});
