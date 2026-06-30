import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// Pre-cycle exchange-rate cache. Rates are normally stored cycle-scoped
// in the `exchange_rates` table, but the user can plant wells and plots
// (and edit rates) before they ever tap Begin tracking — at which point
// there's no cycle row to hang them off. This file-backed store fills
// that gap. On Begin tracking, `consume()` migrates the contents into
// `exchange_rates` against the new cycle id and clears the file.
//
// The stored value `rate` is rate-to-base, matching the column on the
// `exchange_rates` table.
class PendingRate {
  PendingRate({required this.rate, required this.setAt});

  final double rate;
  final DateTime setAt;

  Map<String, Object> toJson() => {
        'rate': rate,
        'setAt': setAt.millisecondsSinceEpoch,
      };

  static PendingRate? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final rate = raw['rate'];
    final setAt = raw['setAt'];
    if (rate is! num || rate <= 0) return null;
    if (setAt is! int) return null;
    return PendingRate(
      rate: rate.toDouble(),
      setAt: DateTime.fromMillisecondsSinceEpoch(setAt),
    );
  }
}

class PendingRatesStore {
  PendingRatesStore();

  static const String _fileName = 'pending_rates.json';

  final StreamController<Map<String, PendingRate>> _controller =
      StreamController.broadcast();
  Map<String, PendingRate> _cache = const {};
  bool _loaded = false;

  Map<String, PendingRate> get current => _cache;

  // Loads from disk into the in-memory cache. Idempotent — safe to call
  // multiple times. Missing / malformed file resets to empty.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _file();
      if (!await file.exists()) {
        _cache = const {};
        _loaded = true;
        _controller.add(_cache);
        return;
      }
      final text = await file.readAsString();
      if (text.trim().isEmpty) {
        _cache = const {};
      } else {
        final decoded = json.decode(text);
        final rates = (decoded is Map ? decoded['rates'] : null);
        if (rates is Map) {
          final next = <String, PendingRate>{};
          rates.forEach((k, v) {
            if (k is String) {
              final parsed = PendingRate.tryParse(v);
              if (parsed != null) next[k] = parsed;
            }
          });
          _cache = next;
        } else {
          _cache = const {};
        }
      }
    } catch (_) {
      _cache = const {};
    }
    _loaded = true;
    _controller.add(_cache);
  }

  Stream<Map<String, PendingRate>> watch() async* {
    if (!_loaded) await load();
    yield _cache;
    yield* _controller.stream;
  }

  // Replaces every entry in one shot. Used by onboarding-complete and
  // by the rates sheet's bulk Save.
  Future<void> replaceAll(Map<String, double> rates, {DateTime? setAt}) async {
    final stamp = setAt ?? DateTime.now();
    _cache = {
      for (final e in rates.entries)
        if (e.value > 0) e.key: PendingRate(rate: e.value, setAt: stamp),
    };
    await _persist();
    _controller.add(_cache);
  }

  Future<void> upsert(String code, double rate, {DateTime? setAt}) async {
    if (rate <= 0) return;
    final next = Map<String, PendingRate>.from(_cache);
    next[code] = PendingRate(rate: rate, setAt: setAt ?? DateTime.now());
    _cache = next;
    await _persist();
    _controller.add(_cache);
  }

  Future<void> upsertMany(Map<String, double> rates, {DateTime? setAt}) async {
    if (rates.isEmpty) return;
    final stamp = setAt ?? DateTime.now();
    final next = Map<String, PendingRate>.from(_cache);
    for (final e in rates.entries) {
      if (e.value <= 0) continue;
      next[e.key] = PendingRate(rate: e.value, setAt: stamp);
    }
    _cache = next;
    await _persist();
    _controller.add(_cache);
  }

  // Drains the store and returns the current rates as a plain map,
  // matching the legacy `_pendingInitialRates` shape. Called by the
  // cycle-transition flow on Begin tracking.
  Future<Map<String, double>> consume() async {
    if (!_loaded) await load();
    final out = {for (final e in _cache.entries) e.key: e.value.rate};
    await clear();
    return out;
  }

  Future<void> clear() async {
    _cache = const {};
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // best effort; in-memory cache is the source of truth for this run
    }
    _controller.add(_cache);
  }

  Future<void> _persist() async {
    try {
      final file = await _file();
      final payload = {
        'rates': {
          for (final e in _cache.entries) e.key: e.value.toJson(),
        },
      };
      await file.writeAsString(json.encode(payload), flush: true);
    } catch (_) {
      // Cache is still consistent — next launch just won't carry these
      // values. Acceptable degradation.
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }
}
