import 'package:drift/drift.dart';

import 'enum_converters.dart';

enum OwnedItemType {
  crop,
  fertilizer,
  decoration,
  plotColor,
  wellSkin,
  barnSkin,
  avatar,
}

@DataClassName('OwnedItemRow')
class OwnedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text().unique()();
  TextColumn get itemType => text().map(
      const SnakeEnumConverter<OwnedItemType>(OwnedItemType.values))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get acquiredAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (item_type IN ("
            "'crop', 'fertilizer', 'decoration', "
            "'plot_color', 'well_skin', 'barn_skin', 'avatar'"
            "))",
        'CHECK (quantity >= 0)',
      ];
}
