import 'package:drift/drift.dart';

import 'cycles.dart';

@DataClassName('BadgeEarnedRow')
class BadgesEarned extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get badgeId => text().unique()();
  IntColumn get earnedAt => integer()();
  IntColumn get cycleId => integer().nullable().references(Cycles, #id)();
}
