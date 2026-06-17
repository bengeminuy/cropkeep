import 'package:drift/drift.dart';

import 'currencies.dart';

@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get farmerName => text()();
  TextColumn get avatarId => text()();
  TextColumn get baseCurrencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get farmerLevel => integer().withDefault(const Constant(1))();
  IntColumn get farmerXp => integer().withDefault(const Constant(0))();
  IntColumn get coinsBalance => integer().withDefault(const Constant(0))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
