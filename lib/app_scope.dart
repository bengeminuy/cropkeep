import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'data/repositories/app_settings_repository.dart';
import 'data/repositories/savings_barn_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.database,
    required this.appSettings,
    required this.savingsBarn,
    required super.child,
  });

  final AppDatabase database;
  final AppSettingsRepository appSettings;
  final SavingsBarnRepository savingsBarn;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found. Wrap your app in an AppScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      database != oldWidget.database ||
      appSettings != oldWidget.appSettings ||
      savingsBarn != oldWidget.savingsBarn;
}
