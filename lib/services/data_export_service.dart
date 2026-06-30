import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

class DataExportService {
  DataExportService(this._db);

  final AppDatabase _db;

  // Bumped when the export envelope shape changes (not when the DB schema
  // changes — that's tracked separately in `db_schema_version`).
  static const int exportSchemaVersion = 1;

  Future<File> exportToTempFile({
    required String farmerName,
    required String appVersion,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final payload = await buildPayload(
      farmerName: farmerName,
      appVersion: appVersion,
      exportedAt: timestamp,
    );
    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final filename = _buildFilename(farmerName, timestamp);
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<Map<String, dynamic>> buildPayload({
    required String farmerName,
    required String appVersion,
    required DateTime exportedAt,
  }) async {
    return {
      'app': 'cropkeep',
      'app_version': appVersion,
      'export_schema_version': exportSchemaVersion,
      'db_schema_version': _db.schemaVersion,
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'farmer_name': farmerName,
      'tables': {
        'app_settings': await _dump(_db.appSettings),
        'currencies': await _dump(_db.currencies),
        'cycles': await _dump(_db.cycles),
        'cycle_summaries': await _dump(_db.cycleSummaries),
        'exchange_rates': await _dump(_db.exchangeRates),
        'wells': await _dump(_db.wells),
        'income_entries': await _dump(_db.incomeEntries),
        'bonus_allocations': await _dump(_db.bonusAllocations),
        'savings_barn': await _dump(_db.savingsBarn),
        'plots': await _dump(_db.plots),
        'transactions': await _dump(_db.transactions),
        'plot_cycle_results': await _dump(_db.plotCycleResults),
        'plot_fertilizer_applications':
            await _dump(_db.plotFertilizerApplications),
        'coin_ledger': await _dump(_db.coinLedger),
        'badges_earned': await _dump(_db.badgesEarned),
        'crops_catalog': await _dump(_db.cropsCatalog),
        'owned_items': await _dump(_db.ownedItems),
      },
    };
  }

  Future<List<Map<String, dynamic>>> _dump<T extends Table, R extends DataClass>(
    TableInfo<T, R> table,
  ) async {
    final rows = await _db.select(table).get();
    return [for (final row in rows) row.toJson()];
  }

  String _buildFilename(String farmerName, DateTime when) {
    final date =
        '${when.year.toString().padLeft(4, '0')}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
    final slug = _slugify(farmerName);
    return slug.isEmpty
        ? 'cropkeep-backup-$date.json'
        : 'cropkeep-backup-$date-$slug.json';
  }

  String _slugify(String value) {
    final lowered = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final code in lowered.codeUnits) {
      final isLower = code >= 0x61 && code <= 0x7a;
      final isDigit = code >= 0x30 && code <= 0x39;
      if (isLower || isDigit) {
        buffer.writeCharCode(code);
      } else if (code == 0x20 || code == 0x2d || code == 0x5f) {
        buffer.write('-');
      }
    }
    return buffer.toString().replaceAll(RegExp(r'-+'), '-').replaceAll(
          RegExp(r'^-|-$'),
          '',
        );
  }
}
