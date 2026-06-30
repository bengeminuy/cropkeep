import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// Free, keyless rate provider. `exchangerate.host` moved to a paid model
// in 2024; `open.er-api.com` is the drop-in replacement that still covers
// every code in `CurrencyCatalog` (incl. TWD/KRW that ECB feeds drop).
// Swap the endpoint here if a different provider is preferred — the rest
// of the app only talks to `FxRatesService`.
const String _kEndpointBase = 'https://open.er-api.com/v6/latest';

class FxRatesException implements Exception {
  FxRatesException(this.message);
  final String message;
  @override
  String toString() => 'FxRatesException: $message';
}

class FxRatesService {
  FxRatesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Returns a map keyed by target currency code → rate-to-base, where
  // `rate-to-base` means: `1 unit of target = rate units of base`. This
  // matches `_convertMinor`'s contract in log_transaction_sheet.dart:
  //   baseMinor = sourceMinor * rate * 10^(targetDecimals - sourceDecimals)
  // The remote API returns the inverse ("X target per 1 base"), so we
  // invert each value before returning. The base itself is never included
  // in the result; callers treat base as identity (1.0).
  Future<Map<String, double>> fetchRatesToBase({
    required String baseCode,
    required List<String> targetCodes,
  }) async {
    final wanted = targetCodes.where((c) => c != baseCode).toSet();
    if (wanted.isEmpty) return const <String, double>{};

    final uri = Uri.parse('$_kEndpointBase/$baseCode');
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw FxRatesException('Request timed out.');
    } catch (e) {
      throw FxRatesException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw FxRatesException('HTTP ${response.statusCode}.');
    }

    final Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw FxRatesException('Bad JSON: $e');
    }

    if (body['result'] != 'success') {
      throw FxRatesException('Provider reported failure.');
    }

    final rawRates = body['rates'];
    if (rawRates is! Map<String, dynamic>) {
      throw FxRatesException('Missing rates payload.');
    }

    final result = <String, double>{};
    for (final code in wanted) {
      final raw = rawRates[code];
      if (raw is! num) continue;
      final perBase = raw.toDouble();
      if (perBase <= 0) continue;
      result[code] = 1.0 / perBase;
    }
    return result;
  }

  void dispose() => _client.close();
}
