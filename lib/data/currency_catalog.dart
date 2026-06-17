class CurrencySpec {
  const CurrencySpec({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalPlaces,
    required this.flagAsset,
  });

  final String code;
  final String symbol;
  final String name;
  final int decimalPlaces;
  final String flagAsset;
}

class CurrencyCatalog {
  const CurrencyCatalog._();

  static const List<CurrencySpec> all = <CurrencySpec>[
    CurrencySpec(code: 'USD', symbol: r'$',   name: 'US Dollar',         decimalPlaces: 2, flagAsset: 'assets/icons/flags/us.svg'),
    CurrencySpec(code: 'EUR', symbol: '€',    name: 'Euro',              decimalPlaces: 2, flagAsset: 'assets/icons/flags/eu.svg'),
    CurrencySpec(code: 'GBP', symbol: '£',    name: 'British Pound',     decimalPlaces: 2, flagAsset: 'assets/icons/flags/gb.svg'),
    CurrencySpec(code: 'JPY', symbol: '¥',    name: 'Japanese Yen',      decimalPlaces: 0, flagAsset: 'assets/icons/flags/jp.svg'),
    CurrencySpec(code: 'TWD', symbol: r'NT$', name: 'New Taiwan Dollar', decimalPlaces: 2, flagAsset: 'assets/icons/flags/tw.svg'),
    CurrencySpec(code: 'KRW', symbol: '₩',    name: 'Korean Won',        decimalPlaces: 0, flagAsset: 'assets/icons/flags/kr.svg'),
    CurrencySpec(code: 'PHP', symbol: '₱',    name: 'Philippine Peso',   decimalPlaces: 2, flagAsset: 'assets/icons/flags/ph.svg'),
  ];

  static CurrencySpec? findByCode(String code) {
    for (final spec in all) {
      if (spec.code == code) return spec;
    }
    return null;
  }
}
