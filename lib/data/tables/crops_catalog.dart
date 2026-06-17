import 'package:drift/drift.dart';

@DataClassName('CropCatalogRow')
class CropsCatalog extends Table {
  TextColumn get cropId => text()();
  TextColumn get name => text()();
  IntColumn get baseCoinYield => integer()();
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  BoolColumn get isConsumable =>
      boolean().withDefault(const Constant(false))();
  IntColumn get seedPackSize => integer().nullable()();
  IntColumn get priceCoins => integer().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {cropId};

  @override
  List<String> get customConstraints => [
        'CHECK (is_starter = 1 OR price_coins IS NOT NULL)',
        'CHECK ('
            '(is_consumable = 0 AND seed_pack_size IS NULL) '
            'OR (is_consumable = 1 AND seed_pack_size >= 1)'
            ')',
      ];
}
