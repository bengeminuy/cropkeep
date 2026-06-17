// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CurrenciesTable extends Currencies
    with TableInfo<$CurrenciesTable, CurrencyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decimalPlacesMeta = const VerificationMeta(
    'decimalPlaces',
  );
  @override
  late final GeneratedColumn<int> decimalPlaces = GeneratedColumn<int>(
    'decimal_places',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBaseMeta = const VerificationMeta('isBase');
  @override
  late final GeneratedColumn<bool> isBase = GeneratedColumn<bool>(
    'is_base',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_base" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    symbol,
    name,
    decimalPlaces,
    isBase,
    isActive,
    displayOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('decimal_places')) {
      context.handle(
        _decimalPlacesMeta,
        decimalPlaces.isAcceptableOrUnknown(
          data['decimal_places']!,
          _decimalPlacesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decimalPlacesMeta);
    }
    if (data.containsKey('is_base')) {
      context.handle(
        _isBaseMeta,
        isBase.isAcceptableOrUnknown(data['is_base']!, _isBaseMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  CurrencyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      decimalPlaces: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}decimal_places'],
      )!,
      isBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_base'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
    );
  }

  @override
  $CurrenciesTable createAlias(String alias) {
    return $CurrenciesTable(attachedDatabase, alias);
  }
}

class CurrencyRow extends DataClass implements Insertable<CurrencyRow> {
  final String code;
  final String symbol;
  final String name;
  final int decimalPlaces;
  final bool isBase;
  final bool isActive;
  final int displayOrder;
  const CurrencyRow({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalPlaces,
    required this.isBase,
    required this.isActive,
    required this.displayOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['decimal_places'] = Variable<int>(decimalPlaces);
    map['is_base'] = Variable<bool>(isBase);
    map['is_active'] = Variable<bool>(isActive);
    map['display_order'] = Variable<int>(displayOrder);
    return map;
  }

  CurrenciesCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesCompanion(
      code: Value(code),
      symbol: Value(symbol),
      name: Value(name),
      decimalPlaces: Value(decimalPlaces),
      isBase: Value(isBase),
      isActive: Value(isActive),
      displayOrder: Value(displayOrder),
    );
  }

  factory CurrencyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyRow(
      code: serializer.fromJson<String>(json['code']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      decimalPlaces: serializer.fromJson<int>(json['decimalPlaces']),
      isBase: serializer.fromJson<bool>(json['isBase']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'decimalPlaces': serializer.toJson<int>(decimalPlaces),
      'isBase': serializer.toJson<bool>(isBase),
      'isActive': serializer.toJson<bool>(isActive),
      'displayOrder': serializer.toJson<int>(displayOrder),
    };
  }

  CurrencyRow copyWith({
    String? code,
    String? symbol,
    String? name,
    int? decimalPlaces,
    bool? isBase,
    bool? isActive,
    int? displayOrder,
  }) => CurrencyRow(
    code: code ?? this.code,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    isBase: isBase ?? this.isBase,
    isActive: isActive ?? this.isActive,
    displayOrder: displayOrder ?? this.displayOrder,
  );
  CurrencyRow copyWithCompanion(CurrenciesCompanion data) {
    return CurrencyRow(
      code: data.code.present ? data.code.value : this.code,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      decimalPlaces: data.decimalPlaces.present
          ? data.decimalPlaces.value
          : this.decimalPlaces,
      isBase: data.isBase.present ? data.isBase.value : this.isBase,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyRow(')
          ..write('code: $code, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('decimalPlaces: $decimalPlaces, ')
          ..write('isBase: $isBase, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    symbol,
    name,
    decimalPlaces,
    isBase,
    isActive,
    displayOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyRow &&
          other.code == this.code &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.decimalPlaces == this.decimalPlaces &&
          other.isBase == this.isBase &&
          other.isActive == this.isActive &&
          other.displayOrder == this.displayOrder);
}

class CurrenciesCompanion extends UpdateCompanion<CurrencyRow> {
  final Value<String> code;
  final Value<String> symbol;
  final Value<String> name;
  final Value<int> decimalPlaces;
  final Value<bool> isBase;
  final Value<bool> isActive;
  final Value<int> displayOrder;
  final Value<int> rowid;
  const CurrenciesCompanion({
    this.code = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.decimalPlaces = const Value.absent(),
    this.isBase = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesCompanion.insert({
    required String code,
    required String symbol,
    required String name,
    required int decimalPlaces,
    this.isBase = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       symbol = Value(symbol),
       name = Value(name),
       decimalPlaces = Value(decimalPlaces);
  static Insertable<CurrencyRow> custom({
    Expression<String>? code,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<int>? decimalPlaces,
    Expression<bool>? isBase,
    Expression<bool>? isActive,
    Expression<int>? displayOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (decimalPlaces != null) 'decimal_places': decimalPlaces,
      if (isBase != null) 'is_base': isBase,
      if (isActive != null) 'is_active': isActive,
      if (displayOrder != null) 'display_order': displayOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesCompanion copyWith({
    Value<String>? code,
    Value<String>? symbol,
    Value<String>? name,
    Value<int>? decimalPlaces,
    Value<bool>? isBase,
    Value<bool>? isActive,
    Value<int>? displayOrder,
    Value<int>? rowid,
  }) {
    return CurrenciesCompanion(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      isBase: isBase ?? this.isBase,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (decimalPlaces.present) {
      map['decimal_places'] = Variable<int>(decimalPlaces.value);
    }
    if (isBase.present) {
      map['is_base'] = Variable<bool>(isBase.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrenciesCompanion(')
          ..write('code: $code, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('decimalPlaces: $decimalPlaces, ')
          ..write('isBase: $isBase, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _farmerNameMeta = const VerificationMeta(
    'farmerName',
  );
  @override
  late final GeneratedColumn<String> farmerName = GeneratedColumn<String>(
    'farmer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarIdMeta = const VerificationMeta(
    'avatarId',
  );
  @override
  late final GeneratedColumn<String> avatarId = GeneratedColumn<String>(
    'avatar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCurrencyCodeMeta = const VerificationMeta(
    'baseCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> baseCurrencyCode = GeneratedColumn<String>(
    'base_currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _farmerLevelMeta = const VerificationMeta(
    'farmerLevel',
  );
  @override
  late final GeneratedColumn<int> farmerLevel = GeneratedColumn<int>(
    'farmer_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _farmerXpMeta = const VerificationMeta(
    'farmerXp',
  );
  @override
  late final GeneratedColumn<int> farmerXp = GeneratedColumn<int>(
    'farmer_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coinsBalanceMeta = const VerificationMeta(
    'coinsBalance',
  );
  @override
  late final GeneratedColumn<int> coinsBalance = GeneratedColumn<int>(
    'coins_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    farmerName,
    avatarId,
    baseCurrencyCode,
    onboardingCompleted,
    farmerLevel,
    farmerXp,
    coinsBalance,
    notificationsEnabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('farmer_name')) {
      context.handle(
        _farmerNameMeta,
        farmerName.isAcceptableOrUnknown(data['farmer_name']!, _farmerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_farmerNameMeta);
    }
    if (data.containsKey('avatar_id')) {
      context.handle(
        _avatarIdMeta,
        avatarId.isAcceptableOrUnknown(data['avatar_id']!, _avatarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarIdMeta);
    }
    if (data.containsKey('base_currency_code')) {
      context.handle(
        _baseCurrencyCodeMeta,
        baseCurrencyCode.isAcceptableOrUnknown(
          data['base_currency_code']!,
          _baseCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyCodeMeta);
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('farmer_level')) {
      context.handle(
        _farmerLevelMeta,
        farmerLevel.isAcceptableOrUnknown(
          data['farmer_level']!,
          _farmerLevelMeta,
        ),
      );
    }
    if (data.containsKey('farmer_xp')) {
      context.handle(
        _farmerXpMeta,
        farmerXp.isAcceptableOrUnknown(data['farmer_xp']!, _farmerXpMeta),
      );
    }
    if (data.containsKey('coins_balance')) {
      context.handle(
        _coinsBalanceMeta,
        coinsBalance.isAcceptableOrUnknown(
          data['coins_balance']!,
          _coinsBalanceMeta,
        ),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      farmerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farmer_name'],
      )!,
      avatarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_id'],
      )!,
      baseCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency_code'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      farmerLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}farmer_level'],
      )!,
      farmerXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}farmer_xp'],
      )!,
      coinsBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins_balance'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String farmerName;
  final String avatarId;
  final String baseCurrencyCode;
  final bool onboardingCompleted;
  final int farmerLevel;
  final int farmerXp;
  final int coinsBalance;
  final bool notificationsEnabled;
  final int createdAt;
  const AppSettingsRow({
    required this.id,
    required this.farmerName,
    required this.avatarId,
    required this.baseCurrencyCode,
    required this.onboardingCompleted,
    required this.farmerLevel,
    required this.farmerXp,
    required this.coinsBalance,
    required this.notificationsEnabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['farmer_name'] = Variable<String>(farmerName);
    map['avatar_id'] = Variable<String>(avatarId);
    map['base_currency_code'] = Variable<String>(baseCurrencyCode);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['farmer_level'] = Variable<int>(farmerLevel);
    map['farmer_xp'] = Variable<int>(farmerXp);
    map['coins_balance'] = Variable<int>(coinsBalance);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      farmerName: Value(farmerName),
      avatarId: Value(avatarId),
      baseCurrencyCode: Value(baseCurrencyCode),
      onboardingCompleted: Value(onboardingCompleted),
      farmerLevel: Value(farmerLevel),
      farmerXp: Value(farmerXp),
      coinsBalance: Value(coinsBalance),
      notificationsEnabled: Value(notificationsEnabled),
      createdAt: Value(createdAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      farmerName: serializer.fromJson<String>(json['farmerName']),
      avatarId: serializer.fromJson<String>(json['avatarId']),
      baseCurrencyCode: serializer.fromJson<String>(json['baseCurrencyCode']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      farmerLevel: serializer.fromJson<int>(json['farmerLevel']),
      farmerXp: serializer.fromJson<int>(json['farmerXp']),
      coinsBalance: serializer.fromJson<int>(json['coinsBalance']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'farmerName': serializer.toJson<String>(farmerName),
      'avatarId': serializer.toJson<String>(avatarId),
      'baseCurrencyCode': serializer.toJson<String>(baseCurrencyCode),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'farmerLevel': serializer.toJson<int>(farmerLevel),
      'farmerXp': serializer.toJson<int>(farmerXp),
      'coinsBalance': serializer.toJson<int>(coinsBalance),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    String? farmerName,
    String? avatarId,
    String? baseCurrencyCode,
    bool? onboardingCompleted,
    int? farmerLevel,
    int? farmerXp,
    int? coinsBalance,
    bool? notificationsEnabled,
    int? createdAt,
  }) => AppSettingsRow(
    id: id ?? this.id,
    farmerName: farmerName ?? this.farmerName,
    avatarId: avatarId ?? this.avatarId,
    baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    farmerLevel: farmerLevel ?? this.farmerLevel,
    farmerXp: farmerXp ?? this.farmerXp,
    coinsBalance: coinsBalance ?? this.coinsBalance,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    createdAt: createdAt ?? this.createdAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      farmerName: data.farmerName.present
          ? data.farmerName.value
          : this.farmerName,
      avatarId: data.avatarId.present ? data.avatarId.value : this.avatarId,
      baseCurrencyCode: data.baseCurrencyCode.present
          ? data.baseCurrencyCode.value
          : this.baseCurrencyCode,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      farmerLevel: data.farmerLevel.present
          ? data.farmerLevel.value
          : this.farmerLevel,
      farmerXp: data.farmerXp.present ? data.farmerXp.value : this.farmerXp,
      coinsBalance: data.coinsBalance.present
          ? data.coinsBalance.value
          : this.coinsBalance,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('farmerName: $farmerName, ')
          ..write('avatarId: $avatarId, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('farmerLevel: $farmerLevel, ')
          ..write('farmerXp: $farmerXp, ')
          ..write('coinsBalance: $coinsBalance, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    farmerName,
    avatarId,
    baseCurrencyCode,
    onboardingCompleted,
    farmerLevel,
    farmerXp,
    coinsBalance,
    notificationsEnabled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.farmerName == this.farmerName &&
          other.avatarId == this.avatarId &&
          other.baseCurrencyCode == this.baseCurrencyCode &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.farmerLevel == this.farmerLevel &&
          other.farmerXp == this.farmerXp &&
          other.coinsBalance == this.coinsBalance &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.createdAt == this.createdAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> farmerName;
  final Value<String> avatarId;
  final Value<String> baseCurrencyCode;
  final Value<bool> onboardingCompleted;
  final Value<int> farmerLevel;
  final Value<int> farmerXp;
  final Value<int> coinsBalance;
  final Value<bool> notificationsEnabled;
  final Value<int> createdAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.farmerName = const Value.absent(),
    this.avatarId = const Value.absent(),
    this.baseCurrencyCode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.farmerLevel = const Value.absent(),
    this.farmerXp = const Value.absent(),
    this.coinsBalance = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String farmerName,
    required String avatarId,
    required String baseCurrencyCode,
    this.onboardingCompleted = const Value.absent(),
    this.farmerLevel = const Value.absent(),
    this.farmerXp = const Value.absent(),
    this.coinsBalance = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    required int createdAt,
  }) : farmerName = Value(farmerName),
       avatarId = Value(avatarId),
       baseCurrencyCode = Value(baseCurrencyCode),
       createdAt = Value(createdAt);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? farmerName,
    Expression<String>? avatarId,
    Expression<String>? baseCurrencyCode,
    Expression<bool>? onboardingCompleted,
    Expression<int>? farmerLevel,
    Expression<int>? farmerXp,
    Expression<int>? coinsBalance,
    Expression<bool>? notificationsEnabled,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farmerName != null) 'farmer_name': farmerName,
      if (avatarId != null) 'avatar_id': avatarId,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (farmerLevel != null) 'farmer_level': farmerLevel,
      if (farmerXp != null) 'farmer_xp': farmerXp,
      if (coinsBalance != null) 'coins_balance': coinsBalance,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? farmerName,
    Value<String>? avatarId,
    Value<String>? baseCurrencyCode,
    Value<bool>? onboardingCompleted,
    Value<int>? farmerLevel,
    Value<int>? farmerXp,
    Value<int>? coinsBalance,
    Value<bool>? notificationsEnabled,
    Value<int>? createdAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      farmerName: farmerName ?? this.farmerName,
      avatarId: avatarId ?? this.avatarId,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      farmerLevel: farmerLevel ?? this.farmerLevel,
      farmerXp: farmerXp ?? this.farmerXp,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (farmerName.present) {
      map['farmer_name'] = Variable<String>(farmerName.value);
    }
    if (avatarId.present) {
      map['avatar_id'] = Variable<String>(avatarId.value);
    }
    if (baseCurrencyCode.present) {
      map['base_currency_code'] = Variable<String>(baseCurrencyCode.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (farmerLevel.present) {
      map['farmer_level'] = Variable<int>(farmerLevel.value);
    }
    if (farmerXp.present) {
      map['farmer_xp'] = Variable<int>(farmerXp.value);
    }
    if (coinsBalance.present) {
      map['coins_balance'] = Variable<int>(coinsBalance.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('farmerName: $farmerName, ')
          ..write('avatarId: $avatarId, ')
          ..write('baseCurrencyCode: $baseCurrencyCode, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('farmerLevel: $farmerLevel, ')
          ..write('farmerXp: $farmerXp, ')
          ..write('coinsBalance: $coinsBalance, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CyclesTable extends Cycles with TableInfo<$CyclesTable, CycleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CycleState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CycleState>($CyclesTable.$converterstate);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    endDate,
    state,
    label,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CycleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CycleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      )!,
      state: $CyclesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $CyclesTable createAlias(String alias) {
    return $CyclesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CycleState, String, String> $converterstate =
      const EnumNameConverter<CycleState>(CycleState.values);
}

class CycleRow extends DataClass implements Insertable<CycleRow> {
  final int id;
  final int startDate;
  final int endDate;
  final CycleState state;
  final String? label;
  final int createdAt;
  final int? completedAt;
  const CycleRow({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.state,
    this.label,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    {
      map['state'] = Variable<String>(
        $CyclesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  CyclesCompanion toCompanion(bool nullToAbsent) {
    return CyclesCompanion(
      id: Value(id),
      startDate: Value(startDate),
      endDate: Value(endDate),
      state: Value(state),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory CycleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleRow(
      id: serializer.fromJson<int>(json['id']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      state: $CyclesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      label: serializer.fromJson<String?>(json['label']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'state': serializer.toJson<String>(
        $CyclesTable.$converterstate.toJson(state),
      ),
      'label': serializer.toJson<String?>(label),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  CycleRow copyWith({
    int? id,
    int? startDate,
    int? endDate,
    CycleState? state,
    Value<String?> label = const Value.absent(),
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
  }) => CycleRow(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    state: state ?? this.state,
    label: label.present ? label.value : this.label,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  CycleRow copyWithCompanion(CyclesCompanion data) {
    return CycleRow(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      state: data.state.present ? data.state.value : this.state,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleRow(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('state: $state, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDate, endDate, state, label, createdAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleRow &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.state == this.state &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class CyclesCompanion extends UpdateCompanion<CycleRow> {
  final Value<int> id;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<CycleState> state;
  final Value<String?> label;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  const CyclesCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.state = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  CyclesCompanion.insert({
    this.id = const Value.absent(),
    required int startDate,
    required int endDate,
    required CycleState state,
    this.label = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
  }) : startDate = Value(startDate),
       endDate = Value(endDate),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<CycleRow> custom({
    Expression<int>? id,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? state,
    Expression<String>? label,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (state != null) 'state': state,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  CyclesCompanion copyWith({
    Value<int>? id,
    Value<int>? startDate,
    Value<int>? endDate,
    Value<CycleState>? state,
    Value<String?>? label,
    Value<int>? createdAt,
    Value<int?>? completedAt,
  }) {
    return CyclesCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      state: state ?? this.state,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $CyclesTable.$converterstate.toSql(state.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CyclesCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('state: $state, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $CycleSummariesTable extends CycleSummaries
    with TableInfo<$CycleSummariesTable, CycleSummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CycleSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _totalFoundationIncomeMeta =
      const VerificationMeta('totalFoundationIncome');
  @override
  late final GeneratedColumn<int> totalFoundationIncome = GeneratedColumn<int>(
    'total_foundation_income',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBonusIncomeMeta = const VerificationMeta(
    'totalBonusIncome',
  );
  @override
  late final GeneratedColumn<int> totalBonusIncome = GeneratedColumn<int>(
    'total_bonus_income',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSpentPlannedMeta = const VerificationMeta(
    'totalSpentPlanned',
  );
  @override
  late final GeneratedColumn<int> totalSpentPlanned = GeneratedColumn<int>(
    'total_spent_planned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSpentUnplannedMeta =
      const VerificationMeta('totalSpentUnplanned');
  @override
  late final GeneratedColumn<int> totalSpentUnplanned = GeneratedColumn<int>(
    'total_spent_unplanned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSpentMeta = const VerificationMeta(
    'totalSpent',
  );
  @override
  late final GeneratedColumn<int> totalSpent = GeneratedColumn<int>(
    'total_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surplusMeta = const VerificationMeta(
    'surplus',
  );
  @override
  late final GeneratedColumn<int> surplus = GeneratedColumn<int>(
    'surplus',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CycleResultTier, String>
  resultTier = GeneratedColumn<String>(
    'result_tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CycleResultTier>($CycleSummariesTable.$converterresultTier);
  static const VerificationMeta _overallBonusCoinsMeta = const VerificationMeta(
    'overallBonusCoins',
  );
  @override
  late final GeneratedColumn<int> overallBonusCoins = GeneratedColumn<int>(
    'overall_bonus_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _perPlotCoinsMeta = const VerificationMeta(
    'perPlotCoins',
  );
  @override
  late final GeneratedColumn<int> perPlotCoins = GeneratedColumn<int>(
    'per_plot_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _surplusSavedCoinsMeta = const VerificationMeta(
    'surplusSavedCoins',
  );
  @override
  late final GeneratedColumn<int> surplusSavedCoins = GeneratedColumn<int>(
    'surplus_saved_coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCoinsEarnedMeta = const VerificationMeta(
    'totalCoinsEarned',
  );
  @override
  late final GeneratedColumn<int> totalCoinsEarned = GeneratedColumn<int>(
    'total_coins_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _amountSavedMeta = const VerificationMeta(
    'amountSaved',
  );
  @override
  late final GeneratedColumn<int> amountSaved = GeneratedColumn<int>(
    'amount_saved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _amountRolledToNextMeta =
      const VerificationMeta('amountRolledToNext');
  @override
  late final GeneratedColumn<int> amountRolledToNext = GeneratedColumn<int>(
    'amount_rolled_to_next',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    totalFoundationIncome,
    totalBonusIncome,
    totalSpentPlanned,
    totalSpentUnplanned,
    totalSpent,
    surplus,
    resultTier,
    overallBonusCoins,
    perPlotCoins,
    surplusSavedCoins,
    totalCoinsEarned,
    amountSaved,
    amountRolledToNext,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycle_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CycleSummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('total_foundation_income')) {
      context.handle(
        _totalFoundationIncomeMeta,
        totalFoundationIncome.isAcceptableOrUnknown(
          data['total_foundation_income']!,
          _totalFoundationIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalFoundationIncomeMeta);
    }
    if (data.containsKey('total_bonus_income')) {
      context.handle(
        _totalBonusIncomeMeta,
        totalBonusIncome.isAcceptableOrUnknown(
          data['total_bonus_income']!,
          _totalBonusIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalBonusIncomeMeta);
    }
    if (data.containsKey('total_spent_planned')) {
      context.handle(
        _totalSpentPlannedMeta,
        totalSpentPlanned.isAcceptableOrUnknown(
          data['total_spent_planned']!,
          _totalSpentPlannedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSpentPlannedMeta);
    }
    if (data.containsKey('total_spent_unplanned')) {
      context.handle(
        _totalSpentUnplannedMeta,
        totalSpentUnplanned.isAcceptableOrUnknown(
          data['total_spent_unplanned']!,
          _totalSpentUnplannedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSpentUnplannedMeta);
    }
    if (data.containsKey('total_spent')) {
      context.handle(
        _totalSpentMeta,
        totalSpent.isAcceptableOrUnknown(data['total_spent']!, _totalSpentMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSpentMeta);
    }
    if (data.containsKey('surplus')) {
      context.handle(
        _surplusMeta,
        surplus.isAcceptableOrUnknown(data['surplus']!, _surplusMeta),
      );
    } else if (isInserting) {
      context.missing(_surplusMeta);
    }
    if (data.containsKey('overall_bonus_coins')) {
      context.handle(
        _overallBonusCoinsMeta,
        overallBonusCoins.isAcceptableOrUnknown(
          data['overall_bonus_coins']!,
          _overallBonusCoinsMeta,
        ),
      );
    }
    if (data.containsKey('per_plot_coins')) {
      context.handle(
        _perPlotCoinsMeta,
        perPlotCoins.isAcceptableOrUnknown(
          data['per_plot_coins']!,
          _perPlotCoinsMeta,
        ),
      );
    }
    if (data.containsKey('surplus_saved_coins')) {
      context.handle(
        _surplusSavedCoinsMeta,
        surplusSavedCoins.isAcceptableOrUnknown(
          data['surplus_saved_coins']!,
          _surplusSavedCoinsMeta,
        ),
      );
    }
    if (data.containsKey('total_coins_earned')) {
      context.handle(
        _totalCoinsEarnedMeta,
        totalCoinsEarned.isAcceptableOrUnknown(
          data['total_coins_earned']!,
          _totalCoinsEarnedMeta,
        ),
      );
    }
    if (data.containsKey('amount_saved')) {
      context.handle(
        _amountSavedMeta,
        amountSaved.isAcceptableOrUnknown(
          data['amount_saved']!,
          _amountSavedMeta,
        ),
      );
    }
    if (data.containsKey('amount_rolled_to_next')) {
      context.handle(
        _amountRolledToNextMeta,
        amountRolledToNext.isAcceptableOrUnknown(
          data['amount_rolled_to_next']!,
          _amountRolledToNextMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CycleSummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CycleSummaryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      totalFoundationIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_foundation_income'],
      )!,
      totalBonusIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bonus_income'],
      )!,
      totalSpentPlanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_spent_planned'],
      )!,
      totalSpentUnplanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_spent_unplanned'],
      )!,
      totalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_spent'],
      )!,
      surplus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surplus'],
      )!,
      resultTier: $CycleSummariesTable.$converterresultTier.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result_tier'],
        )!,
      ),
      overallBonusCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_bonus_coins'],
      )!,
      perPlotCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}per_plot_coins'],
      )!,
      surplusSavedCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surplus_saved_coins'],
      )!,
      totalCoinsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_coins_earned'],
      )!,
      amountSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_saved'],
      )!,
      amountRolledToNext: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rolled_to_next'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $CycleSummariesTable createAlias(String alias) {
    return $CycleSummariesTable(attachedDatabase, alias);
  }

  static TypeConverter<CycleResultTier, String> $converterresultTier =
      const SnakeEnumConverter<CycleResultTier>(CycleResultTier.values);
}

class CycleSummaryRow extends DataClass implements Insertable<CycleSummaryRow> {
  final int id;
  final int cycleId;
  final int totalFoundationIncome;
  final int totalBonusIncome;
  final int totalSpentPlanned;
  final int totalSpentUnplanned;
  final int totalSpent;
  final int surplus;
  final CycleResultTier resultTier;
  final int overallBonusCoins;
  final int perPlotCoins;
  final int surplusSavedCoins;
  final int totalCoinsEarned;
  final int amountSaved;
  final int amountRolledToNext;
  final int completedAt;
  const CycleSummaryRow({
    required this.id,
    required this.cycleId,
    required this.totalFoundationIncome,
    required this.totalBonusIncome,
    required this.totalSpentPlanned,
    required this.totalSpentUnplanned,
    required this.totalSpent,
    required this.surplus,
    required this.resultTier,
    required this.overallBonusCoins,
    required this.perPlotCoins,
    required this.surplusSavedCoins,
    required this.totalCoinsEarned,
    required this.amountSaved,
    required this.amountRolledToNext,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['total_foundation_income'] = Variable<int>(totalFoundationIncome);
    map['total_bonus_income'] = Variable<int>(totalBonusIncome);
    map['total_spent_planned'] = Variable<int>(totalSpentPlanned);
    map['total_spent_unplanned'] = Variable<int>(totalSpentUnplanned);
    map['total_spent'] = Variable<int>(totalSpent);
    map['surplus'] = Variable<int>(surplus);
    {
      map['result_tier'] = Variable<String>(
        $CycleSummariesTable.$converterresultTier.toSql(resultTier),
      );
    }
    map['overall_bonus_coins'] = Variable<int>(overallBonusCoins);
    map['per_plot_coins'] = Variable<int>(perPlotCoins);
    map['surplus_saved_coins'] = Variable<int>(surplusSavedCoins);
    map['total_coins_earned'] = Variable<int>(totalCoinsEarned);
    map['amount_saved'] = Variable<int>(amountSaved);
    map['amount_rolled_to_next'] = Variable<int>(amountRolledToNext);
    map['completed_at'] = Variable<int>(completedAt);
    return map;
  }

  CycleSummariesCompanion toCompanion(bool nullToAbsent) {
    return CycleSummariesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      totalFoundationIncome: Value(totalFoundationIncome),
      totalBonusIncome: Value(totalBonusIncome),
      totalSpentPlanned: Value(totalSpentPlanned),
      totalSpentUnplanned: Value(totalSpentUnplanned),
      totalSpent: Value(totalSpent),
      surplus: Value(surplus),
      resultTier: Value(resultTier),
      overallBonusCoins: Value(overallBonusCoins),
      perPlotCoins: Value(perPlotCoins),
      surplusSavedCoins: Value(surplusSavedCoins),
      totalCoinsEarned: Value(totalCoinsEarned),
      amountSaved: Value(amountSaved),
      amountRolledToNext: Value(amountRolledToNext),
      completedAt: Value(completedAt),
    );
  }

  factory CycleSummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CycleSummaryRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      totalFoundationIncome: serializer.fromJson<int>(
        json['totalFoundationIncome'],
      ),
      totalBonusIncome: serializer.fromJson<int>(json['totalBonusIncome']),
      totalSpentPlanned: serializer.fromJson<int>(json['totalSpentPlanned']),
      totalSpentUnplanned: serializer.fromJson<int>(
        json['totalSpentUnplanned'],
      ),
      totalSpent: serializer.fromJson<int>(json['totalSpent']),
      surplus: serializer.fromJson<int>(json['surplus']),
      resultTier: serializer.fromJson<CycleResultTier>(json['resultTier']),
      overallBonusCoins: serializer.fromJson<int>(json['overallBonusCoins']),
      perPlotCoins: serializer.fromJson<int>(json['perPlotCoins']),
      surplusSavedCoins: serializer.fromJson<int>(json['surplusSavedCoins']),
      totalCoinsEarned: serializer.fromJson<int>(json['totalCoinsEarned']),
      amountSaved: serializer.fromJson<int>(json['amountSaved']),
      amountRolledToNext: serializer.fromJson<int>(json['amountRolledToNext']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'totalFoundationIncome': serializer.toJson<int>(totalFoundationIncome),
      'totalBonusIncome': serializer.toJson<int>(totalBonusIncome),
      'totalSpentPlanned': serializer.toJson<int>(totalSpentPlanned),
      'totalSpentUnplanned': serializer.toJson<int>(totalSpentUnplanned),
      'totalSpent': serializer.toJson<int>(totalSpent),
      'surplus': serializer.toJson<int>(surplus),
      'resultTier': serializer.toJson<CycleResultTier>(resultTier),
      'overallBonusCoins': serializer.toJson<int>(overallBonusCoins),
      'perPlotCoins': serializer.toJson<int>(perPlotCoins),
      'surplusSavedCoins': serializer.toJson<int>(surplusSavedCoins),
      'totalCoinsEarned': serializer.toJson<int>(totalCoinsEarned),
      'amountSaved': serializer.toJson<int>(amountSaved),
      'amountRolledToNext': serializer.toJson<int>(amountRolledToNext),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  CycleSummaryRow copyWith({
    int? id,
    int? cycleId,
    int? totalFoundationIncome,
    int? totalBonusIncome,
    int? totalSpentPlanned,
    int? totalSpentUnplanned,
    int? totalSpent,
    int? surplus,
    CycleResultTier? resultTier,
    int? overallBonusCoins,
    int? perPlotCoins,
    int? surplusSavedCoins,
    int? totalCoinsEarned,
    int? amountSaved,
    int? amountRolledToNext,
    int? completedAt,
  }) => CycleSummaryRow(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    totalFoundationIncome: totalFoundationIncome ?? this.totalFoundationIncome,
    totalBonusIncome: totalBonusIncome ?? this.totalBonusIncome,
    totalSpentPlanned: totalSpentPlanned ?? this.totalSpentPlanned,
    totalSpentUnplanned: totalSpentUnplanned ?? this.totalSpentUnplanned,
    totalSpent: totalSpent ?? this.totalSpent,
    surplus: surplus ?? this.surplus,
    resultTier: resultTier ?? this.resultTier,
    overallBonusCoins: overallBonusCoins ?? this.overallBonusCoins,
    perPlotCoins: perPlotCoins ?? this.perPlotCoins,
    surplusSavedCoins: surplusSavedCoins ?? this.surplusSavedCoins,
    totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
    amountSaved: amountSaved ?? this.amountSaved,
    amountRolledToNext: amountRolledToNext ?? this.amountRolledToNext,
    completedAt: completedAt ?? this.completedAt,
  );
  CycleSummaryRow copyWithCompanion(CycleSummariesCompanion data) {
    return CycleSummaryRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      totalFoundationIncome: data.totalFoundationIncome.present
          ? data.totalFoundationIncome.value
          : this.totalFoundationIncome,
      totalBonusIncome: data.totalBonusIncome.present
          ? data.totalBonusIncome.value
          : this.totalBonusIncome,
      totalSpentPlanned: data.totalSpentPlanned.present
          ? data.totalSpentPlanned.value
          : this.totalSpentPlanned,
      totalSpentUnplanned: data.totalSpentUnplanned.present
          ? data.totalSpentUnplanned.value
          : this.totalSpentUnplanned,
      totalSpent: data.totalSpent.present
          ? data.totalSpent.value
          : this.totalSpent,
      surplus: data.surplus.present ? data.surplus.value : this.surplus,
      resultTier: data.resultTier.present
          ? data.resultTier.value
          : this.resultTier,
      overallBonusCoins: data.overallBonusCoins.present
          ? data.overallBonusCoins.value
          : this.overallBonusCoins,
      perPlotCoins: data.perPlotCoins.present
          ? data.perPlotCoins.value
          : this.perPlotCoins,
      surplusSavedCoins: data.surplusSavedCoins.present
          ? data.surplusSavedCoins.value
          : this.surplusSavedCoins,
      totalCoinsEarned: data.totalCoinsEarned.present
          ? data.totalCoinsEarned.value
          : this.totalCoinsEarned,
      amountSaved: data.amountSaved.present
          ? data.amountSaved.value
          : this.amountSaved,
      amountRolledToNext: data.amountRolledToNext.present
          ? data.amountRolledToNext.value
          : this.amountRolledToNext,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CycleSummaryRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('totalFoundationIncome: $totalFoundationIncome, ')
          ..write('totalBonusIncome: $totalBonusIncome, ')
          ..write('totalSpentPlanned: $totalSpentPlanned, ')
          ..write('totalSpentUnplanned: $totalSpentUnplanned, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('surplus: $surplus, ')
          ..write('resultTier: $resultTier, ')
          ..write('overallBonusCoins: $overallBonusCoins, ')
          ..write('perPlotCoins: $perPlotCoins, ')
          ..write('surplusSavedCoins: $surplusSavedCoins, ')
          ..write('totalCoinsEarned: $totalCoinsEarned, ')
          ..write('amountSaved: $amountSaved, ')
          ..write('amountRolledToNext: $amountRolledToNext, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    totalFoundationIncome,
    totalBonusIncome,
    totalSpentPlanned,
    totalSpentUnplanned,
    totalSpent,
    surplus,
    resultTier,
    overallBonusCoins,
    perPlotCoins,
    surplusSavedCoins,
    totalCoinsEarned,
    amountSaved,
    amountRolledToNext,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CycleSummaryRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.totalFoundationIncome == this.totalFoundationIncome &&
          other.totalBonusIncome == this.totalBonusIncome &&
          other.totalSpentPlanned == this.totalSpentPlanned &&
          other.totalSpentUnplanned == this.totalSpentUnplanned &&
          other.totalSpent == this.totalSpent &&
          other.surplus == this.surplus &&
          other.resultTier == this.resultTier &&
          other.overallBonusCoins == this.overallBonusCoins &&
          other.perPlotCoins == this.perPlotCoins &&
          other.surplusSavedCoins == this.surplusSavedCoins &&
          other.totalCoinsEarned == this.totalCoinsEarned &&
          other.amountSaved == this.amountSaved &&
          other.amountRolledToNext == this.amountRolledToNext &&
          other.completedAt == this.completedAt);
}

class CycleSummariesCompanion extends UpdateCompanion<CycleSummaryRow> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<int> totalFoundationIncome;
  final Value<int> totalBonusIncome;
  final Value<int> totalSpentPlanned;
  final Value<int> totalSpentUnplanned;
  final Value<int> totalSpent;
  final Value<int> surplus;
  final Value<CycleResultTier> resultTier;
  final Value<int> overallBonusCoins;
  final Value<int> perPlotCoins;
  final Value<int> surplusSavedCoins;
  final Value<int> totalCoinsEarned;
  final Value<int> amountSaved;
  final Value<int> amountRolledToNext;
  final Value<int> completedAt;
  const CycleSummariesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.totalFoundationIncome = const Value.absent(),
    this.totalBonusIncome = const Value.absent(),
    this.totalSpentPlanned = const Value.absent(),
    this.totalSpentUnplanned = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.surplus = const Value.absent(),
    this.resultTier = const Value.absent(),
    this.overallBonusCoins = const Value.absent(),
    this.perPlotCoins = const Value.absent(),
    this.surplusSavedCoins = const Value.absent(),
    this.totalCoinsEarned = const Value.absent(),
    this.amountSaved = const Value.absent(),
    this.amountRolledToNext = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  CycleSummariesCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required int totalFoundationIncome,
    required int totalBonusIncome,
    required int totalSpentPlanned,
    required int totalSpentUnplanned,
    required int totalSpent,
    required int surplus,
    required CycleResultTier resultTier,
    this.overallBonusCoins = const Value.absent(),
    this.perPlotCoins = const Value.absent(),
    this.surplusSavedCoins = const Value.absent(),
    this.totalCoinsEarned = const Value.absent(),
    this.amountSaved = const Value.absent(),
    this.amountRolledToNext = const Value.absent(),
    required int completedAt,
  }) : cycleId = Value(cycleId),
       totalFoundationIncome = Value(totalFoundationIncome),
       totalBonusIncome = Value(totalBonusIncome),
       totalSpentPlanned = Value(totalSpentPlanned),
       totalSpentUnplanned = Value(totalSpentUnplanned),
       totalSpent = Value(totalSpent),
       surplus = Value(surplus),
       resultTier = Value(resultTier),
       completedAt = Value(completedAt);
  static Insertable<CycleSummaryRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<int>? totalFoundationIncome,
    Expression<int>? totalBonusIncome,
    Expression<int>? totalSpentPlanned,
    Expression<int>? totalSpentUnplanned,
    Expression<int>? totalSpent,
    Expression<int>? surplus,
    Expression<String>? resultTier,
    Expression<int>? overallBonusCoins,
    Expression<int>? perPlotCoins,
    Expression<int>? surplusSavedCoins,
    Expression<int>? totalCoinsEarned,
    Expression<int>? amountSaved,
    Expression<int>? amountRolledToNext,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (totalFoundationIncome != null)
        'total_foundation_income': totalFoundationIncome,
      if (totalBonusIncome != null) 'total_bonus_income': totalBonusIncome,
      if (totalSpentPlanned != null) 'total_spent_planned': totalSpentPlanned,
      if (totalSpentUnplanned != null)
        'total_spent_unplanned': totalSpentUnplanned,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (surplus != null) 'surplus': surplus,
      if (resultTier != null) 'result_tier': resultTier,
      if (overallBonusCoins != null) 'overall_bonus_coins': overallBonusCoins,
      if (perPlotCoins != null) 'per_plot_coins': perPlotCoins,
      if (surplusSavedCoins != null) 'surplus_saved_coins': surplusSavedCoins,
      if (totalCoinsEarned != null) 'total_coins_earned': totalCoinsEarned,
      if (amountSaved != null) 'amount_saved': amountSaved,
      if (amountRolledToNext != null)
        'amount_rolled_to_next': amountRolledToNext,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  CycleSummariesCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<int>? totalFoundationIncome,
    Value<int>? totalBonusIncome,
    Value<int>? totalSpentPlanned,
    Value<int>? totalSpentUnplanned,
    Value<int>? totalSpent,
    Value<int>? surplus,
    Value<CycleResultTier>? resultTier,
    Value<int>? overallBonusCoins,
    Value<int>? perPlotCoins,
    Value<int>? surplusSavedCoins,
    Value<int>? totalCoinsEarned,
    Value<int>? amountSaved,
    Value<int>? amountRolledToNext,
    Value<int>? completedAt,
  }) {
    return CycleSummariesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      totalFoundationIncome:
          totalFoundationIncome ?? this.totalFoundationIncome,
      totalBonusIncome: totalBonusIncome ?? this.totalBonusIncome,
      totalSpentPlanned: totalSpentPlanned ?? this.totalSpentPlanned,
      totalSpentUnplanned: totalSpentUnplanned ?? this.totalSpentUnplanned,
      totalSpent: totalSpent ?? this.totalSpent,
      surplus: surplus ?? this.surplus,
      resultTier: resultTier ?? this.resultTier,
      overallBonusCoins: overallBonusCoins ?? this.overallBonusCoins,
      perPlotCoins: perPlotCoins ?? this.perPlotCoins,
      surplusSavedCoins: surplusSavedCoins ?? this.surplusSavedCoins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      amountSaved: amountSaved ?? this.amountSaved,
      amountRolledToNext: amountRolledToNext ?? this.amountRolledToNext,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (totalFoundationIncome.present) {
      map['total_foundation_income'] = Variable<int>(
        totalFoundationIncome.value,
      );
    }
    if (totalBonusIncome.present) {
      map['total_bonus_income'] = Variable<int>(totalBonusIncome.value);
    }
    if (totalSpentPlanned.present) {
      map['total_spent_planned'] = Variable<int>(totalSpentPlanned.value);
    }
    if (totalSpentUnplanned.present) {
      map['total_spent_unplanned'] = Variable<int>(totalSpentUnplanned.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<int>(totalSpent.value);
    }
    if (surplus.present) {
      map['surplus'] = Variable<int>(surplus.value);
    }
    if (resultTier.present) {
      map['result_tier'] = Variable<String>(
        $CycleSummariesTable.$converterresultTier.toSql(resultTier.value),
      );
    }
    if (overallBonusCoins.present) {
      map['overall_bonus_coins'] = Variable<int>(overallBonusCoins.value);
    }
    if (perPlotCoins.present) {
      map['per_plot_coins'] = Variable<int>(perPlotCoins.value);
    }
    if (surplusSavedCoins.present) {
      map['surplus_saved_coins'] = Variable<int>(surplusSavedCoins.value);
    }
    if (totalCoinsEarned.present) {
      map['total_coins_earned'] = Variable<int>(totalCoinsEarned.value);
    }
    if (amountSaved.present) {
      map['amount_saved'] = Variable<int>(amountSaved.value);
    }
    if (amountRolledToNext.present) {
      map['amount_rolled_to_next'] = Variable<int>(amountRolledToNext.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CycleSummariesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('totalFoundationIncome: $totalFoundationIncome, ')
          ..write('totalBonusIncome: $totalBonusIncome, ')
          ..write('totalSpentPlanned: $totalSpentPlanned, ')
          ..write('totalSpentUnplanned: $totalSpentUnplanned, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('surplus: $surplus, ')
          ..write('resultTier: $resultTier, ')
          ..write('overallBonusCoins: $overallBonusCoins, ')
          ..write('perPlotCoins: $perPlotCoins, ')
          ..write('surplusSavedCoins: $surplusSavedCoins, ')
          ..write('totalCoinsEarned: $totalCoinsEarned, ')
          ..write('amountSaved: $amountSaved, ')
          ..write('amountRolledToNext: $amountRolledToNext, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _fromCurrencyCodeMeta = const VerificationMeta(
    'fromCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> fromCurrencyCode = GeneratedColumn<String>(
    'from_currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _toCurrencyCodeMeta = const VerificationMeta(
    'toCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> toCurrencyCode = GeneratedColumn<String>(
    'to_currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setAtMeta = const VerificationMeta('setAt');
  @override
  late final GeneratedColumn<int> setAt = GeneratedColumn<int>(
    'set_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    fromCurrencyCode,
    toCurrencyCode,
    rate,
    setAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExchangeRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('from_currency_code')) {
      context.handle(
        _fromCurrencyCodeMeta,
        fromCurrencyCode.isAcceptableOrUnknown(
          data['from_currency_code']!,
          _fromCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCurrencyCodeMeta);
    }
    if (data.containsKey('to_currency_code')) {
      context.handle(
        _toCurrencyCodeMeta,
        toCurrencyCode.isAcceptableOrUnknown(
          data['to_currency_code']!,
          _toCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toCurrencyCodeMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('set_at')) {
      context.handle(
        _setAtMeta,
        setAt.isAcceptableOrUnknown(data['set_at']!, _setAtMeta),
      );
    } else if (isInserting) {
      context.missing(_setAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cycleId, fromCurrencyCode, toCurrencyCode},
  ];
  @override
  ExchangeRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      fromCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_currency_code'],
      )!,
      toCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_currency_code'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      setAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_at'],
      )!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRateRow extends DataClass implements Insertable<ExchangeRateRow> {
  final int id;
  final int cycleId;
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final double rate;
  final int setAt;
  const ExchangeRateRow({
    required this.id,
    required this.cycleId,
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.rate,
    required this.setAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['from_currency_code'] = Variable<String>(fromCurrencyCode);
    map['to_currency_code'] = Variable<String>(toCurrencyCode);
    map['rate'] = Variable<double>(rate);
    map['set_at'] = Variable<int>(setAt);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      fromCurrencyCode: Value(fromCurrencyCode),
      toCurrencyCode: Value(toCurrencyCode),
      rate: Value(rate),
      setAt: Value(setAt),
    );
  }

  factory ExchangeRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRateRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      fromCurrencyCode: serializer.fromJson<String>(json['fromCurrencyCode']),
      toCurrencyCode: serializer.fromJson<String>(json['toCurrencyCode']),
      rate: serializer.fromJson<double>(json['rate']),
      setAt: serializer.fromJson<int>(json['setAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'fromCurrencyCode': serializer.toJson<String>(fromCurrencyCode),
      'toCurrencyCode': serializer.toJson<String>(toCurrencyCode),
      'rate': serializer.toJson<double>(rate),
      'setAt': serializer.toJson<int>(setAt),
    };
  }

  ExchangeRateRow copyWith({
    int? id,
    int? cycleId,
    String? fromCurrencyCode,
    String? toCurrencyCode,
    double? rate,
    int? setAt,
  }) => ExchangeRateRow(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
    toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
    rate: rate ?? this.rate,
    setAt: setAt ?? this.setAt,
  );
  ExchangeRateRow copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRateRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      fromCurrencyCode: data.fromCurrencyCode.present
          ? data.fromCurrencyCode.value
          : this.fromCurrencyCode,
      toCurrencyCode: data.toCurrencyCode.present
          ? data.toCurrencyCode.value
          : this.toCurrencyCode,
      rate: data.rate.present ? data.rate.value : this.rate,
      setAt: data.setAt.present ? data.setAt.value : this.setAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRateRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('fromCurrencyCode: $fromCurrencyCode, ')
          ..write('toCurrencyCode: $toCurrencyCode, ')
          ..write('rate: $rate, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, fromCurrencyCode, toCurrencyCode, rate, setAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRateRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.fromCurrencyCode == this.fromCurrencyCode &&
          other.toCurrencyCode == this.toCurrencyCode &&
          other.rate == this.rate &&
          other.setAt == this.setAt);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRateRow> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<String> fromCurrencyCode;
  final Value<String> toCurrencyCode;
  final Value<double> rate;
  final Value<int> setAt;
  const ExchangeRatesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.fromCurrencyCode = const Value.absent(),
    this.toCurrencyCode = const Value.absent(),
    this.rate = const Value.absent(),
    this.setAt = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required double rate,
    required int setAt,
  }) : cycleId = Value(cycleId),
       fromCurrencyCode = Value(fromCurrencyCode),
       toCurrencyCode = Value(toCurrencyCode),
       rate = Value(rate),
       setAt = Value(setAt);
  static Insertable<ExchangeRateRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<String>? fromCurrencyCode,
    Expression<String>? toCurrencyCode,
    Expression<double>? rate,
    Expression<int>? setAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (fromCurrencyCode != null) 'from_currency_code': fromCurrencyCode,
      if (toCurrencyCode != null) 'to_currency_code': toCurrencyCode,
      if (rate != null) 'rate': rate,
      if (setAt != null) 'set_at': setAt,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<String>? fromCurrencyCode,
    Value<String>? toCurrencyCode,
    Value<double>? rate,
    Value<int>? setAt,
  }) {
    return ExchangeRatesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
      toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
      rate: rate ?? this.rate,
      setAt: setAt ?? this.setAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (fromCurrencyCode.present) {
      map['from_currency_code'] = Variable<String>(fromCurrencyCode.value);
    }
    if (toCurrencyCode.present) {
      map['to_currency_code'] = Variable<String>(toCurrencyCode.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (setAt.present) {
      map['set_at'] = Variable<int>(setAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('fromCurrencyCode: $fromCurrencyCode, ')
          ..write('toCurrencyCode: $toCurrencyCode, ')
          ..write('rate: $rate, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }
}

class $WellsTable extends Wells with TableInfo<$WellsTable, WellRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WellType, String> wellType =
      GeneratedColumn<String>(
        'well_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WellType>($WellsTable.$converterwellType);
  static const VerificationMeta _isCarryoverMeta = const VerificationMeta(
    'isCarryover',
  );
  @override
  late final GeneratedColumn<bool> isCarryover = GeneratedColumn<bool>(
    'is_carryover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_carryover" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _expectedAmountMeta = const VerificationMeta(
    'expectedAmount',
  );
  @override
  late final GeneratedColumn<int> expectedAmount = GeneratedColumn<int>(
    'expected_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimateMinMeta = const VerificationMeta(
    'estimateMin',
  );
  @override
  late final GeneratedColumn<int> estimateMin = GeneratedColumn<int>(
    'estimate_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimateMaxMeta = const VerificationMeta(
    'estimateMax',
  );
  @override
  late final GeneratedColumn<int> estimateMax = GeneratedColumn<int>(
    'estimate_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wellIconIdMeta = const VerificationMeta(
    'wellIconId',
  );
  @override
  late final GeneratedColumn<String> wellIconId = GeneratedColumn<String>(
    'well_icon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    wellType,
    isCarryover,
    currencyCode,
    expectedAmount,
    estimateMin,
    estimateMax,
    wellIconId,
    isActive,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wells';
  @override
  VerificationContext validateIntegrity(
    Insertable<WellRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_carryover')) {
      context.handle(
        _isCarryoverMeta,
        isCarryover.isAcceptableOrUnknown(
          data['is_carryover']!,
          _isCarryoverMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('expected_amount')) {
      context.handle(
        _expectedAmountMeta,
        expectedAmount.isAcceptableOrUnknown(
          data['expected_amount']!,
          _expectedAmountMeta,
        ),
      );
    }
    if (data.containsKey('estimate_min')) {
      context.handle(
        _estimateMinMeta,
        estimateMin.isAcceptableOrUnknown(
          data['estimate_min']!,
          _estimateMinMeta,
        ),
      );
    }
    if (data.containsKey('estimate_max')) {
      context.handle(
        _estimateMaxMeta,
        estimateMax.isAcceptableOrUnknown(
          data['estimate_max']!,
          _estimateMaxMeta,
        ),
      );
    }
    if (data.containsKey('well_icon_id')) {
      context.handle(
        _wellIconIdMeta,
        wellIconId.isAcceptableOrUnknown(
          data['well_icon_id']!,
          _wellIconIdMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WellRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WellRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      wellType: $WellsTable.$converterwellType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}well_type'],
        )!,
      ),
      isCarryover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_carryover'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      expectedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_amount'],
      ),
      estimateMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_min'],
      ),
      estimateMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_max'],
      ),
      wellIconId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}well_icon_id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WellsTable createAlias(String alias) {
    return $WellsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WellType, String, String> $converterwellType =
      const EnumNameConverter<WellType>(WellType.values);
}

class WellRow extends DataClass implements Insertable<WellRow> {
  final int id;
  final String name;
  final WellType wellType;
  final bool isCarryover;
  final String currencyCode;
  final int? expectedAmount;
  final int? estimateMin;
  final int? estimateMax;
  final String wellIconId;
  final bool isActive;
  final int displayOrder;
  final int createdAt;
  const WellRow({
    required this.id,
    required this.name,
    required this.wellType,
    required this.isCarryover,
    required this.currencyCode,
    this.expectedAmount,
    this.estimateMin,
    this.estimateMax,
    required this.wellIconId,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['well_type'] = Variable<String>(
        $WellsTable.$converterwellType.toSql(wellType),
      );
    }
    map['is_carryover'] = Variable<bool>(isCarryover);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || expectedAmount != null) {
      map['expected_amount'] = Variable<int>(expectedAmount);
    }
    if (!nullToAbsent || estimateMin != null) {
      map['estimate_min'] = Variable<int>(estimateMin);
    }
    if (!nullToAbsent || estimateMax != null) {
      map['estimate_max'] = Variable<int>(estimateMax);
    }
    map['well_icon_id'] = Variable<String>(wellIconId);
    map['is_active'] = Variable<bool>(isActive);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WellsCompanion toCompanion(bool nullToAbsent) {
    return WellsCompanion(
      id: Value(id),
      name: Value(name),
      wellType: Value(wellType),
      isCarryover: Value(isCarryover),
      currencyCode: Value(currencyCode),
      expectedAmount: expectedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedAmount),
      estimateMin: estimateMin == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMin),
      estimateMax: estimateMax == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMax),
      wellIconId: Value(wellIconId),
      isActive: Value(isActive),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory WellRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WellRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      wellType: $WellsTable.$converterwellType.fromJson(
        serializer.fromJson<String>(json['wellType']),
      ),
      isCarryover: serializer.fromJson<bool>(json['isCarryover']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      expectedAmount: serializer.fromJson<int?>(json['expectedAmount']),
      estimateMin: serializer.fromJson<int?>(json['estimateMin']),
      estimateMax: serializer.fromJson<int?>(json['estimateMax']),
      wellIconId: serializer.fromJson<String>(json['wellIconId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'wellType': serializer.toJson<String>(
        $WellsTable.$converterwellType.toJson(wellType),
      ),
      'isCarryover': serializer.toJson<bool>(isCarryover),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'expectedAmount': serializer.toJson<int?>(expectedAmount),
      'estimateMin': serializer.toJson<int?>(estimateMin),
      'estimateMax': serializer.toJson<int?>(estimateMax),
      'wellIconId': serializer.toJson<String>(wellIconId),
      'isActive': serializer.toJson<bool>(isActive),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WellRow copyWith({
    int? id,
    String? name,
    WellType? wellType,
    bool? isCarryover,
    String? currencyCode,
    Value<int?> expectedAmount = const Value.absent(),
    Value<int?> estimateMin = const Value.absent(),
    Value<int?> estimateMax = const Value.absent(),
    String? wellIconId,
    bool? isActive,
    int? displayOrder,
    int? createdAt,
  }) => WellRow(
    id: id ?? this.id,
    name: name ?? this.name,
    wellType: wellType ?? this.wellType,
    isCarryover: isCarryover ?? this.isCarryover,
    currencyCode: currencyCode ?? this.currencyCode,
    expectedAmount: expectedAmount.present
        ? expectedAmount.value
        : this.expectedAmount,
    estimateMin: estimateMin.present ? estimateMin.value : this.estimateMin,
    estimateMax: estimateMax.present ? estimateMax.value : this.estimateMax,
    wellIconId: wellIconId ?? this.wellIconId,
    isActive: isActive ?? this.isActive,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  WellRow copyWithCompanion(WellsCompanion data) {
    return WellRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      wellType: data.wellType.present ? data.wellType.value : this.wellType,
      isCarryover: data.isCarryover.present
          ? data.isCarryover.value
          : this.isCarryover,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      expectedAmount: data.expectedAmount.present
          ? data.expectedAmount.value
          : this.expectedAmount,
      estimateMin: data.estimateMin.present
          ? data.estimateMin.value
          : this.estimateMin,
      estimateMax: data.estimateMax.present
          ? data.estimateMax.value
          : this.estimateMax,
      wellIconId: data.wellIconId.present
          ? data.wellIconId.value
          : this.wellIconId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WellRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wellType: $wellType, ')
          ..write('isCarryover: $isCarryover, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('estimateMin: $estimateMin, ')
          ..write('estimateMax: $estimateMax, ')
          ..write('wellIconId: $wellIconId, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    wellType,
    isCarryover,
    currencyCode,
    expectedAmount,
    estimateMin,
    estimateMax,
    wellIconId,
    isActive,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WellRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.wellType == this.wellType &&
          other.isCarryover == this.isCarryover &&
          other.currencyCode == this.currencyCode &&
          other.expectedAmount == this.expectedAmount &&
          other.estimateMin == this.estimateMin &&
          other.estimateMax == this.estimateMax &&
          other.wellIconId == this.wellIconId &&
          other.isActive == this.isActive &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class WellsCompanion extends UpdateCompanion<WellRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<WellType> wellType;
  final Value<bool> isCarryover;
  final Value<String> currencyCode;
  final Value<int?> expectedAmount;
  final Value<int?> estimateMin;
  final Value<int?> estimateMax;
  final Value<String> wellIconId;
  final Value<bool> isActive;
  final Value<int> displayOrder;
  final Value<int> createdAt;
  const WellsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.wellType = const Value.absent(),
    this.isCarryover = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.expectedAmount = const Value.absent(),
    this.estimateMin = const Value.absent(),
    this.estimateMax = const Value.absent(),
    this.wellIconId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WellsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required WellType wellType,
    this.isCarryover = const Value.absent(),
    required String currencyCode,
    this.expectedAmount = const Value.absent(),
    this.estimateMin = const Value.absent(),
    this.estimateMax = const Value.absent(),
    this.wellIconId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       wellType = Value(wellType),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt);
  static Insertable<WellRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? wellType,
    Expression<bool>? isCarryover,
    Expression<String>? currencyCode,
    Expression<int>? expectedAmount,
    Expression<int>? estimateMin,
    Expression<int>? estimateMax,
    Expression<String>? wellIconId,
    Expression<bool>? isActive,
    Expression<int>? displayOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (wellType != null) 'well_type': wellType,
      if (isCarryover != null) 'is_carryover': isCarryover,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (estimateMin != null) 'estimate_min': estimateMin,
      if (estimateMax != null) 'estimate_max': estimateMax,
      if (wellIconId != null) 'well_icon_id': wellIconId,
      if (isActive != null) 'is_active': isActive,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WellsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<WellType>? wellType,
    Value<bool>? isCarryover,
    Value<String>? currencyCode,
    Value<int?>? expectedAmount,
    Value<int?>? estimateMin,
    Value<int?>? estimateMax,
    Value<String>? wellIconId,
    Value<bool>? isActive,
    Value<int>? displayOrder,
    Value<int>? createdAt,
  }) {
    return WellsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      wellType: wellType ?? this.wellType,
      isCarryover: isCarryover ?? this.isCarryover,
      currencyCode: currencyCode ?? this.currencyCode,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      estimateMin: estimateMin ?? this.estimateMin,
      estimateMax: estimateMax ?? this.estimateMax,
      wellIconId: wellIconId ?? this.wellIconId,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (wellType.present) {
      map['well_type'] = Variable<String>(
        $WellsTable.$converterwellType.toSql(wellType.value),
      );
    }
    if (isCarryover.present) {
      map['is_carryover'] = Variable<bool>(isCarryover.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (expectedAmount.present) {
      map['expected_amount'] = Variable<int>(expectedAmount.value);
    }
    if (estimateMin.present) {
      map['estimate_min'] = Variable<int>(estimateMin.value);
    }
    if (estimateMax.present) {
      map['estimate_max'] = Variable<int>(estimateMax.value);
    }
    if (wellIconId.present) {
      map['well_icon_id'] = Variable<String>(wellIconId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WellsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('wellType: $wellType, ')
          ..write('isCarryover: $isCarryover, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('estimateMin: $estimateMin, ')
          ..write('estimateMax: $estimateMax, ')
          ..write('wellIconId: $wellIconId, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IncomeEntriesTable extends IncomeEntries
    with TableInfo<$IncomeEntriesTable, IncomeEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wellIdMeta = const VerificationMeta('wellId');
  @override
  late final GeneratedColumn<int> wellId = GeneratedColumn<int>(
    'well_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wells (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _baseAmountMeta = const VerificationMeta(
    'baseAmount',
  );
  @override
  late final GeneratedColumn<int> baseAmount = GeneratedColumn<int>(
    'base_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemGeneratedMeta = const VerificationMeta(
    'isSystemGenerated',
  );
  @override
  late final GeneratedColumn<bool> isSystemGenerated = GeneratedColumn<bool>(
    'is_system_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_generated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wellId,
    cycleId,
    amount,
    currencyCode,
    baseAmount,
    exchangeRate,
    receivedAt,
    note,
    isSystemGenerated,
    createdAt,
    editedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('well_id')) {
      context.handle(
        _wellIdMeta,
        wellId.isAcceptableOrUnknown(data['well_id']!, _wellIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wellIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('base_amount')) {
      context.handle(
        _baseAmountMeta,
        baseAmount.isAcceptableOrUnknown(data['base_amount']!, _baseAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_baseAmountMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exchangeRateMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_system_generated')) {
      context.handle(
        _isSystemGeneratedMeta,
        isSystemGenerated.isAcceptableOrUnknown(
          data['is_system_generated']!,
          _isSystemGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wellId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}well_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isSystemGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_generated'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $IncomeEntriesTable createAlias(String alias) {
    return $IncomeEntriesTable(attachedDatabase, alias);
  }
}

class IncomeEntryRow extends DataClass implements Insertable<IncomeEntryRow> {
  final int id;
  final int wellId;
  final int cycleId;
  final int amount;
  final String currencyCode;
  final int baseAmount;
  final double exchangeRate;
  final int receivedAt;
  final String? note;
  final bool isSystemGenerated;
  final int createdAt;
  final int? editedAt;
  final int? deletedAt;
  const IncomeEntryRow({
    required this.id,
    required this.wellId,
    required this.cycleId,
    required this.amount,
    required this.currencyCode,
    required this.baseAmount,
    required this.exchangeRate,
    required this.receivedAt,
    this.note,
    required this.isSystemGenerated,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['well_id'] = Variable<int>(wellId);
    map['cycle_id'] = Variable<int>(cycleId);
    map['amount'] = Variable<int>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['base_amount'] = Variable<int>(baseAmount);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['received_at'] = Variable<int>(receivedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_system_generated'] = Variable<bool>(isSystemGenerated);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  IncomeEntriesCompanion toCompanion(bool nullToAbsent) {
    return IncomeEntriesCompanion(
      id: Value(id),
      wellId: Value(wellId),
      cycleId: Value(cycleId),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      baseAmount: Value(baseAmount),
      exchangeRate: Value(exchangeRate),
      receivedAt: Value(receivedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isSystemGenerated: Value(isSystemGenerated),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory IncomeEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeEntryRow(
      id: serializer.fromJson<int>(json['id']),
      wellId: serializer.fromJson<int>(json['wellId']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      amount: serializer.fromJson<int>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
      note: serializer.fromJson<String?>(json['note']),
      isSystemGenerated: serializer.fromJson<bool>(json['isSystemGenerated']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wellId': serializer.toJson<int>(wellId),
      'cycleId': serializer.toJson<int>(cycleId),
      'amount': serializer.toJson<int>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'receivedAt': serializer.toJson<int>(receivedAt),
      'note': serializer.toJson<String?>(note),
      'isSystemGenerated': serializer.toJson<bool>(isSystemGenerated),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  IncomeEntryRow copyWith({
    int? id,
    int? wellId,
    int? cycleId,
    int? amount,
    String? currencyCode,
    int? baseAmount,
    double? exchangeRate,
    int? receivedAt,
    Value<String?> note = const Value.absent(),
    bool? isSystemGenerated,
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => IncomeEntryRow(
    id: id ?? this.id,
    wellId: wellId ?? this.wellId,
    cycleId: cycleId ?? this.cycleId,
    amount: amount ?? this.amount,
    currencyCode: currencyCode ?? this.currencyCode,
    baseAmount: baseAmount ?? this.baseAmount,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    receivedAt: receivedAt ?? this.receivedAt,
    note: note.present ? note.value : this.note,
    isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  IncomeEntryRow copyWithCompanion(IncomeEntriesCompanion data) {
    return IncomeEntryRow(
      id: data.id.present ? data.id.value : this.id,
      wellId: data.wellId.present ? data.wellId.value : this.wellId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      note: data.note.present ? data.note.value : this.note,
      isSystemGenerated: data.isSystemGenerated.present
          ? data.isSystemGenerated.value
          : this.isSystemGenerated,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeEntryRow(')
          ..write('id: $id, ')
          ..write('wellId: $wellId, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note, ')
          ..write('isSystemGenerated: $isSystemGenerated, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wellId,
    cycleId,
    amount,
    currencyCode,
    baseAmount,
    exchangeRate,
    receivedAt,
    note,
    isSystemGenerated,
    createdAt,
    editedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeEntryRow &&
          other.id == this.id &&
          other.wellId == this.wellId &&
          other.cycleId == this.cycleId &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.baseAmount == this.baseAmount &&
          other.exchangeRate == this.exchangeRate &&
          other.receivedAt == this.receivedAt &&
          other.note == this.note &&
          other.isSystemGenerated == this.isSystemGenerated &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt);
}

class IncomeEntriesCompanion extends UpdateCompanion<IncomeEntryRow> {
  final Value<int> id;
  final Value<int> wellId;
  final Value<int> cycleId;
  final Value<int> amount;
  final Value<String> currencyCode;
  final Value<int> baseAmount;
  final Value<double> exchangeRate;
  final Value<int> receivedAt;
  final Value<String?> note;
  final Value<bool> isSystemGenerated;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int?> deletedAt;
  const IncomeEntriesCompanion({
    this.id = const Value.absent(),
    this.wellId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.isSystemGenerated = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  IncomeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int wellId,
    required int cycleId,
    required int amount,
    required String currencyCode,
    required int baseAmount,
    required double exchangeRate,
    required int receivedAt,
    this.note = const Value.absent(),
    this.isSystemGenerated = const Value.absent(),
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : wellId = Value(wellId),
       cycleId = Value(cycleId),
       amount = Value(amount),
       currencyCode = Value(currencyCode),
       baseAmount = Value(baseAmount),
       exchangeRate = Value(exchangeRate),
       receivedAt = Value(receivedAt),
       createdAt = Value(createdAt);
  static Insertable<IncomeEntryRow> custom({
    Expression<int>? id,
    Expression<int>? wellId,
    Expression<int>? cycleId,
    Expression<int>? amount,
    Expression<String>? currencyCode,
    Expression<int>? baseAmount,
    Expression<double>? exchangeRate,
    Expression<int>? receivedAt,
    Expression<String>? note,
    Expression<bool>? isSystemGenerated,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wellId != null) 'well_id': wellId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (receivedAt != null) 'received_at': receivedAt,
      if (note != null) 'note': note,
      if (isSystemGenerated != null) 'is_system_generated': isSystemGenerated,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  IncomeEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? wellId,
    Value<int>? cycleId,
    Value<int>? amount,
    Value<String>? currencyCode,
    Value<int>? baseAmount,
    Value<double>? exchangeRate,
    Value<int>? receivedAt,
    Value<String?>? note,
    Value<bool>? isSystemGenerated,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int?>? deletedAt,
  }) {
    return IncomeEntriesCompanion(
      id: id ?? this.id,
      wellId: wellId ?? this.wellId,
      cycleId: cycleId ?? this.cycleId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      baseAmount: baseAmount ?? this.baseAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      receivedAt: receivedAt ?? this.receivedAt,
      note: note ?? this.note,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wellId.present) {
      map['well_id'] = Variable<int>(wellId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<int>(baseAmount.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isSystemGenerated.present) {
      map['is_system_generated'] = Variable<bool>(isSystemGenerated.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('wellId: $wellId, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note, ')
          ..write('isSystemGenerated: $isSystemGenerated, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CropsCatalogTable extends CropsCatalog
    with TableInfo<$CropsCatalogTable, CropCatalogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropsCatalogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCoinYieldMeta = const VerificationMeta(
    'baseCoinYield',
  );
  @override
  late final GeneratedColumn<int> baseCoinYield = GeneratedColumn<int>(
    'base_coin_yield',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isStarterMeta = const VerificationMeta(
    'isStarter',
  );
  @override
  late final GeneratedColumn<bool> isStarter = GeneratedColumn<bool>(
    'is_starter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isConsumableMeta = const VerificationMeta(
    'isConsumable',
  );
  @override
  late final GeneratedColumn<bool> isConsumable = GeneratedColumn<bool>(
    'is_consumable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_consumable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _seedPackSizeMeta = const VerificationMeta(
    'seedPackSize',
  );
  @override
  late final GeneratedColumn<int> seedPackSize = GeneratedColumn<int>(
    'seed_pack_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceCoinsMeta = const VerificationMeta(
    'priceCoins',
  );
  @override
  late final GeneratedColumn<int> priceCoins = GeneratedColumn<int>(
    'price_coins',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cropId,
    name,
    baseCoinYield,
    isStarter,
    isConsumable,
    seedPackSize,
    priceCoins,
    description,
    displayOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crops_catalog';
  @override
  VerificationContext validateIntegrity(
    Insertable<CropCatalogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_coin_yield')) {
      context.handle(
        _baseCoinYieldMeta,
        baseCoinYield.isAcceptableOrUnknown(
          data['base_coin_yield']!,
          _baseCoinYieldMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCoinYieldMeta);
    }
    if (data.containsKey('is_starter')) {
      context.handle(
        _isStarterMeta,
        isStarter.isAcceptableOrUnknown(data['is_starter']!, _isStarterMeta),
      );
    }
    if (data.containsKey('is_consumable')) {
      context.handle(
        _isConsumableMeta,
        isConsumable.isAcceptableOrUnknown(
          data['is_consumable']!,
          _isConsumableMeta,
        ),
      );
    }
    if (data.containsKey('seed_pack_size')) {
      context.handle(
        _seedPackSizeMeta,
        seedPackSize.isAcceptableOrUnknown(
          data['seed_pack_size']!,
          _seedPackSizeMeta,
        ),
      );
    }
    if (data.containsKey('price_coins')) {
      context.handle(
        _priceCoinsMeta,
        priceCoins.isAcceptableOrUnknown(data['price_coins']!, _priceCoinsMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cropId};
  @override
  CropCatalogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropCatalogRow(
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseCoinYield: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_coin_yield'],
      )!,
      isStarter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starter'],
      )!,
      isConsumable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_consumable'],
      )!,
      seedPackSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed_pack_size'],
      ),
      priceCoins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_coins'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
    );
  }

  @override
  $CropsCatalogTable createAlias(String alias) {
    return $CropsCatalogTable(attachedDatabase, alias);
  }
}

class CropCatalogRow extends DataClass implements Insertable<CropCatalogRow> {
  final String cropId;
  final String name;
  final int baseCoinYield;
  final bool isStarter;
  final bool isConsumable;
  final int? seedPackSize;
  final int? priceCoins;
  final String? description;
  final int displayOrder;
  const CropCatalogRow({
    required this.cropId,
    required this.name,
    required this.baseCoinYield,
    required this.isStarter,
    required this.isConsumable,
    this.seedPackSize,
    this.priceCoins,
    this.description,
    required this.displayOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['crop_id'] = Variable<String>(cropId);
    map['name'] = Variable<String>(name);
    map['base_coin_yield'] = Variable<int>(baseCoinYield);
    map['is_starter'] = Variable<bool>(isStarter);
    map['is_consumable'] = Variable<bool>(isConsumable);
    if (!nullToAbsent || seedPackSize != null) {
      map['seed_pack_size'] = Variable<int>(seedPackSize);
    }
    if (!nullToAbsent || priceCoins != null) {
      map['price_coins'] = Variable<int>(priceCoins);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['display_order'] = Variable<int>(displayOrder);
    return map;
  }

  CropsCatalogCompanion toCompanion(bool nullToAbsent) {
    return CropsCatalogCompanion(
      cropId: Value(cropId),
      name: Value(name),
      baseCoinYield: Value(baseCoinYield),
      isStarter: Value(isStarter),
      isConsumable: Value(isConsumable),
      seedPackSize: seedPackSize == null && nullToAbsent
          ? const Value.absent()
          : Value(seedPackSize),
      priceCoins: priceCoins == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCoins),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      displayOrder: Value(displayOrder),
    );
  }

  factory CropCatalogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropCatalogRow(
      cropId: serializer.fromJson<String>(json['cropId']),
      name: serializer.fromJson<String>(json['name']),
      baseCoinYield: serializer.fromJson<int>(json['baseCoinYield']),
      isStarter: serializer.fromJson<bool>(json['isStarter']),
      isConsumable: serializer.fromJson<bool>(json['isConsumable']),
      seedPackSize: serializer.fromJson<int?>(json['seedPackSize']),
      priceCoins: serializer.fromJson<int?>(json['priceCoins']),
      description: serializer.fromJson<String?>(json['description']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cropId': serializer.toJson<String>(cropId),
      'name': serializer.toJson<String>(name),
      'baseCoinYield': serializer.toJson<int>(baseCoinYield),
      'isStarter': serializer.toJson<bool>(isStarter),
      'isConsumable': serializer.toJson<bool>(isConsumable),
      'seedPackSize': serializer.toJson<int?>(seedPackSize),
      'priceCoins': serializer.toJson<int?>(priceCoins),
      'description': serializer.toJson<String?>(description),
      'displayOrder': serializer.toJson<int>(displayOrder),
    };
  }

  CropCatalogRow copyWith({
    String? cropId,
    String? name,
    int? baseCoinYield,
    bool? isStarter,
    bool? isConsumable,
    Value<int?> seedPackSize = const Value.absent(),
    Value<int?> priceCoins = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? displayOrder,
  }) => CropCatalogRow(
    cropId: cropId ?? this.cropId,
    name: name ?? this.name,
    baseCoinYield: baseCoinYield ?? this.baseCoinYield,
    isStarter: isStarter ?? this.isStarter,
    isConsumable: isConsumable ?? this.isConsumable,
    seedPackSize: seedPackSize.present ? seedPackSize.value : this.seedPackSize,
    priceCoins: priceCoins.present ? priceCoins.value : this.priceCoins,
    description: description.present ? description.value : this.description,
    displayOrder: displayOrder ?? this.displayOrder,
  );
  CropCatalogRow copyWithCompanion(CropsCatalogCompanion data) {
    return CropCatalogRow(
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      name: data.name.present ? data.name.value : this.name,
      baseCoinYield: data.baseCoinYield.present
          ? data.baseCoinYield.value
          : this.baseCoinYield,
      isStarter: data.isStarter.present ? data.isStarter.value : this.isStarter,
      isConsumable: data.isConsumable.present
          ? data.isConsumable.value
          : this.isConsumable,
      seedPackSize: data.seedPackSize.present
          ? data.seedPackSize.value
          : this.seedPackSize,
      priceCoins: data.priceCoins.present
          ? data.priceCoins.value
          : this.priceCoins,
      description: data.description.present
          ? data.description.value
          : this.description,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropCatalogRow(')
          ..write('cropId: $cropId, ')
          ..write('name: $name, ')
          ..write('baseCoinYield: $baseCoinYield, ')
          ..write('isStarter: $isStarter, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('seedPackSize: $seedPackSize, ')
          ..write('priceCoins: $priceCoins, ')
          ..write('description: $description, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cropId,
    name,
    baseCoinYield,
    isStarter,
    isConsumable,
    seedPackSize,
    priceCoins,
    description,
    displayOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropCatalogRow &&
          other.cropId == this.cropId &&
          other.name == this.name &&
          other.baseCoinYield == this.baseCoinYield &&
          other.isStarter == this.isStarter &&
          other.isConsumable == this.isConsumable &&
          other.seedPackSize == this.seedPackSize &&
          other.priceCoins == this.priceCoins &&
          other.description == this.description &&
          other.displayOrder == this.displayOrder);
}

class CropsCatalogCompanion extends UpdateCompanion<CropCatalogRow> {
  final Value<String> cropId;
  final Value<String> name;
  final Value<int> baseCoinYield;
  final Value<bool> isStarter;
  final Value<bool> isConsumable;
  final Value<int?> seedPackSize;
  final Value<int?> priceCoins;
  final Value<String?> description;
  final Value<int> displayOrder;
  final Value<int> rowid;
  const CropsCatalogCompanion({
    this.cropId = const Value.absent(),
    this.name = const Value.absent(),
    this.baseCoinYield = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.seedPackSize = const Value.absent(),
    this.priceCoins = const Value.absent(),
    this.description = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CropsCatalogCompanion.insert({
    required String cropId,
    required String name,
    required int baseCoinYield,
    this.isStarter = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.seedPackSize = const Value.absent(),
    this.priceCoins = const Value.absent(),
    this.description = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cropId = Value(cropId),
       name = Value(name),
       baseCoinYield = Value(baseCoinYield);
  static Insertable<CropCatalogRow> custom({
    Expression<String>? cropId,
    Expression<String>? name,
    Expression<int>? baseCoinYield,
    Expression<bool>? isStarter,
    Expression<bool>? isConsumable,
    Expression<int>? seedPackSize,
    Expression<int>? priceCoins,
    Expression<String>? description,
    Expression<int>? displayOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cropId != null) 'crop_id': cropId,
      if (name != null) 'name': name,
      if (baseCoinYield != null) 'base_coin_yield': baseCoinYield,
      if (isStarter != null) 'is_starter': isStarter,
      if (isConsumable != null) 'is_consumable': isConsumable,
      if (seedPackSize != null) 'seed_pack_size': seedPackSize,
      if (priceCoins != null) 'price_coins': priceCoins,
      if (description != null) 'description': description,
      if (displayOrder != null) 'display_order': displayOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CropsCatalogCompanion copyWith({
    Value<String>? cropId,
    Value<String>? name,
    Value<int>? baseCoinYield,
    Value<bool>? isStarter,
    Value<bool>? isConsumable,
    Value<int?>? seedPackSize,
    Value<int?>? priceCoins,
    Value<String?>? description,
    Value<int>? displayOrder,
    Value<int>? rowid,
  }) {
    return CropsCatalogCompanion(
      cropId: cropId ?? this.cropId,
      name: name ?? this.name,
      baseCoinYield: baseCoinYield ?? this.baseCoinYield,
      isStarter: isStarter ?? this.isStarter,
      isConsumable: isConsumable ?? this.isConsumable,
      seedPackSize: seedPackSize ?? this.seedPackSize,
      priceCoins: priceCoins ?? this.priceCoins,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseCoinYield.present) {
      map['base_coin_yield'] = Variable<int>(baseCoinYield.value);
    }
    if (isStarter.present) {
      map['is_starter'] = Variable<bool>(isStarter.value);
    }
    if (isConsumable.present) {
      map['is_consumable'] = Variable<bool>(isConsumable.value);
    }
    if (seedPackSize.present) {
      map['seed_pack_size'] = Variable<int>(seedPackSize.value);
    }
    if (priceCoins.present) {
      map['price_coins'] = Variable<int>(priceCoins.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CropsCatalogCompanion(')
          ..write('cropId: $cropId, ')
          ..write('name: $name, ')
          ..write('baseCoinYield: $baseCoinYield, ')
          ..write('isStarter: $isStarter, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('seedPackSize: $seedPackSize, ')
          ..write('priceCoins: $priceCoins, ')
          ..write('description: $description, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlotsTable extends Plots with TableInfo<$PlotsTable, PlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlotKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('discretionary'),
      ).withConverter<PlotKind>($PlotsTable.$converterkind);
  static const VerificationMeta _budgetAmountMeta = const VerificationMeta(
    'budgetAmount',
  );
  @override
  late final GeneratedColumn<int> budgetAmount = GeneratedColumn<int>(
    'budget_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _cropTypeIdMeta = const VerificationMeta(
    'cropTypeId',
  );
  @override
  late final GeneratedColumn<String> cropTypeId = GeneratedColumn<String>(
    'crop_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES crops_catalog (crop_id)',
    ),
  );
  static const VerificationMeta _plotColorIdMeta = const VerificationMeta(
    'plotColorId',
  );
  @override
  late final GeneratedColumn<String> plotColorId = GeneratedColumn<String>(
    'plot_color_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUnplannedMeta = const VerificationMeta(
    'isUnplanned',
  );
  @override
  late final GeneratedColumn<bool> isUnplanned = GeneratedColumn<bool>(
    'is_unplanned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unplanned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    budgetAmount,
    currencyCode,
    cropTypeId,
    plotColorId,
    dueDay,
    isUnplanned,
    isActive,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('budget_amount')) {
      context.handle(
        _budgetAmountMeta,
        budgetAmount.isAcceptableOrUnknown(
          data['budget_amount']!,
          _budgetAmountMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('crop_type_id')) {
      context.handle(
        _cropTypeIdMeta,
        cropTypeId.isAcceptableOrUnknown(
          data['crop_type_id']!,
          _cropTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cropTypeIdMeta);
    }
    if (data.containsKey('plot_color_id')) {
      context.handle(
        _plotColorIdMeta,
        plotColorId.isAcceptableOrUnknown(
          data['plot_color_id']!,
          _plotColorIdMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('is_unplanned')) {
      context.handle(
        _isUnplannedMeta,
        isUnplanned.isAcceptableOrUnknown(
          data['is_unplanned']!,
          _isUnplannedMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $PlotsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      budgetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_amount'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      cropTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_type_id'],
      )!,
      plotColorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_color_id'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      isUnplanned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unplanned'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlotsTable createAlias(String alias) {
    return $PlotsTable(attachedDatabase, alias);
  }

  static TypeConverter<PlotKind, String> $converterkind =
      const SnakeEnumConverter<PlotKind>(PlotKind.values);
}

class PlotRow extends DataClass implements Insertable<PlotRow> {
  final int id;
  final String name;
  final PlotKind kind;
  final int? budgetAmount;
  final String currencyCode;
  final String cropTypeId;
  final String? plotColorId;
  final int? dueDay;
  final bool isUnplanned;
  final bool isActive;
  final int displayOrder;
  final int createdAt;
  const PlotRow({
    required this.id,
    required this.name,
    required this.kind,
    this.budgetAmount,
    required this.currencyCode,
    required this.cropTypeId,
    this.plotColorId,
    this.dueDay,
    required this.isUnplanned,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>($PlotsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || budgetAmount != null) {
      map['budget_amount'] = Variable<int>(budgetAmount);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['crop_type_id'] = Variable<String>(cropTypeId);
    if (!nullToAbsent || plotColorId != null) {
      map['plot_color_id'] = Variable<String>(plotColorId);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['is_unplanned'] = Variable<bool>(isUnplanned);
    map['is_active'] = Variable<bool>(isActive);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlotsCompanion toCompanion(bool nullToAbsent) {
    return PlotsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      budgetAmount: budgetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetAmount),
      currencyCode: Value(currencyCode),
      cropTypeId: Value(cropTypeId),
      plotColorId: plotColorId == null && nullToAbsent
          ? const Value.absent()
          : Value(plotColorId),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      isUnplanned: Value(isUnplanned),
      isActive: Value(isActive),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory PlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlotRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<PlotKind>(json['kind']),
      budgetAmount: serializer.fromJson<int?>(json['budgetAmount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      cropTypeId: serializer.fromJson<String>(json['cropTypeId']),
      plotColorId: serializer.fromJson<String?>(json['plotColorId']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      isUnplanned: serializer.fromJson<bool>(json['isUnplanned']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<PlotKind>(kind),
      'budgetAmount': serializer.toJson<int?>(budgetAmount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'cropTypeId': serializer.toJson<String>(cropTypeId),
      'plotColorId': serializer.toJson<String?>(plotColorId),
      'dueDay': serializer.toJson<int?>(dueDay),
      'isUnplanned': serializer.toJson<bool>(isUnplanned),
      'isActive': serializer.toJson<bool>(isActive),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlotRow copyWith({
    int? id,
    String? name,
    PlotKind? kind,
    Value<int?> budgetAmount = const Value.absent(),
    String? currencyCode,
    String? cropTypeId,
    Value<String?> plotColorId = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    bool? isUnplanned,
    bool? isActive,
    int? displayOrder,
    int? createdAt,
  }) => PlotRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    budgetAmount: budgetAmount.present ? budgetAmount.value : this.budgetAmount,
    currencyCode: currencyCode ?? this.currencyCode,
    cropTypeId: cropTypeId ?? this.cropTypeId,
    plotColorId: plotColorId.present ? plotColorId.value : this.plotColorId,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    isUnplanned: isUnplanned ?? this.isUnplanned,
    isActive: isActive ?? this.isActive,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  PlotRow copyWithCompanion(PlotsCompanion data) {
    return PlotRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      budgetAmount: data.budgetAmount.present
          ? data.budgetAmount.value
          : this.budgetAmount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      cropTypeId: data.cropTypeId.present
          ? data.cropTypeId.value
          : this.cropTypeId,
      plotColorId: data.plotColorId.present
          ? data.plotColorId.value
          : this.plotColorId,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      isUnplanned: data.isUnplanned.present
          ? data.isUnplanned.value
          : this.isUnplanned,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlotRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('budgetAmount: $budgetAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('cropTypeId: $cropTypeId, ')
          ..write('plotColorId: $plotColorId, ')
          ..write('dueDay: $dueDay, ')
          ..write('isUnplanned: $isUnplanned, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    budgetAmount,
    currencyCode,
    cropTypeId,
    plotColorId,
    dueDay,
    isUnplanned,
    isActive,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlotRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.budgetAmount == this.budgetAmount &&
          other.currencyCode == this.currencyCode &&
          other.cropTypeId == this.cropTypeId &&
          other.plotColorId == this.plotColorId &&
          other.dueDay == this.dueDay &&
          other.isUnplanned == this.isUnplanned &&
          other.isActive == this.isActive &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class PlotsCompanion extends UpdateCompanion<PlotRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<PlotKind> kind;
  final Value<int?> budgetAmount;
  final Value<String> currencyCode;
  final Value<String> cropTypeId;
  final Value<String?> plotColorId;
  final Value<int?> dueDay;
  final Value<bool> isUnplanned;
  final Value<bool> isActive;
  final Value<int> displayOrder;
  final Value<int> createdAt;
  const PlotsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.budgetAmount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.cropTypeId = const Value.absent(),
    this.plotColorId = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.isUnplanned = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlotsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.budgetAmount = const Value.absent(),
    required String currencyCode,
    required String cropTypeId,
    this.plotColorId = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.isUnplanned = const Value.absent(),
    this.isActive = const Value.absent(),
    this.displayOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       currencyCode = Value(currencyCode),
       cropTypeId = Value(cropTypeId),
       createdAt = Value(createdAt);
  static Insertable<PlotRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? budgetAmount,
    Expression<String>? currencyCode,
    Expression<String>? cropTypeId,
    Expression<String>? plotColorId,
    Expression<int>? dueDay,
    Expression<bool>? isUnplanned,
    Expression<bool>? isActive,
    Expression<int>? displayOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (budgetAmount != null) 'budget_amount': budgetAmount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (cropTypeId != null) 'crop_type_id': cropTypeId,
      if (plotColorId != null) 'plot_color_id': plotColorId,
      if (dueDay != null) 'due_day': dueDay,
      if (isUnplanned != null) 'is_unplanned': isUnplanned,
      if (isActive != null) 'is_active': isActive,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlotsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<PlotKind>? kind,
    Value<int?>? budgetAmount,
    Value<String>? currencyCode,
    Value<String>? cropTypeId,
    Value<String?>? plotColorId,
    Value<int?>? dueDay,
    Value<bool>? isUnplanned,
    Value<bool>? isActive,
    Value<int>? displayOrder,
    Value<int>? createdAt,
  }) {
    return PlotsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      cropTypeId: cropTypeId ?? this.cropTypeId,
      plotColorId: plotColorId ?? this.plotColorId,
      dueDay: dueDay ?? this.dueDay,
      isUnplanned: isUnplanned ?? this.isUnplanned,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PlotsTable.$converterkind.toSql(kind.value),
      );
    }
    if (budgetAmount.present) {
      map['budget_amount'] = Variable<int>(budgetAmount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (cropTypeId.present) {
      map['crop_type_id'] = Variable<String>(cropTypeId.value);
    }
    if (plotColorId.present) {
      map['plot_color_id'] = Variable<String>(plotColorId.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (isUnplanned.present) {
      map['is_unplanned'] = Variable<bool>(isUnplanned.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('budgetAmount: $budgetAmount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('cropTypeId: $cropTypeId, ')
          ..write('plotColorId: $plotColorId, ')
          ..write('dueDay: $dueDay, ')
          ..write('isUnplanned: $isUnplanned, ')
          ..write('isActive: $isActive, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BonusAllocationsTable extends BonusAllocations
    with TableInfo<$BonusAllocationsTable, BonusAllocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BonusAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _targetPlotIdMeta = const VerificationMeta(
    'targetPlotId',
  );
  @override
  late final GeneratedColumn<int> targetPlotId = GeneratedColumn<int>(
    'target_plot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plots (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allocatedAtMeta = const VerificationMeta(
    'allocatedAt',
  );
  @override
  late final GeneratedColumn<int> allocatedAt = GeneratedColumn<int>(
    'allocated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    targetPlotId,
    amount,
    allocatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bonus_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<BonusAllocationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('target_plot_id')) {
      context.handle(
        _targetPlotIdMeta,
        targetPlotId.isAcceptableOrUnknown(
          data['target_plot_id']!,
          _targetPlotIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPlotIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('allocated_at')) {
      context.handle(
        _allocatedAtMeta,
        allocatedAt.isAcceptableOrUnknown(
          data['allocated_at']!,
          _allocatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allocatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BonusAllocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BonusAllocationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      targetPlotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_plot_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      allocatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allocated_at'],
      )!,
    );
  }

  @override
  $BonusAllocationsTable createAlias(String alias) {
    return $BonusAllocationsTable(attachedDatabase, alias);
  }
}

class BonusAllocationRow extends DataClass
    implements Insertable<BonusAllocationRow> {
  final int id;
  final int cycleId;
  final int targetPlotId;
  final int amount;
  final int allocatedAt;
  const BonusAllocationRow({
    required this.id,
    required this.cycleId,
    required this.targetPlotId,
    required this.amount,
    required this.allocatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['target_plot_id'] = Variable<int>(targetPlotId);
    map['amount'] = Variable<int>(amount);
    map['allocated_at'] = Variable<int>(allocatedAt);
    return map;
  }

  BonusAllocationsCompanion toCompanion(bool nullToAbsent) {
    return BonusAllocationsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      targetPlotId: Value(targetPlotId),
      amount: Value(amount),
      allocatedAt: Value(allocatedAt),
    );
  }

  factory BonusAllocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BonusAllocationRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      targetPlotId: serializer.fromJson<int>(json['targetPlotId']),
      amount: serializer.fromJson<int>(json['amount']),
      allocatedAt: serializer.fromJson<int>(json['allocatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'targetPlotId': serializer.toJson<int>(targetPlotId),
      'amount': serializer.toJson<int>(amount),
      'allocatedAt': serializer.toJson<int>(allocatedAt),
    };
  }

  BonusAllocationRow copyWith({
    int? id,
    int? cycleId,
    int? targetPlotId,
    int? amount,
    int? allocatedAt,
  }) => BonusAllocationRow(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    targetPlotId: targetPlotId ?? this.targetPlotId,
    amount: amount ?? this.amount,
    allocatedAt: allocatedAt ?? this.allocatedAt,
  );
  BonusAllocationRow copyWithCompanion(BonusAllocationsCompanion data) {
    return BonusAllocationRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      targetPlotId: data.targetPlotId.present
          ? data.targetPlotId.value
          : this.targetPlotId,
      amount: data.amount.present ? data.amount.value : this.amount,
      allocatedAt: data.allocatedAt.present
          ? data.allocatedAt.value
          : this.allocatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BonusAllocationRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('targetPlotId: $targetPlotId, ')
          ..write('amount: $amount, ')
          ..write('allocatedAt: $allocatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, targetPlotId, amount, allocatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BonusAllocationRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.targetPlotId == this.targetPlotId &&
          other.amount == this.amount &&
          other.allocatedAt == this.allocatedAt);
}

class BonusAllocationsCompanion extends UpdateCompanion<BonusAllocationRow> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<int> targetPlotId;
  final Value<int> amount;
  final Value<int> allocatedAt;
  const BonusAllocationsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.targetPlotId = const Value.absent(),
    this.amount = const Value.absent(),
    this.allocatedAt = const Value.absent(),
  });
  BonusAllocationsCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required int targetPlotId,
    required int amount,
    required int allocatedAt,
  }) : cycleId = Value(cycleId),
       targetPlotId = Value(targetPlotId),
       amount = Value(amount),
       allocatedAt = Value(allocatedAt);
  static Insertable<BonusAllocationRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<int>? targetPlotId,
    Expression<int>? amount,
    Expression<int>? allocatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (targetPlotId != null) 'target_plot_id': targetPlotId,
      if (amount != null) 'amount': amount,
      if (allocatedAt != null) 'allocated_at': allocatedAt,
    });
  }

  BonusAllocationsCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<int>? targetPlotId,
    Value<int>? amount,
    Value<int>? allocatedAt,
  }) {
    return BonusAllocationsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      targetPlotId: targetPlotId ?? this.targetPlotId,
      amount: amount ?? this.amount,
      allocatedAt: allocatedAt ?? this.allocatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (targetPlotId.present) {
      map['target_plot_id'] = Variable<int>(targetPlotId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (allocatedAt.present) {
      map['allocated_at'] = Variable<int>(allocatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BonusAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('targetPlotId: $targetPlotId, ')
          ..write('amount: $amount, ')
          ..write('allocatedAt: $allocatedAt')
          ..write(')'))
        .toString();
  }
}

class $SavingsBarnTable extends SavingsBarn
    with TableInfo<$SavingsBarnTable, SavingsBarnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsBarnTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalSavedMeta = const VerificationMeta(
    'totalSaved',
  );
  @override
  late final GeneratedColumn<int> totalSaved = GeneratedColumn<int>(
    'total_saved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _barnSkinIdMeta = const VerificationMeta(
    'barnSkinId',
  );
  @override
  late final GeneratedColumn<String> barnSkinId = GeneratedColumn<String>(
    'barn_skin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalSaved,
    barnSkinId,
    lastUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_barn';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsBarnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_saved')) {
      context.handle(
        _totalSavedMeta,
        totalSaved.isAcceptableOrUnknown(data['total_saved']!, _totalSavedMeta),
      );
    }
    if (data.containsKey('barn_skin_id')) {
      context.handle(
        _barnSkinIdMeta,
        barnSkinId.isAcceptableOrUnknown(
          data['barn_skin_id']!,
          _barnSkinIdMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsBarnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsBarnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      totalSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_saved'],
      )!,
      barnSkinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barn_skin_id'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $SavingsBarnTable createAlias(String alias) {
    return $SavingsBarnTable(attachedDatabase, alias);
  }
}

class SavingsBarnRow extends DataClass implements Insertable<SavingsBarnRow> {
  final int id;
  final int totalSaved;
  final String barnSkinId;
  final int lastUpdatedAt;
  const SavingsBarnRow({
    required this.id,
    required this.totalSaved,
    required this.barnSkinId,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_saved'] = Variable<int>(totalSaved);
    map['barn_skin_id'] = Variable<String>(barnSkinId);
    map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    return map;
  }

  SavingsBarnCompanion toCompanion(bool nullToAbsent) {
    return SavingsBarnCompanion(
      id: Value(id),
      totalSaved: Value(totalSaved),
      barnSkinId: Value(barnSkinId),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory SavingsBarnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsBarnRow(
      id: serializer.fromJson<int>(json['id']),
      totalSaved: serializer.fromJson<int>(json['totalSaved']),
      barnSkinId: serializer.fromJson<String>(json['barnSkinId']),
      lastUpdatedAt: serializer.fromJson<int>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalSaved': serializer.toJson<int>(totalSaved),
      'barnSkinId': serializer.toJson<String>(barnSkinId),
      'lastUpdatedAt': serializer.toJson<int>(lastUpdatedAt),
    };
  }

  SavingsBarnRow copyWith({
    int? id,
    int? totalSaved,
    String? barnSkinId,
    int? lastUpdatedAt,
  }) => SavingsBarnRow(
    id: id ?? this.id,
    totalSaved: totalSaved ?? this.totalSaved,
    barnSkinId: barnSkinId ?? this.barnSkinId,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  SavingsBarnRow copyWithCompanion(SavingsBarnCompanion data) {
    return SavingsBarnRow(
      id: data.id.present ? data.id.value : this.id,
      totalSaved: data.totalSaved.present
          ? data.totalSaved.value
          : this.totalSaved,
      barnSkinId: data.barnSkinId.present
          ? data.barnSkinId.value
          : this.barnSkinId,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsBarnRow(')
          ..write('id: $id, ')
          ..write('totalSaved: $totalSaved, ')
          ..write('barnSkinId: $barnSkinId, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, totalSaved, barnSkinId, lastUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsBarnRow &&
          other.id == this.id &&
          other.totalSaved == this.totalSaved &&
          other.barnSkinId == this.barnSkinId &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class SavingsBarnCompanion extends UpdateCompanion<SavingsBarnRow> {
  final Value<int> id;
  final Value<int> totalSaved;
  final Value<String> barnSkinId;
  final Value<int> lastUpdatedAt;
  const SavingsBarnCompanion({
    this.id = const Value.absent(),
    this.totalSaved = const Value.absent(),
    this.barnSkinId = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
  });
  SavingsBarnCompanion.insert({
    this.id = const Value.absent(),
    this.totalSaved = const Value.absent(),
    this.barnSkinId = const Value.absent(),
    required int lastUpdatedAt,
  }) : lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<SavingsBarnRow> custom({
    Expression<int>? id,
    Expression<int>? totalSaved,
    Expression<String>? barnSkinId,
    Expression<int>? lastUpdatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalSaved != null) 'total_saved': totalSaved,
      if (barnSkinId != null) 'barn_skin_id': barnSkinId,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
    });
  }

  SavingsBarnCompanion copyWith({
    Value<int>? id,
    Value<int>? totalSaved,
    Value<String>? barnSkinId,
    Value<int>? lastUpdatedAt,
  }) {
    return SavingsBarnCompanion(
      id: id ?? this.id,
      totalSaved: totalSaved ?? this.totalSaved,
      barnSkinId: barnSkinId ?? this.barnSkinId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalSaved.present) {
      map['total_saved'] = Variable<int>(totalSaved.value);
    }
    if (barnSkinId.present) {
      map['barn_skin_id'] = Variable<String>(barnSkinId.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsBarnCompanion(')
          ..write('id: $id, ')
          ..write('totalSaved: $totalSaved, ')
          ..write('barnSkinId: $barnSkinId, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plots (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _baseAmountMeta = const VerificationMeta(
    'baseAmount',
  );
  @override
  late final GeneratedColumn<int> baseAmount = GeneratedColumn<int>(
    'base_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plotAmountMeta = const VerificationMeta(
    'plotAmount',
  );
  @override
  late final GeneratedColumn<int> plotAmount = GeneratedColumn<int>(
    'plot_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<int> spentAt = GeneratedColumn<int>(
    'spent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEmergencyMeta = const VerificationMeta(
    'isEmergency',
  );
  @override
  late final GeneratedColumn<bool> isEmergency = GeneratedColumn<bool>(
    'is_emergency',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_emergency" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plotId,
    cycleId,
    amount,
    currencyCode,
    baseAmount,
    plotAmount,
    exchangeRate,
    spentAt,
    note,
    isEmergency,
    createdAt,
    editedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('base_amount')) {
      context.handle(
        _baseAmountMeta,
        baseAmount.isAcceptableOrUnknown(data['base_amount']!, _baseAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_baseAmountMeta);
    }
    if (data.containsKey('plot_amount')) {
      context.handle(
        _plotAmountMeta,
        plotAmount.isAcceptableOrUnknown(data['plot_amount']!, _plotAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_plotAmountMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exchangeRateMeta);
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_spentAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_emergency')) {
      context.handle(
        _isEmergencyMeta,
        isEmergency.isAcceptableOrUnknown(
          data['is_emergency']!,
          _isEmergencyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plot_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount'],
      )!,
      plotAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plot_amount'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spent_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isEmergency: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_emergency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int plotId;
  final int cycleId;
  final int amount;
  final String currencyCode;
  final int baseAmount;
  final int plotAmount;
  final double exchangeRate;
  final int spentAt;
  final String? note;
  final bool isEmergency;
  final int createdAt;
  final int? editedAt;
  final int? deletedAt;
  const TransactionRow({
    required this.id,
    required this.plotId,
    required this.cycleId,
    required this.amount,
    required this.currencyCode,
    required this.baseAmount,
    required this.plotAmount,
    required this.exchangeRate,
    required this.spentAt,
    this.note,
    required this.isEmergency,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['cycle_id'] = Variable<int>(cycleId);
    map['amount'] = Variable<int>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['base_amount'] = Variable<int>(baseAmount);
    map['plot_amount'] = Variable<int>(plotAmount);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['spent_at'] = Variable<int>(spentAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_emergency'] = Variable<bool>(isEmergency);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      cycleId: Value(cycleId),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      baseAmount: Value(baseAmount),
      plotAmount: Value(plotAmount),
      exchangeRate: Value(exchangeRate),
      spentAt: Value(spentAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isEmergency: Value(isEmergency),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      amount: serializer.fromJson<int>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      plotAmount: serializer.fromJson<int>(json['plotAmount']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      spentAt: serializer.fromJson<int>(json['spentAt']),
      note: serializer.fromJson<String?>(json['note']),
      isEmergency: serializer.fromJson<bool>(json['isEmergency']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'cycleId': serializer.toJson<int>(cycleId),
      'amount': serializer.toJson<int>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'plotAmount': serializer.toJson<int>(plotAmount),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'spentAt': serializer.toJson<int>(spentAt),
      'note': serializer.toJson<String?>(note),
      'isEmergency': serializer.toJson<bool>(isEmergency),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? plotId,
    int? cycleId,
    int? amount,
    String? currencyCode,
    int? baseAmount,
    int? plotAmount,
    double? exchangeRate,
    int? spentAt,
    Value<String?> note = const Value.absent(),
    bool? isEmergency,
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    plotId: plotId ?? this.plotId,
    cycleId: cycleId ?? this.cycleId,
    amount: amount ?? this.amount,
    currencyCode: currencyCode ?? this.currencyCode,
    baseAmount: baseAmount ?? this.baseAmount,
    plotAmount: plotAmount ?? this.plotAmount,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    spentAt: spentAt ?? this.spentAt,
    note: note.present ? note.value : this.note,
    isEmergency: isEmergency ?? this.isEmergency,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      plotAmount: data.plotAmount.present
          ? data.plotAmount.value
          : this.plotAmount,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      note: data.note.present ? data.note.value : this.note,
      isEmergency: data.isEmergency.present
          ? data.isEmergency.value
          : this.isEmergency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('plotAmount: $plotAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('spentAt: $spentAt, ')
          ..write('note: $note, ')
          ..write('isEmergency: $isEmergency, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plotId,
    cycleId,
    amount,
    currencyCode,
    baseAmount,
    plotAmount,
    exchangeRate,
    spentAt,
    note,
    isEmergency,
    createdAt,
    editedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.cycleId == this.cycleId &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.baseAmount == this.baseAmount &&
          other.plotAmount == this.plotAmount &&
          other.exchangeRate == this.exchangeRate &&
          other.spentAt == this.spentAt &&
          other.note == this.note &&
          other.isEmergency == this.isEmergency &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<int> cycleId;
  final Value<int> amount;
  final Value<String> currencyCode;
  final Value<int> baseAmount;
  final Value<int> plotAmount;
  final Value<double> exchangeRate;
  final Value<int> spentAt;
  final Value<String?> note;
  final Value<bool> isEmergency;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int?> deletedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.plotAmount = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.note = const Value.absent(),
    this.isEmergency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required int cycleId,
    required int amount,
    required String currencyCode,
    required int baseAmount,
    required int plotAmount,
    required double exchangeRate,
    required int spentAt,
    this.note = const Value.absent(),
    this.isEmergency = const Value.absent(),
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : plotId = Value(plotId),
       cycleId = Value(cycleId),
       amount = Value(amount),
       currencyCode = Value(currencyCode),
       baseAmount = Value(baseAmount),
       plotAmount = Value(plotAmount),
       exchangeRate = Value(exchangeRate),
       spentAt = Value(spentAt),
       createdAt = Value(createdAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<int>? cycleId,
    Expression<int>? amount,
    Expression<String>? currencyCode,
    Expression<int>? baseAmount,
    Expression<int>? plotAmount,
    Expression<double>? exchangeRate,
    Expression<int>? spentAt,
    Expression<String>? note,
    Expression<bool>? isEmergency,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (plotAmount != null) 'plot_amount': plotAmount,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (spentAt != null) 'spent_at': spentAt,
      if (note != null) 'note': note,
      if (isEmergency != null) 'is_emergency': isEmergency,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? plotId,
    Value<int>? cycleId,
    Value<int>? amount,
    Value<String>? currencyCode,
    Value<int>? baseAmount,
    Value<int>? plotAmount,
    Value<double>? exchangeRate,
    Value<int>? spentAt,
    Value<String?>? note,
    Value<bool>? isEmergency,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int?>? deletedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      cycleId: cycleId ?? this.cycleId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      baseAmount: baseAmount ?? this.baseAmount,
      plotAmount: plotAmount ?? this.plotAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      spentAt: spentAt ?? this.spentAt,
      note: note ?? this.note,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<int>(baseAmount.value);
    }
    if (plotAmount.present) {
      map['plot_amount'] = Variable<int>(plotAmount.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<int>(spentAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isEmergency.present) {
      map['is_emergency'] = Variable<bool>(isEmergency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('plotAmount: $plotAmount, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('spentAt: $spentAt, ')
          ..write('note: $note, ')
          ..write('isEmergency: $isEmergency, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $PlotCycleResultsTable extends PlotCycleResults
    with TableInfo<$PlotCycleResultsTable, PlotCycleResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotCycleResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plots (id)',
    ),
  );
  static const VerificationMeta _plotNameSnapshotMeta = const VerificationMeta(
    'plotNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> plotNameSnapshot = GeneratedColumn<String>(
    'plot_name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlotKind, String> kindSnapshot =
      GeneratedColumn<String>(
        'kind_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('discretionary'),
      ).withConverter<PlotKind>($PlotCycleResultsTable.$converterkindSnapshot);
  static const VerificationMeta _cropTypeIdSnapshotMeta =
      const VerificationMeta('cropTypeIdSnapshot');
  @override
  late final GeneratedColumn<String> cropTypeIdSnapshot =
      GeneratedColumn<String>(
        'crop_type_id_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _plotColorIdSnapshotMeta =
      const VerificationMeta('plotColorIdSnapshot');
  @override
  late final GeneratedColumn<String> plotColorIdSnapshot =
      GeneratedColumn<String>(
        'plot_color_id_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isUnplannedMeta = const VerificationMeta(
    'isUnplanned',
  );
  @override
  late final GeneratedColumn<bool> isUnplanned = GeneratedColumn<bool>(
    'is_unplanned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unplanned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _budgetAmountSnapshotMeta =
      const VerificationMeta('budgetAmountSnapshot');
  @override
  late final GeneratedColumn<int> budgetAmountSnapshot = GeneratedColumn<int>(
    'budget_amount_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeSnapshotMeta =
      const VerificationMeta('currencyCodeSnapshot');
  @override
  late final GeneratedColumn<String> currencyCodeSnapshot =
      GeneratedColumn<String>(
        'currency_code_snapshot',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 3,
          maxTextLength: 3,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES currencies (code)',
        ),
      );
  static const VerificationMeta _totalSpentMeta = const VerificationMeta(
    'totalSpent',
  );
  @override
  late final GeneratedColumn<int> totalSpent = GeneratedColumn<int>(
    'total_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomeShareAtCloseMeta =
      const VerificationMeta('incomeShareAtClose');
  @override
  late final GeneratedColumn<double> incomeShareAtClose =
      GeneratedColumn<double>(
        'income_share_at_close',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<PlotFinalState, String>
  finalState = GeneratedColumn<String>(
    'final_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PlotFinalState>($PlotCycleResultsTable.$converterfinalState);
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    plotId,
    plotNameSnapshot,
    kindSnapshot,
    cropTypeIdSnapshot,
    plotColorIdSnapshot,
    isUnplanned,
    budgetAmountSnapshot,
    currencyCodeSnapshot,
    totalSpent,
    incomeShareAtClose,
    finalState,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plot_cycle_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlotCycleResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('plot_name_snapshot')) {
      context.handle(
        _plotNameSnapshotMeta,
        plotNameSnapshot.isAcceptableOrUnknown(
          data['plot_name_snapshot']!,
          _plotNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plotNameSnapshotMeta);
    }
    if (data.containsKey('crop_type_id_snapshot')) {
      context.handle(
        _cropTypeIdSnapshotMeta,
        cropTypeIdSnapshot.isAcceptableOrUnknown(
          data['crop_type_id_snapshot']!,
          _cropTypeIdSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cropTypeIdSnapshotMeta);
    }
    if (data.containsKey('plot_color_id_snapshot')) {
      context.handle(
        _plotColorIdSnapshotMeta,
        plotColorIdSnapshot.isAcceptableOrUnknown(
          data['plot_color_id_snapshot']!,
          _plotColorIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('is_unplanned')) {
      context.handle(
        _isUnplannedMeta,
        isUnplanned.isAcceptableOrUnknown(
          data['is_unplanned']!,
          _isUnplannedMeta,
        ),
      );
    }
    if (data.containsKey('budget_amount_snapshot')) {
      context.handle(
        _budgetAmountSnapshotMeta,
        budgetAmountSnapshot.isAcceptableOrUnknown(
          data['budget_amount_snapshot']!,
          _budgetAmountSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('currency_code_snapshot')) {
      context.handle(
        _currencyCodeSnapshotMeta,
        currencyCodeSnapshot.isAcceptableOrUnknown(
          data['currency_code_snapshot']!,
          _currencyCodeSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeSnapshotMeta);
    }
    if (data.containsKey('total_spent')) {
      context.handle(
        _totalSpentMeta,
        totalSpent.isAcceptableOrUnknown(data['total_spent']!, _totalSpentMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSpentMeta);
    }
    if (data.containsKey('income_share_at_close')) {
      context.handle(
        _incomeShareAtCloseMeta,
        incomeShareAtClose.isAcceptableOrUnknown(
          data['income_share_at_close']!,
          _incomeShareAtCloseMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cycleId, plotId},
  ];
  @override
  PlotCycleResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlotCycleResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plot_id'],
      )!,
      plotNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_name_snapshot'],
      )!,
      kindSnapshot: $PlotCycleResultsTable.$converterkindSnapshot.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind_snapshot'],
        )!,
      ),
      cropTypeIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_type_id_snapshot'],
      )!,
      plotColorIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot_color_id_snapshot'],
      ),
      isUnplanned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unplanned'],
      )!,
      budgetAmountSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_amount_snapshot'],
      ),
      currencyCodeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code_snapshot'],
      )!,
      totalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_spent'],
      )!,
      incomeShareAtClose: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}income_share_at_close'],
      ),
      finalState: $PlotCycleResultsTable.$converterfinalState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}final_state'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $PlotCycleResultsTable createAlias(String alias) {
    return $PlotCycleResultsTable(attachedDatabase, alias);
  }

  static TypeConverter<PlotKind, String> $converterkindSnapshot =
      const SnakeEnumConverter<PlotKind>(PlotKind.values);
  static TypeConverter<PlotFinalState, String> $converterfinalState =
      const SnakeEnumConverter<PlotFinalState>(PlotFinalState.values);
}

class PlotCycleResultRow extends DataClass
    implements Insertable<PlotCycleResultRow> {
  final int id;
  final int cycleId;
  final int plotId;
  final String plotNameSnapshot;
  final PlotKind kindSnapshot;
  final String cropTypeIdSnapshot;
  final String? plotColorIdSnapshot;
  final bool isUnplanned;
  final int? budgetAmountSnapshot;
  final String currencyCodeSnapshot;
  final int totalSpent;
  final double? incomeShareAtClose;
  final PlotFinalState finalState;
  final int completedAt;
  const PlotCycleResultRow({
    required this.id,
    required this.cycleId,
    required this.plotId,
    required this.plotNameSnapshot,
    required this.kindSnapshot,
    required this.cropTypeIdSnapshot,
    this.plotColorIdSnapshot,
    required this.isUnplanned,
    this.budgetAmountSnapshot,
    required this.currencyCodeSnapshot,
    required this.totalSpent,
    this.incomeShareAtClose,
    required this.finalState,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['plot_id'] = Variable<int>(plotId);
    map['plot_name_snapshot'] = Variable<String>(plotNameSnapshot);
    {
      map['kind_snapshot'] = Variable<String>(
        $PlotCycleResultsTable.$converterkindSnapshot.toSql(kindSnapshot),
      );
    }
    map['crop_type_id_snapshot'] = Variable<String>(cropTypeIdSnapshot);
    if (!nullToAbsent || plotColorIdSnapshot != null) {
      map['plot_color_id_snapshot'] = Variable<String>(plotColorIdSnapshot);
    }
    map['is_unplanned'] = Variable<bool>(isUnplanned);
    if (!nullToAbsent || budgetAmountSnapshot != null) {
      map['budget_amount_snapshot'] = Variable<int>(budgetAmountSnapshot);
    }
    map['currency_code_snapshot'] = Variable<String>(currencyCodeSnapshot);
    map['total_spent'] = Variable<int>(totalSpent);
    if (!nullToAbsent || incomeShareAtClose != null) {
      map['income_share_at_close'] = Variable<double>(incomeShareAtClose);
    }
    {
      map['final_state'] = Variable<String>(
        $PlotCycleResultsTable.$converterfinalState.toSql(finalState),
      );
    }
    map['completed_at'] = Variable<int>(completedAt);
    return map;
  }

  PlotCycleResultsCompanion toCompanion(bool nullToAbsent) {
    return PlotCycleResultsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      plotId: Value(plotId),
      plotNameSnapshot: Value(plotNameSnapshot),
      kindSnapshot: Value(kindSnapshot),
      cropTypeIdSnapshot: Value(cropTypeIdSnapshot),
      plotColorIdSnapshot: plotColorIdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(plotColorIdSnapshot),
      isUnplanned: Value(isUnplanned),
      budgetAmountSnapshot: budgetAmountSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetAmountSnapshot),
      currencyCodeSnapshot: Value(currencyCodeSnapshot),
      totalSpent: Value(totalSpent),
      incomeShareAtClose: incomeShareAtClose == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeShareAtClose),
      finalState: Value(finalState),
      completedAt: Value(completedAt),
    );
  }

  factory PlotCycleResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlotCycleResultRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      plotId: serializer.fromJson<int>(json['plotId']),
      plotNameSnapshot: serializer.fromJson<String>(json['plotNameSnapshot']),
      kindSnapshot: serializer.fromJson<PlotKind>(json['kindSnapshot']),
      cropTypeIdSnapshot: serializer.fromJson<String>(
        json['cropTypeIdSnapshot'],
      ),
      plotColorIdSnapshot: serializer.fromJson<String?>(
        json['plotColorIdSnapshot'],
      ),
      isUnplanned: serializer.fromJson<bool>(json['isUnplanned']),
      budgetAmountSnapshot: serializer.fromJson<int?>(
        json['budgetAmountSnapshot'],
      ),
      currencyCodeSnapshot: serializer.fromJson<String>(
        json['currencyCodeSnapshot'],
      ),
      totalSpent: serializer.fromJson<int>(json['totalSpent']),
      incomeShareAtClose: serializer.fromJson<double?>(
        json['incomeShareAtClose'],
      ),
      finalState: serializer.fromJson<PlotFinalState>(json['finalState']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'plotId': serializer.toJson<int>(plotId),
      'plotNameSnapshot': serializer.toJson<String>(plotNameSnapshot),
      'kindSnapshot': serializer.toJson<PlotKind>(kindSnapshot),
      'cropTypeIdSnapshot': serializer.toJson<String>(cropTypeIdSnapshot),
      'plotColorIdSnapshot': serializer.toJson<String?>(plotColorIdSnapshot),
      'isUnplanned': serializer.toJson<bool>(isUnplanned),
      'budgetAmountSnapshot': serializer.toJson<int?>(budgetAmountSnapshot),
      'currencyCodeSnapshot': serializer.toJson<String>(currencyCodeSnapshot),
      'totalSpent': serializer.toJson<int>(totalSpent),
      'incomeShareAtClose': serializer.toJson<double?>(incomeShareAtClose),
      'finalState': serializer.toJson<PlotFinalState>(finalState),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  PlotCycleResultRow copyWith({
    int? id,
    int? cycleId,
    int? plotId,
    String? plotNameSnapshot,
    PlotKind? kindSnapshot,
    String? cropTypeIdSnapshot,
    Value<String?> plotColorIdSnapshot = const Value.absent(),
    bool? isUnplanned,
    Value<int?> budgetAmountSnapshot = const Value.absent(),
    String? currencyCodeSnapshot,
    int? totalSpent,
    Value<double?> incomeShareAtClose = const Value.absent(),
    PlotFinalState? finalState,
    int? completedAt,
  }) => PlotCycleResultRow(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    plotId: plotId ?? this.plotId,
    plotNameSnapshot: plotNameSnapshot ?? this.plotNameSnapshot,
    kindSnapshot: kindSnapshot ?? this.kindSnapshot,
    cropTypeIdSnapshot: cropTypeIdSnapshot ?? this.cropTypeIdSnapshot,
    plotColorIdSnapshot: plotColorIdSnapshot.present
        ? plotColorIdSnapshot.value
        : this.plotColorIdSnapshot,
    isUnplanned: isUnplanned ?? this.isUnplanned,
    budgetAmountSnapshot: budgetAmountSnapshot.present
        ? budgetAmountSnapshot.value
        : this.budgetAmountSnapshot,
    currencyCodeSnapshot: currencyCodeSnapshot ?? this.currencyCodeSnapshot,
    totalSpent: totalSpent ?? this.totalSpent,
    incomeShareAtClose: incomeShareAtClose.present
        ? incomeShareAtClose.value
        : this.incomeShareAtClose,
    finalState: finalState ?? this.finalState,
    completedAt: completedAt ?? this.completedAt,
  );
  PlotCycleResultRow copyWithCompanion(PlotCycleResultsCompanion data) {
    return PlotCycleResultRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      plotNameSnapshot: data.plotNameSnapshot.present
          ? data.plotNameSnapshot.value
          : this.plotNameSnapshot,
      kindSnapshot: data.kindSnapshot.present
          ? data.kindSnapshot.value
          : this.kindSnapshot,
      cropTypeIdSnapshot: data.cropTypeIdSnapshot.present
          ? data.cropTypeIdSnapshot.value
          : this.cropTypeIdSnapshot,
      plotColorIdSnapshot: data.plotColorIdSnapshot.present
          ? data.plotColorIdSnapshot.value
          : this.plotColorIdSnapshot,
      isUnplanned: data.isUnplanned.present
          ? data.isUnplanned.value
          : this.isUnplanned,
      budgetAmountSnapshot: data.budgetAmountSnapshot.present
          ? data.budgetAmountSnapshot.value
          : this.budgetAmountSnapshot,
      currencyCodeSnapshot: data.currencyCodeSnapshot.present
          ? data.currencyCodeSnapshot.value
          : this.currencyCodeSnapshot,
      totalSpent: data.totalSpent.present
          ? data.totalSpent.value
          : this.totalSpent,
      incomeShareAtClose: data.incomeShareAtClose.present
          ? data.incomeShareAtClose.value
          : this.incomeShareAtClose,
      finalState: data.finalState.present
          ? data.finalState.value
          : this.finalState,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlotCycleResultRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('plotId: $plotId, ')
          ..write('plotNameSnapshot: $plotNameSnapshot, ')
          ..write('kindSnapshot: $kindSnapshot, ')
          ..write('cropTypeIdSnapshot: $cropTypeIdSnapshot, ')
          ..write('plotColorIdSnapshot: $plotColorIdSnapshot, ')
          ..write('isUnplanned: $isUnplanned, ')
          ..write('budgetAmountSnapshot: $budgetAmountSnapshot, ')
          ..write('currencyCodeSnapshot: $currencyCodeSnapshot, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('incomeShareAtClose: $incomeShareAtClose, ')
          ..write('finalState: $finalState, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    plotId,
    plotNameSnapshot,
    kindSnapshot,
    cropTypeIdSnapshot,
    plotColorIdSnapshot,
    isUnplanned,
    budgetAmountSnapshot,
    currencyCodeSnapshot,
    totalSpent,
    incomeShareAtClose,
    finalState,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlotCycleResultRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.plotId == this.plotId &&
          other.plotNameSnapshot == this.plotNameSnapshot &&
          other.kindSnapshot == this.kindSnapshot &&
          other.cropTypeIdSnapshot == this.cropTypeIdSnapshot &&
          other.plotColorIdSnapshot == this.plotColorIdSnapshot &&
          other.isUnplanned == this.isUnplanned &&
          other.budgetAmountSnapshot == this.budgetAmountSnapshot &&
          other.currencyCodeSnapshot == this.currencyCodeSnapshot &&
          other.totalSpent == this.totalSpent &&
          other.incomeShareAtClose == this.incomeShareAtClose &&
          other.finalState == this.finalState &&
          other.completedAt == this.completedAt);
}

class PlotCycleResultsCompanion extends UpdateCompanion<PlotCycleResultRow> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<int> plotId;
  final Value<String> plotNameSnapshot;
  final Value<PlotKind> kindSnapshot;
  final Value<String> cropTypeIdSnapshot;
  final Value<String?> plotColorIdSnapshot;
  final Value<bool> isUnplanned;
  final Value<int?> budgetAmountSnapshot;
  final Value<String> currencyCodeSnapshot;
  final Value<int> totalSpent;
  final Value<double?> incomeShareAtClose;
  final Value<PlotFinalState> finalState;
  final Value<int> completedAt;
  const PlotCycleResultsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.plotId = const Value.absent(),
    this.plotNameSnapshot = const Value.absent(),
    this.kindSnapshot = const Value.absent(),
    this.cropTypeIdSnapshot = const Value.absent(),
    this.plotColorIdSnapshot = const Value.absent(),
    this.isUnplanned = const Value.absent(),
    this.budgetAmountSnapshot = const Value.absent(),
    this.currencyCodeSnapshot = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.incomeShareAtClose = const Value.absent(),
    this.finalState = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  PlotCycleResultsCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required int plotId,
    required String plotNameSnapshot,
    this.kindSnapshot = const Value.absent(),
    required String cropTypeIdSnapshot,
    this.plotColorIdSnapshot = const Value.absent(),
    this.isUnplanned = const Value.absent(),
    this.budgetAmountSnapshot = const Value.absent(),
    required String currencyCodeSnapshot,
    required int totalSpent,
    this.incomeShareAtClose = const Value.absent(),
    required PlotFinalState finalState,
    required int completedAt,
  }) : cycleId = Value(cycleId),
       plotId = Value(plotId),
       plotNameSnapshot = Value(plotNameSnapshot),
       cropTypeIdSnapshot = Value(cropTypeIdSnapshot),
       currencyCodeSnapshot = Value(currencyCodeSnapshot),
       totalSpent = Value(totalSpent),
       finalState = Value(finalState),
       completedAt = Value(completedAt);
  static Insertable<PlotCycleResultRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<int>? plotId,
    Expression<String>? plotNameSnapshot,
    Expression<String>? kindSnapshot,
    Expression<String>? cropTypeIdSnapshot,
    Expression<String>? plotColorIdSnapshot,
    Expression<bool>? isUnplanned,
    Expression<int>? budgetAmountSnapshot,
    Expression<String>? currencyCodeSnapshot,
    Expression<int>? totalSpent,
    Expression<double>? incomeShareAtClose,
    Expression<String>? finalState,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (plotId != null) 'plot_id': plotId,
      if (plotNameSnapshot != null) 'plot_name_snapshot': plotNameSnapshot,
      if (kindSnapshot != null) 'kind_snapshot': kindSnapshot,
      if (cropTypeIdSnapshot != null)
        'crop_type_id_snapshot': cropTypeIdSnapshot,
      if (plotColorIdSnapshot != null)
        'plot_color_id_snapshot': plotColorIdSnapshot,
      if (isUnplanned != null) 'is_unplanned': isUnplanned,
      if (budgetAmountSnapshot != null)
        'budget_amount_snapshot': budgetAmountSnapshot,
      if (currencyCodeSnapshot != null)
        'currency_code_snapshot': currencyCodeSnapshot,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (incomeShareAtClose != null)
        'income_share_at_close': incomeShareAtClose,
      if (finalState != null) 'final_state': finalState,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  PlotCycleResultsCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<int>? plotId,
    Value<String>? plotNameSnapshot,
    Value<PlotKind>? kindSnapshot,
    Value<String>? cropTypeIdSnapshot,
    Value<String?>? plotColorIdSnapshot,
    Value<bool>? isUnplanned,
    Value<int?>? budgetAmountSnapshot,
    Value<String>? currencyCodeSnapshot,
    Value<int>? totalSpent,
    Value<double?>? incomeShareAtClose,
    Value<PlotFinalState>? finalState,
    Value<int>? completedAt,
  }) {
    return PlotCycleResultsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      plotId: plotId ?? this.plotId,
      plotNameSnapshot: plotNameSnapshot ?? this.plotNameSnapshot,
      kindSnapshot: kindSnapshot ?? this.kindSnapshot,
      cropTypeIdSnapshot: cropTypeIdSnapshot ?? this.cropTypeIdSnapshot,
      plotColorIdSnapshot: plotColorIdSnapshot ?? this.plotColorIdSnapshot,
      isUnplanned: isUnplanned ?? this.isUnplanned,
      budgetAmountSnapshot: budgetAmountSnapshot ?? this.budgetAmountSnapshot,
      currencyCodeSnapshot: currencyCodeSnapshot ?? this.currencyCodeSnapshot,
      totalSpent: totalSpent ?? this.totalSpent,
      incomeShareAtClose: incomeShareAtClose ?? this.incomeShareAtClose,
      finalState: finalState ?? this.finalState,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (plotNameSnapshot.present) {
      map['plot_name_snapshot'] = Variable<String>(plotNameSnapshot.value);
    }
    if (kindSnapshot.present) {
      map['kind_snapshot'] = Variable<String>(
        $PlotCycleResultsTable.$converterkindSnapshot.toSql(kindSnapshot.value),
      );
    }
    if (cropTypeIdSnapshot.present) {
      map['crop_type_id_snapshot'] = Variable<String>(cropTypeIdSnapshot.value);
    }
    if (plotColorIdSnapshot.present) {
      map['plot_color_id_snapshot'] = Variable<String>(
        plotColorIdSnapshot.value,
      );
    }
    if (isUnplanned.present) {
      map['is_unplanned'] = Variable<bool>(isUnplanned.value);
    }
    if (budgetAmountSnapshot.present) {
      map['budget_amount_snapshot'] = Variable<int>(budgetAmountSnapshot.value);
    }
    if (currencyCodeSnapshot.present) {
      map['currency_code_snapshot'] = Variable<String>(
        currencyCodeSnapshot.value,
      );
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<int>(totalSpent.value);
    }
    if (incomeShareAtClose.present) {
      map['income_share_at_close'] = Variable<double>(incomeShareAtClose.value);
    }
    if (finalState.present) {
      map['final_state'] = Variable<String>(
        $PlotCycleResultsTable.$converterfinalState.toSql(finalState.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotCycleResultsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('plotId: $plotId, ')
          ..write('plotNameSnapshot: $plotNameSnapshot, ')
          ..write('kindSnapshot: $kindSnapshot, ')
          ..write('cropTypeIdSnapshot: $cropTypeIdSnapshot, ')
          ..write('plotColorIdSnapshot: $plotColorIdSnapshot, ')
          ..write('isUnplanned: $isUnplanned, ')
          ..write('budgetAmountSnapshot: $budgetAmountSnapshot, ')
          ..write('currencyCodeSnapshot: $currencyCodeSnapshot, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('incomeShareAtClose: $incomeShareAtClose, ')
          ..write('finalState: $finalState, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $PlotFertilizerApplicationsTable extends PlotFertilizerApplications
    with
        TableInfo<
          $PlotFertilizerApplicationsTable,
          PlotFertilizerApplicationRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotFertilizerApplicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
    'plot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plots (id)',
    ),
  );
  static const VerificationMeta _fertilizerItemIdMeta = const VerificationMeta(
    'fertilizerItemId',
  );
  @override
  late final GeneratedColumn<String> fertilizerItemId = GeneratedColumn<String>(
    'fertilizer_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<int> appliedAt = GeneratedColumn<int>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    plotId,
    fertilizerItemId,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plot_fertilizer_applications';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlotFertilizerApplicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('plot_id')) {
      context.handle(
        _plotIdMeta,
        plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('fertilizer_item_id')) {
      context.handle(
        _fertilizerItemIdMeta,
        fertilizerItemId.isAcceptableOrUnknown(
          data['fertilizer_item_id']!,
          _fertilizerItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fertilizerItemIdMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cycleId, plotId},
  ];
  @override
  PlotFertilizerApplicationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlotFertilizerApplicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      plotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plot_id'],
      )!,
      fertilizerItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fertilizer_item_id'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $PlotFertilizerApplicationsTable createAlias(String alias) {
    return $PlotFertilizerApplicationsTable(attachedDatabase, alias);
  }
}

class PlotFertilizerApplicationRow extends DataClass
    implements Insertable<PlotFertilizerApplicationRow> {
  final int id;
  final int cycleId;
  final int plotId;
  final String fertilizerItemId;
  final int appliedAt;
  const PlotFertilizerApplicationRow({
    required this.id,
    required this.cycleId,
    required this.plotId,
    required this.fertilizerItemId,
    required this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_id'] = Variable<int>(cycleId);
    map['plot_id'] = Variable<int>(plotId);
    map['fertilizer_item_id'] = Variable<String>(fertilizerItemId);
    map['applied_at'] = Variable<int>(appliedAt);
    return map;
  }

  PlotFertilizerApplicationsCompanion toCompanion(bool nullToAbsent) {
    return PlotFertilizerApplicationsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      plotId: Value(plotId),
      fertilizerItemId: Value(fertilizerItemId),
      appliedAt: Value(appliedAt),
    );
  }

  factory PlotFertilizerApplicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlotFertilizerApplicationRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      plotId: serializer.fromJson<int>(json['plotId']),
      fertilizerItemId: serializer.fromJson<String>(json['fertilizerItemId']),
      appliedAt: serializer.fromJson<int>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int>(cycleId),
      'plotId': serializer.toJson<int>(plotId),
      'fertilizerItemId': serializer.toJson<String>(fertilizerItemId),
      'appliedAt': serializer.toJson<int>(appliedAt),
    };
  }

  PlotFertilizerApplicationRow copyWith({
    int? id,
    int? cycleId,
    int? plotId,
    String? fertilizerItemId,
    int? appliedAt,
  }) => PlotFertilizerApplicationRow(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    plotId: plotId ?? this.plotId,
    fertilizerItemId: fertilizerItemId ?? this.fertilizerItemId,
    appliedAt: appliedAt ?? this.appliedAt,
  );
  PlotFertilizerApplicationRow copyWithCompanion(
    PlotFertilizerApplicationsCompanion data,
  ) {
    return PlotFertilizerApplicationRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      fertilizerItemId: data.fertilizerItemId.present
          ? data.fertilizerItemId.value
          : this.fertilizerItemId,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlotFertilizerApplicationRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('plotId: $plotId, ')
          ..write('fertilizerItemId: $fertilizerItemId, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleId, plotId, fertilizerItemId, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlotFertilizerApplicationRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.plotId == this.plotId &&
          other.fertilizerItemId == this.fertilizerItemId &&
          other.appliedAt == this.appliedAt);
}

class PlotFertilizerApplicationsCompanion
    extends UpdateCompanion<PlotFertilizerApplicationRow> {
  final Value<int> id;
  final Value<int> cycleId;
  final Value<int> plotId;
  final Value<String> fertilizerItemId;
  final Value<int> appliedAt;
  const PlotFertilizerApplicationsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.plotId = const Value.absent(),
    this.fertilizerItemId = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  PlotFertilizerApplicationsCompanion.insert({
    this.id = const Value.absent(),
    required int cycleId,
    required int plotId,
    required String fertilizerItemId,
    required int appliedAt,
  }) : cycleId = Value(cycleId),
       plotId = Value(plotId),
       fertilizerItemId = Value(fertilizerItemId),
       appliedAt = Value(appliedAt);
  static Insertable<PlotFertilizerApplicationRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<int>? plotId,
    Expression<String>? fertilizerItemId,
    Expression<int>? appliedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (plotId != null) 'plot_id': plotId,
      if (fertilizerItemId != null) 'fertilizer_item_id': fertilizerItemId,
      if (appliedAt != null) 'applied_at': appliedAt,
    });
  }

  PlotFertilizerApplicationsCompanion copyWith({
    Value<int>? id,
    Value<int>? cycleId,
    Value<int>? plotId,
    Value<String>? fertilizerItemId,
    Value<int>? appliedAt,
  }) {
    return PlotFertilizerApplicationsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      plotId: plotId ?? this.plotId,
      fertilizerItemId: fertilizerItemId ?? this.fertilizerItemId,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (fertilizerItemId.present) {
      map['fertilizer_item_id'] = Variable<String>(fertilizerItemId.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(appliedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotFertilizerApplicationsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('plotId: $plotId, ')
          ..write('fertilizerItemId: $fertilizerItemId, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }
}

class $CoinLedgerTable extends CoinLedger
    with TableInfo<$CoinLedgerTable, CoinLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoinLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CoinReason, String> reason =
      GeneratedColumn<String>(
        'reason',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CoinReason>($CoinLedgerTable.$converterreason);
  static const VerificationMeta _relatedIdMeta = const VerificationMeta(
    'relatedId',
  );
  @override
  late final GeneratedColumn<int> relatedId = GeneratedColumn<int>(
    'related_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedTypeMeta = const VerificationMeta(
    'relatedType',
  );
  @override
  late final GeneratedColumn<String> relatedType = GeneratedColumn<String>(
    'related_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    amount,
    reason,
    relatedId,
    relatedType,
    description,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coin_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoinLedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('related_id')) {
      context.handle(
        _relatedIdMeta,
        relatedId.isAcceptableOrUnknown(data['related_id']!, _relatedIdMeta),
      );
    }
    if (data.containsKey('related_type')) {
      context.handle(
        _relatedTypeMeta,
        relatedType.isAcceptableOrUnknown(
          data['related_type']!,
          _relatedTypeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoinLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoinLedgerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      reason: $CoinLedgerTable.$converterreason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reason'],
        )!,
      ),
      relatedId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_id'],
      ),
      relatedType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $CoinLedgerTable createAlias(String alias) {
    return $CoinLedgerTable(attachedDatabase, alias);
  }

  static TypeConverter<CoinReason, String> $converterreason =
      const SnakeEnumConverter<CoinReason>(CoinReason.values);
}

class CoinLedgerRow extends DataClass implements Insertable<CoinLedgerRow> {
  final int id;
  final int? cycleId;
  final int amount;
  final CoinReason reason;
  final int? relatedId;
  final String? relatedType;
  final String? description;
  final int occurredAt;
  const CoinLedgerRow({
    required this.id,
    this.cycleId,
    required this.amount,
    required this.reason,
    this.relatedId,
    this.relatedType,
    this.description,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<int>(cycleId);
    }
    map['amount'] = Variable<int>(amount);
    {
      map['reason'] = Variable<String>(
        $CoinLedgerTable.$converterreason.toSql(reason),
      );
    }
    if (!nullToAbsent || relatedId != null) {
      map['related_id'] = Variable<int>(relatedId);
    }
    if (!nullToAbsent || relatedType != null) {
      map['related_type'] = Variable<String>(relatedType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    return map;
  }

  CoinLedgerCompanion toCompanion(bool nullToAbsent) {
    return CoinLedgerCompanion(
      id: Value(id),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
      amount: Value(amount),
      reason: Value(reason),
      relatedId: relatedId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedId),
      relatedType: relatedType == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: Value(occurredAt),
    );
  }

  factory CoinLedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoinLedgerRow(
      id: serializer.fromJson<int>(json['id']),
      cycleId: serializer.fromJson<int?>(json['cycleId']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<CoinReason>(json['reason']),
      relatedId: serializer.fromJson<int?>(json['relatedId']),
      relatedType: serializer.fromJson<String?>(json['relatedType']),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleId': serializer.toJson<int?>(cycleId),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<CoinReason>(reason),
      'relatedId': serializer.toJson<int?>(relatedId),
      'relatedType': serializer.toJson<String?>(relatedType),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<int>(occurredAt),
    };
  }

  CoinLedgerRow copyWith({
    int? id,
    Value<int?> cycleId = const Value.absent(),
    int? amount,
    CoinReason? reason,
    Value<int?> relatedId = const Value.absent(),
    Value<String?> relatedType = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? occurredAt,
  }) => CoinLedgerRow(
    id: id ?? this.id,
    cycleId: cycleId.present ? cycleId.value : this.cycleId,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    relatedId: relatedId.present ? relatedId.value : this.relatedId,
    relatedType: relatedType.present ? relatedType.value : this.relatedType,
    description: description.present ? description.value : this.description,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  CoinLedgerRow copyWithCompanion(CoinLedgerCompanion data) {
    return CoinLedgerRow(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      relatedId: data.relatedId.present ? data.relatedId.value : this.relatedId,
      relatedType: data.relatedType.present
          ? data.relatedType.value
          : this.relatedType,
      description: data.description.present
          ? data.description.value
          : this.description,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoinLedgerRow(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('relatedId: $relatedId, ')
          ..write('relatedType: $relatedType, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    amount,
    reason,
    relatedId,
    relatedType,
    description,
    occurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoinLedgerRow &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.relatedId == this.relatedId &&
          other.relatedType == this.relatedType &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt);
}

class CoinLedgerCompanion extends UpdateCompanion<CoinLedgerRow> {
  final Value<int> id;
  final Value<int?> cycleId;
  final Value<int> amount;
  final Value<CoinReason> reason;
  final Value<int?> relatedId;
  final Value<String?> relatedType;
  final Value<String?> description;
  final Value<int> occurredAt;
  const CoinLedgerCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.relatedId = const Value.absent(),
    this.relatedType = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
  });
  CoinLedgerCompanion.insert({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    required int amount,
    required CoinReason reason,
    this.relatedId = const Value.absent(),
    this.relatedType = const Value.absent(),
    this.description = const Value.absent(),
    required int occurredAt,
  }) : amount = Value(amount),
       reason = Value(reason),
       occurredAt = Value(occurredAt);
  static Insertable<CoinLedgerRow> custom({
    Expression<int>? id,
    Expression<int>? cycleId,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<int>? relatedId,
    Expression<String>? relatedType,
    Expression<String>? description,
    Expression<int>? occurredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (relatedId != null) 'related_id': relatedId,
      if (relatedType != null) 'related_type': relatedType,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
    });
  }

  CoinLedgerCompanion copyWith({
    Value<int>? id,
    Value<int?>? cycleId,
    Value<int>? amount,
    Value<CoinReason>? reason,
    Value<int?>? relatedId,
    Value<String?>? relatedType,
    Value<String?>? description,
    Value<int>? occurredAt,
  }) {
    return CoinLedgerCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(
        $CoinLedgerTable.$converterreason.toSql(reason.value),
      );
    }
    if (relatedId.present) {
      map['related_id'] = Variable<int>(relatedId.value);
    }
    if (relatedType.present) {
      map['related_type'] = Variable<String>(relatedType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoinLedgerCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('relatedId: $relatedId, ')
          ..write('relatedType: $relatedType, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }
}

class $BadgesEarnedTable extends BadgesEarned
    with TableInfo<$BadgesEarnedTable, BadgeEarnedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BadgesEarnedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _badgeIdMeta = const VerificationMeta(
    'badgeId',
  );
  @override
  late final GeneratedColumn<String> badgeId = GeneratedColumn<String>(
    'badge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<int> earnedAt = GeneratedColumn<int>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, badgeId, earnedAt, cycleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'badges_earned';
  @override
  VerificationContext validateIntegrity(
    Insertable<BadgeEarnedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('badge_id')) {
      context.handle(
        _badgeIdMeta,
        badgeId.isAcceptableOrUnknown(data['badge_id']!, _badgeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_badgeIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BadgeEarnedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BadgeEarnedRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      badgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badge_id'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}earned_at'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      ),
    );
  }

  @override
  $BadgesEarnedTable createAlias(String alias) {
    return $BadgesEarnedTable(attachedDatabase, alias);
  }
}

class BadgeEarnedRow extends DataClass implements Insertable<BadgeEarnedRow> {
  final int id;
  final String badgeId;
  final int earnedAt;
  final int? cycleId;
  const BadgeEarnedRow({
    required this.id,
    required this.badgeId,
    required this.earnedAt,
    this.cycleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['badge_id'] = Variable<String>(badgeId);
    map['earned_at'] = Variable<int>(earnedAt);
    if (!nullToAbsent || cycleId != null) {
      map['cycle_id'] = Variable<int>(cycleId);
    }
    return map;
  }

  BadgesEarnedCompanion toCompanion(bool nullToAbsent) {
    return BadgesEarnedCompanion(
      id: Value(id),
      badgeId: Value(badgeId),
      earnedAt: Value(earnedAt),
      cycleId: cycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleId),
    );
  }

  factory BadgeEarnedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BadgeEarnedRow(
      id: serializer.fromJson<int>(json['id']),
      badgeId: serializer.fromJson<String>(json['badgeId']),
      earnedAt: serializer.fromJson<int>(json['earnedAt']),
      cycleId: serializer.fromJson<int?>(json['cycleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'badgeId': serializer.toJson<String>(badgeId),
      'earnedAt': serializer.toJson<int>(earnedAt),
      'cycleId': serializer.toJson<int?>(cycleId),
    };
  }

  BadgeEarnedRow copyWith({
    int? id,
    String? badgeId,
    int? earnedAt,
    Value<int?> cycleId = const Value.absent(),
  }) => BadgeEarnedRow(
    id: id ?? this.id,
    badgeId: badgeId ?? this.badgeId,
    earnedAt: earnedAt ?? this.earnedAt,
    cycleId: cycleId.present ? cycleId.value : this.cycleId,
  );
  BadgeEarnedRow copyWithCompanion(BadgesEarnedCompanion data) {
    return BadgeEarnedRow(
      id: data.id.present ? data.id.value : this.id,
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BadgeEarnedRow(')
          ..write('id: $id, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('cycleId: $cycleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, badgeId, earnedAt, cycleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BadgeEarnedRow &&
          other.id == this.id &&
          other.badgeId == this.badgeId &&
          other.earnedAt == this.earnedAt &&
          other.cycleId == this.cycleId);
}

class BadgesEarnedCompanion extends UpdateCompanion<BadgeEarnedRow> {
  final Value<int> id;
  final Value<String> badgeId;
  final Value<int> earnedAt;
  final Value<int?> cycleId;
  const BadgesEarnedCompanion({
    this.id = const Value.absent(),
    this.badgeId = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.cycleId = const Value.absent(),
  });
  BadgesEarnedCompanion.insert({
    this.id = const Value.absent(),
    required String badgeId,
    required int earnedAt,
    this.cycleId = const Value.absent(),
  }) : badgeId = Value(badgeId),
       earnedAt = Value(earnedAt);
  static Insertable<BadgeEarnedRow> custom({
    Expression<int>? id,
    Expression<String>? badgeId,
    Expression<int>? earnedAt,
    Expression<int>? cycleId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (badgeId != null) 'badge_id': badgeId,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (cycleId != null) 'cycle_id': cycleId,
    });
  }

  BadgesEarnedCompanion copyWith({
    Value<int>? id,
    Value<String>? badgeId,
    Value<int>? earnedAt,
    Value<int?>? cycleId,
  }) {
    return BadgesEarnedCompanion(
      id: id ?? this.id,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      cycleId: cycleId ?? this.cycleId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(badgeId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<int>(earnedAt.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BadgesEarnedCompanion(')
          ..write('id: $id, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('cycleId: $cycleId')
          ..write(')'))
        .toString();
  }
}

class $OwnedItemsTable extends OwnedItems
    with TableInfo<$OwnedItemsTable, OwnedItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<OwnedItemType, String> itemType =
      GeneratedColumn<String>(
        'item_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OwnedItemType>($OwnedItemsTable.$converteritemType);
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _acquiredAtMeta = const VerificationMeta(
    'acquiredAt',
  );
  @override
  late final GeneratedColumn<int> acquiredAt = GeneratedColumn<int>(
    'acquired_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    itemType,
    quantity,
    acquiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owned_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnedItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
        _acquiredAtMeta,
        acquiredAt.isAcceptableOrUnknown(data['acquired_at']!, _acquiredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnedItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnedItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: $OwnedItemsTable.$converteritemType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}item_type'],
        )!,
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      acquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acquired_at'],
      )!,
    );
  }

  @override
  $OwnedItemsTable createAlias(String alias) {
    return $OwnedItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<OwnedItemType, String> $converteritemType =
      const SnakeEnumConverter<OwnedItemType>(OwnedItemType.values);
}

class OwnedItemRow extends DataClass implements Insertable<OwnedItemRow> {
  final int id;
  final String itemId;
  final OwnedItemType itemType;
  final int quantity;
  final int acquiredAt;
  const OwnedItemRow({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.quantity,
    required this.acquiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    {
      map['item_type'] = Variable<String>(
        $OwnedItemsTable.$converteritemType.toSql(itemType),
      );
    }
    map['quantity'] = Variable<int>(quantity);
    map['acquired_at'] = Variable<int>(acquiredAt);
    return map;
  }

  OwnedItemsCompanion toCompanion(bool nullToAbsent) {
    return OwnedItemsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      itemType: Value(itemType),
      quantity: Value(quantity),
      acquiredAt: Value(acquiredAt),
    );
  }

  factory OwnedItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnedItemRow(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<OwnedItemType>(json['itemType']),
      quantity: serializer.fromJson<int>(json['quantity']),
      acquiredAt: serializer.fromJson<int>(json['acquiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<OwnedItemType>(itemType),
      'quantity': serializer.toJson<int>(quantity),
      'acquiredAt': serializer.toJson<int>(acquiredAt),
    };
  }

  OwnedItemRow copyWith({
    int? id,
    String? itemId,
    OwnedItemType? itemType,
    int? quantity,
    int? acquiredAt,
  }) => OwnedItemRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    quantity: quantity ?? this.quantity,
    acquiredAt: acquiredAt ?? this.acquiredAt,
  );
  OwnedItemRow copyWithCompanion(OwnedItemsCompanion data) {
    return OwnedItemRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      acquiredAt: data.acquiredAt.present
          ? data.acquiredAt.value
          : this.acquiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnedItemRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('quantity: $quantity, ')
          ..write('acquiredAt: $acquiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, itemType, quantity, acquiredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnedItemRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.quantity == this.quantity &&
          other.acquiredAt == this.acquiredAt);
}

class OwnedItemsCompanion extends UpdateCompanion<OwnedItemRow> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<OwnedItemType> itemType;
  final Value<int> quantity;
  final Value<int> acquiredAt;
  const OwnedItemsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.acquiredAt = const Value.absent(),
  });
  OwnedItemsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required OwnedItemType itemType,
    this.quantity = const Value.absent(),
    required int acquiredAt,
  }) : itemId = Value(itemId),
       itemType = Value(itemType),
       acquiredAt = Value(acquiredAt);
  static Insertable<OwnedItemRow> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<int>? quantity,
    Expression<int>? acquiredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (quantity != null) 'quantity': quantity,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
    });
  }

  OwnedItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<OwnedItemType>? itemType,
    Value<int>? quantity,
    Value<int>? acquiredAt,
  }) {
    return OwnedItemsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      acquiredAt: acquiredAt ?? this.acquiredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(
        $OwnedItemsTable.$converteritemType.toSql(itemType.value),
      );
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<int>(acquiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnedItemsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('quantity: $quantity, ')
          ..write('acquiredAt: $acquiredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CurrenciesTable currencies = $CurrenciesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CyclesTable cycles = $CyclesTable(this);
  late final $CycleSummariesTable cycleSummaries = $CycleSummariesTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $WellsTable wells = $WellsTable(this);
  late final $IncomeEntriesTable incomeEntries = $IncomeEntriesTable(this);
  late final $CropsCatalogTable cropsCatalog = $CropsCatalogTable(this);
  late final $PlotsTable plots = $PlotsTable(this);
  late final $BonusAllocationsTable bonusAllocations = $BonusAllocationsTable(
    this,
  );
  late final $SavingsBarnTable savingsBarn = $SavingsBarnTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PlotCycleResultsTable plotCycleResults = $PlotCycleResultsTable(
    this,
  );
  late final $PlotFertilizerApplicationsTable plotFertilizerApplications =
      $PlotFertilizerApplicationsTable(this);
  late final $CoinLedgerTable coinLedger = $CoinLedgerTable(this);
  late final $BadgesEarnedTable badgesEarned = $BadgesEarnedTable(this);
  late final $OwnedItemsTable ownedItems = $OwnedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    currencies,
    appSettings,
    cycles,
    cycleSummaries,
    exchangeRates,
    wells,
    incomeEntries,
    cropsCatalog,
    plots,
    bonusAllocations,
    savingsBarn,
    transactions,
    plotCycleResults,
    plotFertilizerApplications,
    coinLedger,
    badgesEarned,
    ownedItems,
  ];
}

typedef $$CurrenciesTableCreateCompanionBuilder =
    CurrenciesCompanion Function({
      required String code,
      required String symbol,
      required String name,
      required int decimalPlaces,
      Value<bool> isBase,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<int> rowid,
    });
typedef $$CurrenciesTableUpdateCompanionBuilder =
    CurrenciesCompanion Function({
      Value<String> code,
      Value<String> symbol,
      Value<String> name,
      Value<int> decimalPlaces,
      Value<bool> isBase,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<int> rowid,
    });

final class $$CurrenciesTableReferences
    extends BaseReferences<_$AppDatabase, $CurrenciesTable, CurrencyRow> {
  $$CurrenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppSettingsTable, List<AppSettingsRow>>
  _appSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.appSettings.baseCurrencyCode,
    ),
  );

  $$AppSettingsTableProcessedTableManager get appSettingsRefs {
    final manager = $$AppSettingsTableTableManager($_db, $_db.appSettings)
        .filter(
          (f) =>
              f.baseCurrencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WellsTable, List<WellRow>> _wellsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.wells,
    aliasName: $_aliasNameGenerator(db.currencies.code, db.wells.currencyCode),
  );

  $$WellsTableProcessedTableManager get wellsRefs {
    final manager = $$WellsTableTableManager($_db, $_db.wells).filter(
      (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(_wellsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IncomeEntriesTable, List<IncomeEntryRow>>
  _incomeEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incomeEntries,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.incomeEntries.currencyCode,
    ),
  );

  $$IncomeEntriesTableProcessedTableManager get incomeEntriesRefs {
    final manager = $$IncomeEntriesTableTableManager($_db, $_db.incomeEntries)
        .filter(
          (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_incomeEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlotsTable, List<PlotRow>> _plotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plots,
    aliasName: $_aliasNameGenerator(db.currencies.code, db.plots.currencyCode),
  );

  $$PlotsTableProcessedTableManager get plotsRefs {
    final manager = $$PlotsTableTableManager($_db, $_db.plots).filter(
      (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(_plotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.transactions.currencyCode,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlotCycleResultsTable, List<PlotCycleResultRow>>
  _plotCycleResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plotCycleResults,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.plotCycleResults.currencyCodeSnapshot,
    ),
  );

  $$PlotCycleResultsTableProcessedTableManager get plotCycleResultsRefs {
    final manager =
        $$PlotCycleResultsTableTableManager($_db, $_db.plotCycleResults).filter(
          (f) => f.currencyCodeSnapshot.code.sqlEquals(
            $_itemColumn<String>('code')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _plotCycleResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurrenciesTableFilterComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($$AppSettingsTableFilterComposer f) f,
  ) {
    final $$AppSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.baseCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wellsRefs(
    Expression<bool> Function($$WellsTableFilterComposer f) f,
  ) {
    final $$WellsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.wells,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WellsTableFilterComposer(
            $db: $db,
            $table: $db.wells,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomeEntriesRefs(
    Expression<bool> Function($$IncomeEntriesTableFilterComposer f) f,
  ) {
    final $$IncomeEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableFilterComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotsRefs(
    Expression<bool> Function($$PlotsTableFilterComposer f) f,
  ) {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotCycleResultsRefs(
    Expression<bool> Function($$PlotCycleResultsTableFilterComposer f) f,
  ) {
    final $$PlotCycleResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.currencyCodeSnapshot,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableFilterComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get decimalPlaces => $composableBuilder(
    column: $table.decimalPlaces,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBase =>
      $composableBuilder(column: $table.isBase, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($$AppSettingsTableAnnotationComposer a) f,
  ) {
    final $$AppSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.baseCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wellsRefs<T extends Object>(
    Expression<T> Function($$WellsTableAnnotationComposer a) f,
  ) {
    final $$WellsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.wells,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WellsTableAnnotationComposer(
            $db: $db,
            $table: $db.wells,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomeEntriesRefs<T extends Object>(
    Expression<T> Function($$IncomeEntriesTableAnnotationComposer a) f,
  ) {
    final $$IncomeEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotsRefs<T extends Object>(
    Expression<T> Function($$PlotsTableAnnotationComposer a) f,
  ) {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotCycleResultsRefs<T extends Object>(
    Expression<T> Function($$PlotCycleResultsTableAnnotationComposer a) f,
  ) {
    final $$PlotCycleResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.currencyCodeSnapshot,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurrenciesTable,
          CurrencyRow,
          $$CurrenciesTableFilterComposer,
          $$CurrenciesTableOrderingComposer,
          $$CurrenciesTableAnnotationComposer,
          $$CurrenciesTableCreateCompanionBuilder,
          $$CurrenciesTableUpdateCompanionBuilder,
          (CurrencyRow, $$CurrenciesTableReferences),
          CurrencyRow,
          PrefetchHooks Function({
            bool appSettingsRefs,
            bool wellsRefs,
            bool incomeEntriesRefs,
            bool plotsRefs,
            bool transactionsRefs,
            bool plotCycleResultsRefs,
          })
        > {
  $$CurrenciesTableTableManager(_$AppDatabase db, $CurrenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> decimalPlaces = const Value.absent(),
                Value<bool> isBase = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion(
                code: code,
                symbol: symbol,
                name: name,
                decimalPlaces: decimalPlaces,
                isBase: isBase,
                isActive: isActive,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String symbol,
                required String name,
                required int decimalPlaces,
                Value<bool> isBase = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion.insert(
                code: code,
                symbol: symbol,
                name: name,
                decimalPlaces: decimalPlaces,
                isBase: isBase,
                isActive: isActive,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CurrenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                appSettingsRefs = false,
                wellsRefs = false,
                incomeEntriesRefs = false,
                plotsRefs = false,
                transactionsRefs = false,
                plotCycleResultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appSettingsRefs) db.appSettings,
                    if (wellsRefs) db.wells,
                    if (incomeEntriesRefs) db.incomeEntries,
                    if (plotsRefs) db.plots,
                    if (transactionsRefs) db.transactions,
                    if (plotCycleResultsRefs) db.plotCycleResults,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (appSettingsRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          AppSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._appSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).appSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.baseCurrencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (wellsRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          WellRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._wellsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).wellsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (incomeEntriesRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          IncomeEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._incomeEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomeEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (plotsRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          PlotRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._plotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).plotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (plotCycleResultsRefs)
                        await $_getPrefetchedData<
                          CurrencyRow,
                          $CurrenciesTable,
                          PlotCycleResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._plotCycleResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).plotCycleResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCodeSnapshot == item.code,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CurrenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurrenciesTable,
      CurrencyRow,
      $$CurrenciesTableFilterComposer,
      $$CurrenciesTableOrderingComposer,
      $$CurrenciesTableAnnotationComposer,
      $$CurrenciesTableCreateCompanionBuilder,
      $$CurrenciesTableUpdateCompanionBuilder,
      (CurrencyRow, $$CurrenciesTableReferences),
      CurrencyRow,
      PrefetchHooks Function({
        bool appSettingsRefs,
        bool wellsRefs,
        bool incomeEntriesRefs,
        bool plotsRefs,
        bool transactionsRefs,
        bool plotCycleResultsRefs,
      })
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String farmerName,
      required String avatarId,
      required String baseCurrencyCode,
      Value<bool> onboardingCompleted,
      Value<int> farmerLevel,
      Value<int> farmerXp,
      Value<int> coinsBalance,
      Value<bool> notificationsEnabled,
      required int createdAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> farmerName,
      Value<String> avatarId,
      Value<String> baseCurrencyCode,
      Value<bool> onboardingCompleted,
      Value<int> farmerLevel,
      Value<int> farmerXp,
      Value<int> coinsBalance,
      Value<bool> notificationsEnabled,
      Value<int> createdAt,
    });

final class $$AppSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow> {
  $$AppSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _baseCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.appSettings.baseCurrencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get baseCurrencyCode {
    final $_column = $_itemColumn<String>('base_currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmerName => $composableBuilder(
    column: $table.farmerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get farmerLevel => $composableBuilder(
    column: $table.farmerLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get farmerXp => $composableBuilder(
    column: $table.farmerXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coinsBalance => $composableBuilder(
    column: $table.coinsBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get baseCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmerName => $composableBuilder(
    column: $table.farmerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get farmerLevel => $composableBuilder(
    column: $table.farmerLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get farmerXp => $composableBuilder(
    column: $table.farmerXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coinsBalance => $composableBuilder(
    column: $table.coinsBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get baseCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get farmerName => $composableBuilder(
    column: $table.farmerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarId =>
      $composableBuilder(column: $table.avatarId, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get farmerLevel => $composableBuilder(
    column: $table.farmerLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get farmerXp =>
      $composableBuilder(column: $table.farmerXp, builder: (column) => column);

  GeneratedColumn<int> get coinsBalance => $composableBuilder(
    column: $table.coinsBalance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get baseCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSettingsRow, $$AppSettingsTableReferences),
          AppSettingsRow,
          PrefetchHooks Function({bool baseCurrencyCode})
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> farmerName = const Value.absent(),
                Value<String> avatarId = const Value.absent(),
                Value<String> baseCurrencyCode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> farmerLevel = const Value.absent(),
                Value<int> farmerXp = const Value.absent(),
                Value<int> coinsBalance = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                farmerName: farmerName,
                avatarId: avatarId,
                baseCurrencyCode: baseCurrencyCode,
                onboardingCompleted: onboardingCompleted,
                farmerLevel: farmerLevel,
                farmerXp: farmerXp,
                coinsBalance: coinsBalance,
                notificationsEnabled: notificationsEnabled,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String farmerName,
                required String avatarId,
                required String baseCurrencyCode,
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> farmerLevel = const Value.absent(),
                Value<int> farmerXp = const Value.absent(),
                Value<int> coinsBalance = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                required int createdAt,
              }) => AppSettingsCompanion.insert(
                id: id,
                farmerName: farmerName,
                avatarId: avatarId,
                baseCurrencyCode: baseCurrencyCode,
                onboardingCompleted: onboardingCompleted,
                farmerLevel: farmerLevel,
                farmerXp: farmerXp,
                coinsBalance: coinsBalance,
                notificationsEnabled: notificationsEnabled,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({baseCurrencyCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (baseCurrencyCode) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.baseCurrencyCode,
                                referencedTable: $$AppSettingsTableReferences
                                    ._baseCurrencyCodeTable(db),
                                referencedColumn: $$AppSettingsTableReferences
                                    ._baseCurrencyCodeTable(db)
                                    .code,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSettingsRow, $$AppSettingsTableReferences),
      AppSettingsRow,
      PrefetchHooks Function({bool baseCurrencyCode})
    >;
typedef $$CyclesTableCreateCompanionBuilder =
    CyclesCompanion Function({
      Value<int> id,
      required int startDate,
      required int endDate,
      required CycleState state,
      Value<String?> label,
      required int createdAt,
      Value<int?> completedAt,
    });
typedef $$CyclesTableUpdateCompanionBuilder =
    CyclesCompanion Function({
      Value<int> id,
      Value<int> startDate,
      Value<int> endDate,
      Value<CycleState> state,
      Value<String?> label,
      Value<int> createdAt,
      Value<int?> completedAt,
    });

final class $$CyclesTableReferences
    extends BaseReferences<_$AppDatabase, $CyclesTable, CycleRow> {
  $$CyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CycleSummariesTable, List<CycleSummaryRow>>
  _cycleSummariesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cycleSummaries,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.cycleSummaries.cycleId),
  );

  $$CycleSummariesTableProcessedTableManager get cycleSummariesRefs {
    final manager = $$CycleSummariesTableTableManager(
      $_db,
      $_db.cycleSummaries,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cycleSummariesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExchangeRatesTable, List<ExchangeRateRow>>
  _exchangeRatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exchangeRates,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.exchangeRates.cycleId),
  );

  $$ExchangeRatesTableProcessedTableManager get exchangeRatesRefs {
    final manager = $$ExchangeRatesTableTableManager(
      $_db,
      $_db.exchangeRates,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_exchangeRatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IncomeEntriesTable, List<IncomeEntryRow>>
  _incomeEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incomeEntries,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.incomeEntries.cycleId),
  );

  $$IncomeEntriesTableProcessedTableManager get incomeEntriesRefs {
    final manager = $$IncomeEntriesTableTableManager(
      $_db,
      $_db.incomeEntries,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomeEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BonusAllocationsTable, List<BonusAllocationRow>>
  _bonusAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bonusAllocations,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.bonusAllocations.cycleId),
  );

  $$BonusAllocationsTableProcessedTableManager get bonusAllocationsRefs {
    final manager = $$BonusAllocationsTableTableManager(
      $_db,
      $_db.bonusAllocations,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bonusAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.transactions.cycleId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlotCycleResultsTable, List<PlotCycleResultRow>>
  _plotCycleResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plotCycleResults,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.plotCycleResults.cycleId),
  );

  $$PlotCycleResultsTableProcessedTableManager get plotCycleResultsRefs {
    final manager = $$PlotCycleResultsTableTableManager(
      $_db,
      $_db.plotCycleResults,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plotCycleResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlotFertilizerApplicationsTable,
    List<PlotFertilizerApplicationRow>
  >
  _plotFertilizerApplicationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.plotFertilizerApplications,
        aliasName: $_aliasNameGenerator(
          db.cycles.id,
          db.plotFertilizerApplications.cycleId,
        ),
      );

  $$PlotFertilizerApplicationsTableProcessedTableManager
  get plotFertilizerApplicationsRefs {
    final manager = $$PlotFertilizerApplicationsTableTableManager(
      $_db,
      $_db.plotFertilizerApplications,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plotFertilizerApplicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CoinLedgerTable, List<CoinLedgerRow>>
  _coinLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.coinLedger,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.coinLedger.cycleId),
  );

  $$CoinLedgerTableProcessedTableManager get coinLedgerRefs {
    final manager = $$CoinLedgerTableTableManager(
      $_db,
      $_db.coinLedger,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_coinLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BadgesEarnedTable, List<BadgeEarnedRow>>
  _badgesEarnedRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.badgesEarned,
    aliasName: $_aliasNameGenerator(db.cycles.id, db.badgesEarned.cycleId),
  );

  $$BadgesEarnedTableProcessedTableManager get badgesEarnedRefs {
    final manager = $$BadgesEarnedTableTableManager(
      $_db,
      $_db.badgesEarned,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_badgesEarnedRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CyclesTableFilterComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CycleState, CycleState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cycleSummariesRefs(
    Expression<bool> Function($$CycleSummariesTableFilterComposer f) f,
  ) {
    final $$CycleSummariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cycleSummaries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CycleSummariesTableFilterComposer(
            $db: $db,
            $table: $db.cycleSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exchangeRatesRefs(
    Expression<bool> Function($$ExchangeRatesTableFilterComposer f) f,
  ) {
    final $$ExchangeRatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableFilterComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomeEntriesRefs(
    Expression<bool> Function($$IncomeEntriesTableFilterComposer f) f,
  ) {
    final $$IncomeEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableFilterComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bonusAllocationsRefs(
    Expression<bool> Function($$BonusAllocationsTableFilterComposer f) f,
  ) {
    final $$BonusAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bonusAllocations,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BonusAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.bonusAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotCycleResultsRefs(
    Expression<bool> Function($$PlotCycleResultsTableFilterComposer f) f,
  ) {
    final $$PlotCycleResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableFilterComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotFertilizerApplicationsRefs(
    Expression<bool> Function($$PlotFertilizerApplicationsTableFilterComposer f)
    f,
  ) {
    final $$PlotFertilizerApplicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.plotFertilizerApplications,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlotFertilizerApplicationsTableFilterComposer(
                $db: $db,
                $table: $db.plotFertilizerApplications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> coinLedgerRefs(
    Expression<bool> Function($$CoinLedgerTableFilterComposer f) f,
  ) {
    final $$CoinLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coinLedger,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoinLedgerTableFilterComposer(
            $db: $db,
            $table: $db.coinLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> badgesEarnedRefs(
    Expression<bool> Function($$BadgesEarnedTableFilterComposer f) f,
  ) {
    final $$BadgesEarnedTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.badgesEarned,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BadgesEarnedTableFilterComposer(
            $db: $db,
            $table: $db.badgesEarned,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CycleState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  Expression<T> cycleSummariesRefs<T extends Object>(
    Expression<T> Function($$CycleSummariesTableAnnotationComposer a) f,
  ) {
    final $$CycleSummariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cycleSummaries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CycleSummariesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycleSummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exchangeRatesRefs<T extends Object>(
    Expression<T> Function($$ExchangeRatesTableAnnotationComposer a) f,
  ) {
    final $$ExchangeRatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableAnnotationComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomeEntriesRefs<T extends Object>(
    Expression<T> Function($$IncomeEntriesTableAnnotationComposer a) f,
  ) {
    final $$IncomeEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bonusAllocationsRefs<T extends Object>(
    Expression<T> Function($$BonusAllocationsTableAnnotationComposer a) f,
  ) {
    final $$BonusAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bonusAllocations,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BonusAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.bonusAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotCycleResultsRefs<T extends Object>(
    Expression<T> Function($$PlotCycleResultsTableAnnotationComposer a) f,
  ) {
    final $$PlotCycleResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotFertilizerApplicationsRefs<T extends Object>(
    Expression<T> Function(
      $$PlotFertilizerApplicationsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$PlotFertilizerApplicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.plotFertilizerApplications,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlotFertilizerApplicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.plotFertilizerApplications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> coinLedgerRefs<T extends Object>(
    Expression<T> Function($$CoinLedgerTableAnnotationComposer a) f,
  ) {
    final $$CoinLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coinLedger,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoinLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.coinLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> badgesEarnedRefs<T extends Object>(
    Expression<T> Function($$BadgesEarnedTableAnnotationComposer a) f,
  ) {
    final $$BadgesEarnedTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.badgesEarned,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BadgesEarnedTableAnnotationComposer(
            $db: $db,
            $table: $db.badgesEarned,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CyclesTable,
          CycleRow,
          $$CyclesTableFilterComposer,
          $$CyclesTableOrderingComposer,
          $$CyclesTableAnnotationComposer,
          $$CyclesTableCreateCompanionBuilder,
          $$CyclesTableUpdateCompanionBuilder,
          (CycleRow, $$CyclesTableReferences),
          CycleRow,
          PrefetchHooks Function({
            bool cycleSummariesRefs,
            bool exchangeRatesRefs,
            bool incomeEntriesRefs,
            bool bonusAllocationsRefs,
            bool transactionsRefs,
            bool plotCycleResultsRefs,
            bool plotFertilizerApplicationsRefs,
            bool coinLedgerRefs,
            bool badgesEarnedRefs,
          })
        > {
  $$CyclesTableTableManager(_$AppDatabase db, $CyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> endDate = const Value.absent(),
                Value<CycleState> state = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => CyclesCompanion(
                id: id,
                startDate: startDate,
                endDate: endDate,
                state: state,
                label: label,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startDate,
                required int endDate,
                required CycleState state,
                Value<String?> label = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
              }) => CyclesCompanion.insert(
                id: id,
                startDate: startDate,
                endDate: endDate,
                state: state,
                label: label,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CyclesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cycleSummariesRefs = false,
                exchangeRatesRefs = false,
                incomeEntriesRefs = false,
                bonusAllocationsRefs = false,
                transactionsRefs = false,
                plotCycleResultsRefs = false,
                plotFertilizerApplicationsRefs = false,
                coinLedgerRefs = false,
                badgesEarnedRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cycleSummariesRefs) db.cycleSummaries,
                    if (exchangeRatesRefs) db.exchangeRates,
                    if (incomeEntriesRefs) db.incomeEntries,
                    if (bonusAllocationsRefs) db.bonusAllocations,
                    if (transactionsRefs) db.transactions,
                    if (plotCycleResultsRefs) db.plotCycleResults,
                    if (plotFertilizerApplicationsRefs)
                      db.plotFertilizerApplications,
                    if (coinLedgerRefs) db.coinLedger,
                    if (badgesEarnedRefs) db.badgesEarned,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cycleSummariesRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          CycleSummaryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._cycleSummariesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).cycleSummariesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exchangeRatesRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          ExchangeRateRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._exchangeRatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).exchangeRatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incomeEntriesRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          IncomeEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._incomeEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomeEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bonusAllocationsRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          BonusAllocationRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._bonusAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).bonusAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plotCycleResultsRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          PlotCycleResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._plotCycleResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).plotCycleResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plotFertilizerApplicationsRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          PlotFertilizerApplicationRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._plotFertilizerApplicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).plotFertilizerApplicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coinLedgerRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          CoinLedgerRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._coinLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).coinLedgerRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (badgesEarnedRefs)
                        await $_getPrefetchedData<
                          CycleRow,
                          $CyclesTable,
                          BadgeEarnedRow
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._badgesEarnedRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).badgesEarnedRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CyclesTable,
      CycleRow,
      $$CyclesTableFilterComposer,
      $$CyclesTableOrderingComposer,
      $$CyclesTableAnnotationComposer,
      $$CyclesTableCreateCompanionBuilder,
      $$CyclesTableUpdateCompanionBuilder,
      (CycleRow, $$CyclesTableReferences),
      CycleRow,
      PrefetchHooks Function({
        bool cycleSummariesRefs,
        bool exchangeRatesRefs,
        bool incomeEntriesRefs,
        bool bonusAllocationsRefs,
        bool transactionsRefs,
        bool plotCycleResultsRefs,
        bool plotFertilizerApplicationsRefs,
        bool coinLedgerRefs,
        bool badgesEarnedRefs,
      })
    >;
typedef $$CycleSummariesTableCreateCompanionBuilder =
    CycleSummariesCompanion Function({
      Value<int> id,
      required int cycleId,
      required int totalFoundationIncome,
      required int totalBonusIncome,
      required int totalSpentPlanned,
      required int totalSpentUnplanned,
      required int totalSpent,
      required int surplus,
      required CycleResultTier resultTier,
      Value<int> overallBonusCoins,
      Value<int> perPlotCoins,
      Value<int> surplusSavedCoins,
      Value<int> totalCoinsEarned,
      Value<int> amountSaved,
      Value<int> amountRolledToNext,
      required int completedAt,
    });
typedef $$CycleSummariesTableUpdateCompanionBuilder =
    CycleSummariesCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<int> totalFoundationIncome,
      Value<int> totalBonusIncome,
      Value<int> totalSpentPlanned,
      Value<int> totalSpentUnplanned,
      Value<int> totalSpent,
      Value<int> surplus,
      Value<CycleResultTier> resultTier,
      Value<int> overallBonusCoins,
      Value<int> perPlotCoins,
      Value<int> surplusSavedCoins,
      Value<int> totalCoinsEarned,
      Value<int> amountSaved,
      Value<int> amountRolledToNext,
      Value<int> completedAt,
    });

final class $$CycleSummariesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CycleSummariesTable, CycleSummaryRow> {
  $$CycleSummariesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.cycleSummaries.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CycleSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $CycleSummariesTable> {
  $$CycleSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFoundationIncome => $composableBuilder(
    column: $table.totalFoundationIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBonusIncome => $composableBuilder(
    column: $table.totalBonusIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSpentPlanned => $composableBuilder(
    column: $table.totalSpentPlanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSpentUnplanned => $composableBuilder(
    column: $table.totalSpentUnplanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surplus => $composableBuilder(
    column: $table.surplus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CycleResultTier, CycleResultTier, String>
  get resultTier => $composableBuilder(
    column: $table.resultTier,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get overallBonusCoins => $composableBuilder(
    column: $table.overallBonusCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perPlotCoins => $composableBuilder(
    column: $table.perPlotCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surplusSavedCoins => $composableBuilder(
    column: $table.surplusSavedCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCoinsEarned => $composableBuilder(
    column: $table.totalCoinsEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountSaved => $composableBuilder(
    column: $table.amountSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRolledToNext => $composableBuilder(
    column: $table.amountRolledToNext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $CycleSummariesTable> {
  $$CycleSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFoundationIncome => $composableBuilder(
    column: $table.totalFoundationIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBonusIncome => $composableBuilder(
    column: $table.totalBonusIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSpentPlanned => $composableBuilder(
    column: $table.totalSpentPlanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSpentUnplanned => $composableBuilder(
    column: $table.totalSpentUnplanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surplus => $composableBuilder(
    column: $table.surplus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultTier => $composableBuilder(
    column: $table.resultTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallBonusCoins => $composableBuilder(
    column: $table.overallBonusCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perPlotCoins => $composableBuilder(
    column: $table.perPlotCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surplusSavedCoins => $composableBuilder(
    column: $table.surplusSavedCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCoinsEarned => $composableBuilder(
    column: $table.totalCoinsEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountSaved => $composableBuilder(
    column: $table.amountSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRolledToNext => $composableBuilder(
    column: $table.amountRolledToNext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CycleSummariesTable> {
  $$CycleSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalFoundationIncome => $composableBuilder(
    column: $table.totalFoundationIncome,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBonusIncome => $composableBuilder(
    column: $table.totalBonusIncome,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSpentPlanned => $composableBuilder(
    column: $table.totalSpentPlanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSpentUnplanned => $composableBuilder(
    column: $table.totalSpentUnplanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get surplus =>
      $composableBuilder(column: $table.surplus, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CycleResultTier, String> get resultTier =>
      $composableBuilder(
        column: $table.resultTier,
        builder: (column) => column,
      );

  GeneratedColumn<int> get overallBonusCoins => $composableBuilder(
    column: $table.overallBonusCoins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get perPlotCoins => $composableBuilder(
    column: $table.perPlotCoins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get surplusSavedCoins => $composableBuilder(
    column: $table.surplusSavedCoins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCoinsEarned => $composableBuilder(
    column: $table.totalCoinsEarned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountSaved => $composableBuilder(
    column: $table.amountSaved,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountRolledToNext => $composableBuilder(
    column: $table.amountRolledToNext,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CycleSummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CycleSummariesTable,
          CycleSummaryRow,
          $$CycleSummariesTableFilterComposer,
          $$CycleSummariesTableOrderingComposer,
          $$CycleSummariesTableAnnotationComposer,
          $$CycleSummariesTableCreateCompanionBuilder,
          $$CycleSummariesTableUpdateCompanionBuilder,
          (CycleSummaryRow, $$CycleSummariesTableReferences),
          CycleSummaryRow,
          PrefetchHooks Function({bool cycleId})
        > {
  $$CycleSummariesTableTableManager(
    _$AppDatabase db,
    $CycleSummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CycleSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CycleSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CycleSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> totalFoundationIncome = const Value.absent(),
                Value<int> totalBonusIncome = const Value.absent(),
                Value<int> totalSpentPlanned = const Value.absent(),
                Value<int> totalSpentUnplanned = const Value.absent(),
                Value<int> totalSpent = const Value.absent(),
                Value<int> surplus = const Value.absent(),
                Value<CycleResultTier> resultTier = const Value.absent(),
                Value<int> overallBonusCoins = const Value.absent(),
                Value<int> perPlotCoins = const Value.absent(),
                Value<int> surplusSavedCoins = const Value.absent(),
                Value<int> totalCoinsEarned = const Value.absent(),
                Value<int> amountSaved = const Value.absent(),
                Value<int> amountRolledToNext = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
              }) => CycleSummariesCompanion(
                id: id,
                cycleId: cycleId,
                totalFoundationIncome: totalFoundationIncome,
                totalBonusIncome: totalBonusIncome,
                totalSpentPlanned: totalSpentPlanned,
                totalSpentUnplanned: totalSpentUnplanned,
                totalSpent: totalSpent,
                surplus: surplus,
                resultTier: resultTier,
                overallBonusCoins: overallBonusCoins,
                perPlotCoins: perPlotCoins,
                surplusSavedCoins: surplusSavedCoins,
                totalCoinsEarned: totalCoinsEarned,
                amountSaved: amountSaved,
                amountRolledToNext: amountRolledToNext,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required int totalFoundationIncome,
                required int totalBonusIncome,
                required int totalSpentPlanned,
                required int totalSpentUnplanned,
                required int totalSpent,
                required int surplus,
                required CycleResultTier resultTier,
                Value<int> overallBonusCoins = const Value.absent(),
                Value<int> perPlotCoins = const Value.absent(),
                Value<int> surplusSavedCoins = const Value.absent(),
                Value<int> totalCoinsEarned = const Value.absent(),
                Value<int> amountSaved = const Value.absent(),
                Value<int> amountRolledToNext = const Value.absent(),
                required int completedAt,
              }) => CycleSummariesCompanion.insert(
                id: id,
                cycleId: cycleId,
                totalFoundationIncome: totalFoundationIncome,
                totalBonusIncome: totalBonusIncome,
                totalSpentPlanned: totalSpentPlanned,
                totalSpentUnplanned: totalSpentUnplanned,
                totalSpent: totalSpent,
                surplus: surplus,
                resultTier: resultTier,
                overallBonusCoins: overallBonusCoins,
                perPlotCoins: perPlotCoins,
                surplusSavedCoins: surplusSavedCoins,
                totalCoinsEarned: totalCoinsEarned,
                amountSaved: amountSaved,
                amountRolledToNext: amountRolledToNext,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CycleSummariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable: $$CycleSummariesTableReferences
                                    ._cycleIdTable(db),
                                referencedColumn:
                                    $$CycleSummariesTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CycleSummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CycleSummariesTable,
      CycleSummaryRow,
      $$CycleSummariesTableFilterComposer,
      $$CycleSummariesTableOrderingComposer,
      $$CycleSummariesTableAnnotationComposer,
      $$CycleSummariesTableCreateCompanionBuilder,
      $$CycleSummariesTableUpdateCompanionBuilder,
      (CycleSummaryRow, $$CycleSummariesTableReferences),
      CycleSummaryRow,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<int> id,
      required int cycleId,
      required String fromCurrencyCode,
      required String toCurrencyCode,
      required double rate,
      required int setAt,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<String> fromCurrencyCode,
      Value<String> toCurrencyCode,
      Value<double> rate,
      Value<int> setAt,
    });

final class $$ExchangeRatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRateRow> {
  $$ExchangeRatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.exchangeRates.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _fromCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.exchangeRates.fromCurrencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get fromCurrencyCode {
    final $_column = $_itemColumn<String>('from_currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _toCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.exchangeRates.toCurrencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get toCurrencyCode {
    final $_column = $_itemColumn<String>('to_currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get fromCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get toCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get fromCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get toCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<int> get setAt =>
      $composableBuilder(column: $table.setAt, builder: (column) => column);

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get fromCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get toCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExchangeRatesTable,
          ExchangeRateRow,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (ExchangeRateRow, $$ExchangeRatesTableReferences),
          ExchangeRateRow,
          PrefetchHooks Function({
            bool cycleId,
            bool fromCurrencyCode,
            bool toCurrencyCode,
          })
        > {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<String> fromCurrencyCode = const Value.absent(),
                Value<String> toCurrencyCode = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<int> setAt = const Value.absent(),
              }) => ExchangeRatesCompanion(
                id: id,
                cycleId: cycleId,
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                setAt: setAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required String fromCurrencyCode,
                required String toCurrencyCode,
                required double rate,
                required int setAt,
              }) => ExchangeRatesCompanion.insert(
                id: id,
                cycleId: cycleId,
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                setAt: setAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExchangeRatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cycleId = false,
                fromCurrencyCode = false,
                toCurrencyCode = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$ExchangeRatesTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$ExchangeRatesTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (fromCurrencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromCurrencyCode,
                                    referencedTable:
                                        $$ExchangeRatesTableReferences
                                            ._fromCurrencyCodeTable(db),
                                    referencedColumn:
                                        $$ExchangeRatesTableReferences
                                            ._fromCurrencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }
                        if (toCurrencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toCurrencyCode,
                                    referencedTable:
                                        $$ExchangeRatesTableReferences
                                            ._toCurrencyCodeTable(db),
                                    referencedColumn:
                                        $$ExchangeRatesTableReferences
                                            ._toCurrencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExchangeRatesTable,
      ExchangeRateRow,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (ExchangeRateRow, $$ExchangeRatesTableReferences),
      ExchangeRateRow,
      PrefetchHooks Function({
        bool cycleId,
        bool fromCurrencyCode,
        bool toCurrencyCode,
      })
    >;
typedef $$WellsTableCreateCompanionBuilder =
    WellsCompanion Function({
      Value<int> id,
      required String name,
      required WellType wellType,
      Value<bool> isCarryover,
      required String currencyCode,
      Value<int?> expectedAmount,
      Value<int?> estimateMin,
      Value<int?> estimateMax,
      Value<String> wellIconId,
      Value<bool> isActive,
      Value<int> displayOrder,
      required int createdAt,
    });
typedef $$WellsTableUpdateCompanionBuilder =
    WellsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<WellType> wellType,
      Value<bool> isCarryover,
      Value<String> currencyCode,
      Value<int?> expectedAmount,
      Value<int?> estimateMin,
      Value<int?> estimateMax,
      Value<String> wellIconId,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<int> createdAt,
    });

final class $$WellsTableReferences
    extends BaseReferences<_$AppDatabase, $WellsTable, WellRow> {
  $$WellsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.wells.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IncomeEntriesTable, List<IncomeEntryRow>>
  _incomeEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incomeEntries,
    aliasName: $_aliasNameGenerator(db.wells.id, db.incomeEntries.wellId),
  );

  $$IncomeEntriesTableProcessedTableManager get incomeEntriesRefs {
    final manager = $$IncomeEntriesTableTableManager(
      $_db,
      $_db.incomeEntries,
    ).filter((f) => f.wellId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomeEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WellsTableFilterComposer extends Composer<_$AppDatabase, $WellsTable> {
  $$WellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WellType, WellType, String> get wellType =>
      $composableBuilder(
        column: $table.wellType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isCarryover => $composableBuilder(
    column: $table.isCarryover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMax => $composableBuilder(
    column: $table.estimateMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wellIconId => $composableBuilder(
    column: $table.wellIconId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> incomeEntriesRefs(
    Expression<bool> Function($$IncomeEntriesTableFilterComposer f) f,
  ) {
    final $$IncomeEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.wellId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableFilterComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WellsTableOrderingComposer
    extends Composer<_$AppDatabase, $WellsTable> {
  $$WellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wellType => $composableBuilder(
    column: $table.wellType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCarryover => $composableBuilder(
    column: $table.isCarryover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMax => $composableBuilder(
    column: $table.estimateMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wellIconId => $composableBuilder(
    column: $table.wellIconId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WellsTable> {
  $$WellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WellType, String> get wellType =>
      $composableBuilder(column: $table.wellType, builder: (column) => column);

  GeneratedColumn<bool> get isCarryover => $composableBuilder(
    column: $table.isCarryover,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMax => $composableBuilder(
    column: $table.estimateMax,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wellIconId => $composableBuilder(
    column: $table.wellIconId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> incomeEntriesRefs<T extends Object>(
    Expression<T> Function($$IncomeEntriesTableAnnotationComposer a) f,
  ) {
    final $$IncomeEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeEntries,
      getReferencedColumn: (t) => t.wellId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WellsTable,
          WellRow,
          $$WellsTableFilterComposer,
          $$WellsTableOrderingComposer,
          $$WellsTableAnnotationComposer,
          $$WellsTableCreateCompanionBuilder,
          $$WellsTableUpdateCompanionBuilder,
          (WellRow, $$WellsTableReferences),
          WellRow,
          PrefetchHooks Function({bool currencyCode, bool incomeEntriesRefs})
        > {
  $$WellsTableTableManager(_$AppDatabase db, $WellsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WellType> wellType = const Value.absent(),
                Value<bool> isCarryover = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int?> expectedAmount = const Value.absent(),
                Value<int?> estimateMin = const Value.absent(),
                Value<int?> estimateMax = const Value.absent(),
                Value<String> wellIconId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => WellsCompanion(
                id: id,
                name: name,
                wellType: wellType,
                isCarryover: isCarryover,
                currencyCode: currencyCode,
                expectedAmount: expectedAmount,
                estimateMin: estimateMin,
                estimateMax: estimateMax,
                wellIconId: wellIconId,
                isActive: isActive,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required WellType wellType,
                Value<bool> isCarryover = const Value.absent(),
                required String currencyCode,
                Value<int?> expectedAmount = const Value.absent(),
                Value<int?> estimateMin = const Value.absent(),
                Value<int?> estimateMax = const Value.absent(),
                Value<String> wellIconId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                required int createdAt,
              }) => WellsCompanion.insert(
                id: id,
                name: name,
                wellType: wellType,
                isCarryover: isCarryover,
                currencyCode: currencyCode,
                expectedAmount: expectedAmount,
                estimateMin: estimateMin,
                estimateMax: estimateMax,
                wellIconId: wellIconId,
                isActive: isActive,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WellsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({currencyCode = false, incomeEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (incomeEntriesRefs) db.incomeEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable: $$WellsTableReferences
                                        ._currencyCodeTable(db),
                                    referencedColumn: $$WellsTableReferences
                                        ._currencyCodeTable(db)
                                        .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (incomeEntriesRefs)
                        await $_getPrefetchedData<
                          WellRow,
                          $WellsTable,
                          IncomeEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$WellsTableReferences
                              ._incomeEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WellsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomeEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wellId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WellsTable,
      WellRow,
      $$WellsTableFilterComposer,
      $$WellsTableOrderingComposer,
      $$WellsTableAnnotationComposer,
      $$WellsTableCreateCompanionBuilder,
      $$WellsTableUpdateCompanionBuilder,
      (WellRow, $$WellsTableReferences),
      WellRow,
      PrefetchHooks Function({bool currencyCode, bool incomeEntriesRefs})
    >;
typedef $$IncomeEntriesTableCreateCompanionBuilder =
    IncomeEntriesCompanion Function({
      Value<int> id,
      required int wellId,
      required int cycleId,
      required int amount,
      required String currencyCode,
      required int baseAmount,
      required double exchangeRate,
      required int receivedAt,
      Value<String?> note,
      Value<bool> isSystemGenerated,
      required int createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
    });
typedef $$IncomeEntriesTableUpdateCompanionBuilder =
    IncomeEntriesCompanion Function({
      Value<int> id,
      Value<int> wellId,
      Value<int> cycleId,
      Value<int> amount,
      Value<String> currencyCode,
      Value<int> baseAmount,
      Value<double> exchangeRate,
      Value<int> receivedAt,
      Value<String?> note,
      Value<bool> isSystemGenerated,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
    });

final class $$IncomeEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $IncomeEntriesTable, IncomeEntryRow> {
  $$IncomeEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WellsTable _wellIdTable(_$AppDatabase db) => db.wells.createAlias(
    $_aliasNameGenerator(db.incomeEntries.wellId, db.wells.id),
  );

  $$WellsTableProcessedTableManager get wellId {
    final $_column = $_itemColumn<int>('well_id')!;

    final manager = $$WellsTableTableManager(
      $_db,
      $_db.wells,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wellIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.incomeEntries.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.incomeEntries.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IncomeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeEntriesTable> {
  $$IncomeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WellsTableFilterComposer get wellId {
    final $$WellsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wellId,
      referencedTable: $db.wells,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WellsTableFilterComposer(
            $db: $db,
            $table: $db.wells,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeEntriesTable> {
  $$IncomeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WellsTableOrderingComposer get wellId {
    final $$WellsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wellId,
      referencedTable: $db.wells,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WellsTableOrderingComposer(
            $db: $db,
            $table: $db.wells,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeEntriesTable> {
  $$IncomeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WellsTableAnnotationComposer get wellId {
    final $$WellsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wellId,
      referencedTable: $db.wells,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WellsTableAnnotationComposer(
            $db: $db,
            $table: $db.wells,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeEntriesTable,
          IncomeEntryRow,
          $$IncomeEntriesTableFilterComposer,
          $$IncomeEntriesTableOrderingComposer,
          $$IncomeEntriesTableAnnotationComposer,
          $$IncomeEntriesTableCreateCompanionBuilder,
          $$IncomeEntriesTableUpdateCompanionBuilder,
          (IncomeEntryRow, $$IncomeEntriesTableReferences),
          IncomeEntryRow,
          PrefetchHooks Function({bool wellId, bool cycleId, bool currencyCode})
        > {
  $$IncomeEntriesTableTableManager(_$AppDatabase db, $IncomeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wellId = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<int> receivedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isSystemGenerated = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => IncomeEntriesCompanion(
                id: id,
                wellId: wellId,
                cycleId: cycleId,
                amount: amount,
                currencyCode: currencyCode,
                baseAmount: baseAmount,
                exchangeRate: exchangeRate,
                receivedAt: receivedAt,
                note: note,
                isSystemGenerated: isSystemGenerated,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wellId,
                required int cycleId,
                required int amount,
                required String currencyCode,
                required int baseAmount,
                required double exchangeRate,
                required int receivedAt,
                Value<String?> note = const Value.absent(),
                Value<bool> isSystemGenerated = const Value.absent(),
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => IncomeEntriesCompanion.insert(
                id: id,
                wellId: wellId,
                cycleId: cycleId,
                amount: amount,
                currencyCode: currencyCode,
                baseAmount: baseAmount,
                exchangeRate: exchangeRate,
                receivedAt: receivedAt,
                note: note,
                isSystemGenerated: isSystemGenerated,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IncomeEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({wellId = false, cycleId = false, currencyCode = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (wellId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.wellId,
                                    referencedTable:
                                        $$IncomeEntriesTableReferences
                                            ._wellIdTable(db),
                                    referencedColumn:
                                        $$IncomeEntriesTableReferences
                                            ._wellIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$IncomeEntriesTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$IncomeEntriesTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable:
                                        $$IncomeEntriesTableReferences
                                            ._currencyCodeTable(db),
                                    referencedColumn:
                                        $$IncomeEntriesTableReferences
                                            ._currencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$IncomeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeEntriesTable,
      IncomeEntryRow,
      $$IncomeEntriesTableFilterComposer,
      $$IncomeEntriesTableOrderingComposer,
      $$IncomeEntriesTableAnnotationComposer,
      $$IncomeEntriesTableCreateCompanionBuilder,
      $$IncomeEntriesTableUpdateCompanionBuilder,
      (IncomeEntryRow, $$IncomeEntriesTableReferences),
      IncomeEntryRow,
      PrefetchHooks Function({bool wellId, bool cycleId, bool currencyCode})
    >;
typedef $$CropsCatalogTableCreateCompanionBuilder =
    CropsCatalogCompanion Function({
      required String cropId,
      required String name,
      required int baseCoinYield,
      Value<bool> isStarter,
      Value<bool> isConsumable,
      Value<int?> seedPackSize,
      Value<int?> priceCoins,
      Value<String?> description,
      Value<int> displayOrder,
      Value<int> rowid,
    });
typedef $$CropsCatalogTableUpdateCompanionBuilder =
    CropsCatalogCompanion Function({
      Value<String> cropId,
      Value<String> name,
      Value<int> baseCoinYield,
      Value<bool> isStarter,
      Value<bool> isConsumable,
      Value<int?> seedPackSize,
      Value<int?> priceCoins,
      Value<String?> description,
      Value<int> displayOrder,
      Value<int> rowid,
    });

final class $$CropsCatalogTableReferences
    extends BaseReferences<_$AppDatabase, $CropsCatalogTable, CropCatalogRow> {
  $$CropsCatalogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlotsTable, List<PlotRow>> _plotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.plots,
    aliasName: $_aliasNameGenerator(
      db.cropsCatalog.cropId,
      db.plots.cropTypeId,
    ),
  );

  $$PlotsTableProcessedTableManager get plotsRefs {
    final manager = $$PlotsTableTableManager($_db, $_db.plots).filter(
      (f) => f.cropTypeId.cropId.sqlEquals($_itemColumn<String>('crop_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_plotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CropsCatalogTableFilterComposer
    extends Composer<_$AppDatabase, $CropsCatalogTable> {
  $$CropsCatalogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseCoinYield => $composableBuilder(
    column: $table.baseCoinYield,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConsumable => $composableBuilder(
    column: $table.isConsumable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seedPackSize => $composableBuilder(
    column: $table.seedPackSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> plotsRefs(
    Expression<bool> Function($$PlotsTableFilterComposer f) f,
  ) {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.cropTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CropsCatalogTableOrderingComposer
    extends Composer<_$AppDatabase, $CropsCatalogTable> {
  $$CropsCatalogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cropId => $composableBuilder(
    column: $table.cropId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseCoinYield => $composableBuilder(
    column: $table.baseCoinYield,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConsumable => $composableBuilder(
    column: $table.isConsumable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seedPackSize => $composableBuilder(
    column: $table.seedPackSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CropsCatalogTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropsCatalogTable> {
  $$CropsCatalogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cropId =>
      $composableBuilder(column: $table.cropId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get baseCoinYield => $composableBuilder(
    column: $table.baseCoinYield,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarter =>
      $composableBuilder(column: $table.isStarter, builder: (column) => column);

  GeneratedColumn<bool> get isConsumable => $composableBuilder(
    column: $table.isConsumable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seedPackSize => $composableBuilder(
    column: $table.seedPackSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceCoins => $composableBuilder(
    column: $table.priceCoins,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  Expression<T> plotsRefs<T extends Object>(
    Expression<T> Function($$PlotsTableAnnotationComposer a) f,
  ) {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.cropTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CropsCatalogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CropsCatalogTable,
          CropCatalogRow,
          $$CropsCatalogTableFilterComposer,
          $$CropsCatalogTableOrderingComposer,
          $$CropsCatalogTableAnnotationComposer,
          $$CropsCatalogTableCreateCompanionBuilder,
          $$CropsCatalogTableUpdateCompanionBuilder,
          (CropCatalogRow, $$CropsCatalogTableReferences),
          CropCatalogRow,
          PrefetchHooks Function({bool plotsRefs})
        > {
  $$CropsCatalogTableTableManager(_$AppDatabase db, $CropsCatalogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropsCatalogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropsCatalogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CropsCatalogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cropId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> baseCoinYield = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isConsumable = const Value.absent(),
                Value<int?> seedPackSize = const Value.absent(),
                Value<int?> priceCoins = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CropsCatalogCompanion(
                cropId: cropId,
                name: name,
                baseCoinYield: baseCoinYield,
                isStarter: isStarter,
                isConsumable: isConsumable,
                seedPackSize: seedPackSize,
                priceCoins: priceCoins,
                description: description,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cropId,
                required String name,
                required int baseCoinYield,
                Value<bool> isStarter = const Value.absent(),
                Value<bool> isConsumable = const Value.absent(),
                Value<int?> seedPackSize = const Value.absent(),
                Value<int?> priceCoins = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CropsCatalogCompanion.insert(
                cropId: cropId,
                name: name,
                baseCoinYield: baseCoinYield,
                isStarter: isStarter,
                isConsumable: isConsumable,
                seedPackSize: seedPackSize,
                priceCoins: priceCoins,
                description: description,
                displayOrder: displayOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CropsCatalogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (plotsRefs) db.plots],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (plotsRefs)
                    await $_getPrefetchedData<
                      CropCatalogRow,
                      $CropsCatalogTable,
                      PlotRow
                    >(
                      currentTable: table,
                      referencedTable: $$CropsCatalogTableReferences
                          ._plotsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CropsCatalogTableReferences(
                            db,
                            table,
                            p0,
                          ).plotsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.cropTypeId == item.cropId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CropsCatalogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CropsCatalogTable,
      CropCatalogRow,
      $$CropsCatalogTableFilterComposer,
      $$CropsCatalogTableOrderingComposer,
      $$CropsCatalogTableAnnotationComposer,
      $$CropsCatalogTableCreateCompanionBuilder,
      $$CropsCatalogTableUpdateCompanionBuilder,
      (CropCatalogRow, $$CropsCatalogTableReferences),
      CropCatalogRow,
      PrefetchHooks Function({bool plotsRefs})
    >;
typedef $$PlotsTableCreateCompanionBuilder =
    PlotsCompanion Function({
      Value<int> id,
      required String name,
      Value<PlotKind> kind,
      Value<int?> budgetAmount,
      required String currencyCode,
      required String cropTypeId,
      Value<String?> plotColorId,
      Value<int?> dueDay,
      Value<bool> isUnplanned,
      Value<bool> isActive,
      Value<int> displayOrder,
      required int createdAt,
    });
typedef $$PlotsTableUpdateCompanionBuilder =
    PlotsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<PlotKind> kind,
      Value<int?> budgetAmount,
      Value<String> currencyCode,
      Value<String> cropTypeId,
      Value<String?> plotColorId,
      Value<int?> dueDay,
      Value<bool> isUnplanned,
      Value<bool> isActive,
      Value<int> displayOrder,
      Value<int> createdAt,
    });

final class $$PlotsTableReferences
    extends BaseReferences<_$AppDatabase, $PlotsTable, PlotRow> {
  $$PlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.plots.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CropsCatalogTable _cropTypeIdTable(_$AppDatabase db) =>
      db.cropsCatalog.createAlias(
        $_aliasNameGenerator(db.plots.cropTypeId, db.cropsCatalog.cropId),
      );

  $$CropsCatalogTableProcessedTableManager get cropTypeId {
    final $_column = $_itemColumn<String>('crop_type_id')!;

    final manager = $$CropsCatalogTableTableManager(
      $_db,
      $_db.cropsCatalog,
    ).filter((f) => f.cropId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BonusAllocationsTable, List<BonusAllocationRow>>
  _bonusAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bonusAllocations,
    aliasName: $_aliasNameGenerator(
      db.plots.id,
      db.bonusAllocations.targetPlotId,
    ),
  );

  $$BonusAllocationsTableProcessedTableManager get bonusAllocationsRefs {
    final manager = $$BonusAllocationsTableTableManager(
      $_db,
      $_db.bonusAllocations,
    ).filter((f) => f.targetPlotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bonusAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.plots.id, db.transactions.plotId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.plotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlotCycleResultsTable, List<PlotCycleResultRow>>
  _plotCycleResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plotCycleResults,
    aliasName: $_aliasNameGenerator(db.plots.id, db.plotCycleResults.plotId),
  );

  $$PlotCycleResultsTableProcessedTableManager get plotCycleResultsRefs {
    final manager = $$PlotCycleResultsTableTableManager(
      $_db,
      $_db.plotCycleResults,
    ).filter((f) => f.plotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plotCycleResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlotFertilizerApplicationsTable,
    List<PlotFertilizerApplicationRow>
  >
  _plotFertilizerApplicationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.plotFertilizerApplications,
        aliasName: $_aliasNameGenerator(
          db.plots.id,
          db.plotFertilizerApplications.plotId,
        ),
      );

  $$PlotFertilizerApplicationsTableProcessedTableManager
  get plotFertilizerApplicationsRefs {
    final manager = $$PlotFertilizerApplicationsTableTableManager(
      $_db,
      $_db.plotFertilizerApplications,
    ).filter((f) => f.plotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _plotFertilizerApplicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlotsTableFilterComposer extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlotKind, PlotKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get budgetAmount => $composableBuilder(
    column: $table.budgetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plotColorId => $composableBuilder(
    column: $table.plotColorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropsCatalogTableFilterComposer get cropTypeId {
    final $$CropsCatalogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropTypeId,
      referencedTable: $db.cropsCatalog,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropsCatalogTableFilterComposer(
            $db: $db,
            $table: $db.cropsCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bonusAllocationsRefs(
    Expression<bool> Function($$BonusAllocationsTableFilterComposer f) f,
  ) {
    final $$BonusAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bonusAllocations,
      getReferencedColumn: (t) => t.targetPlotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BonusAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.bonusAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.plotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotCycleResultsRefs(
    Expression<bool> Function($$PlotCycleResultsTableFilterComposer f) f,
  ) {
    final $$PlotCycleResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.plotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableFilterComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plotFertilizerApplicationsRefs(
    Expression<bool> Function($$PlotFertilizerApplicationsTableFilterComposer f)
    f,
  ) {
    final $$PlotFertilizerApplicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.plotFertilizerApplications,
          getReferencedColumn: (t) => t.plotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlotFertilizerApplicationsTableFilterComposer(
                $db: $db,
                $table: $db.plotFertilizerApplications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetAmount => $composableBuilder(
    column: $table.budgetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plotColorId => $composableBuilder(
    column: $table.plotColorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropsCatalogTableOrderingComposer get cropTypeId {
    final $$CropsCatalogTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropTypeId,
      referencedTable: $db.cropsCatalog,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropsCatalogTableOrderingComposer(
            $db: $db,
            $table: $db.cropsCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlotKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get budgetAmount => $composableBuilder(
    column: $table.budgetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plotColorId => $composableBuilder(
    column: $table.plotColorId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropsCatalogTableAnnotationComposer get cropTypeId {
    final $$CropsCatalogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropTypeId,
      referencedTable: $db.cropsCatalog,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropsCatalogTableAnnotationComposer(
            $db: $db,
            $table: $db.cropsCatalog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bonusAllocationsRefs<T extends Object>(
    Expression<T> Function($$BonusAllocationsTableAnnotationComposer a) f,
  ) {
    final $$BonusAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bonusAllocations,
      getReferencedColumn: (t) => t.targetPlotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BonusAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.bonusAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.plotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotCycleResultsRefs<T extends Object>(
    Expression<T> Function($$PlotCycleResultsTableAnnotationComposer a) f,
  ) {
    final $$PlotCycleResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plotCycleResults,
      getReferencedColumn: (t) => t.plotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotCycleResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.plotCycleResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plotFertilizerApplicationsRefs<T extends Object>(
    Expression<T> Function(
      $$PlotFertilizerApplicationsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$PlotFertilizerApplicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.plotFertilizerApplications,
          getReferencedColumn: (t) => t.plotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlotFertilizerApplicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.plotFertilizerApplications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlotsTable,
          PlotRow,
          $$PlotsTableFilterComposer,
          $$PlotsTableOrderingComposer,
          $$PlotsTableAnnotationComposer,
          $$PlotsTableCreateCompanionBuilder,
          $$PlotsTableUpdateCompanionBuilder,
          (PlotRow, $$PlotsTableReferences),
          PlotRow,
          PrefetchHooks Function({
            bool currencyCode,
            bool cropTypeId,
            bool bonusAllocationsRefs,
            bool transactionsRefs,
            bool plotCycleResultsRefs,
            bool plotFertilizerApplicationsRefs,
          })
        > {
  $$PlotsTableTableManager(_$AppDatabase db, $PlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PlotKind> kind = const Value.absent(),
                Value<int?> budgetAmount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> cropTypeId = const Value.absent(),
                Value<String?> plotColorId = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> isUnplanned = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => PlotsCompanion(
                id: id,
                name: name,
                kind: kind,
                budgetAmount: budgetAmount,
                currencyCode: currencyCode,
                cropTypeId: cropTypeId,
                plotColorId: plotColorId,
                dueDay: dueDay,
                isUnplanned: isUnplanned,
                isActive: isActive,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<PlotKind> kind = const Value.absent(),
                Value<int?> budgetAmount = const Value.absent(),
                required String currencyCode,
                required String cropTypeId,
                Value<String?> plotColorId = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<bool> isUnplanned = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                required int createdAt,
              }) => PlotsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                budgetAmount: budgetAmount,
                currencyCode: currencyCode,
                cropTypeId: cropTypeId,
                plotColorId: plotColorId,
                dueDay: dueDay,
                isUnplanned: isUnplanned,
                isActive: isActive,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PlotsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                currencyCode = false,
                cropTypeId = false,
                bonusAllocationsRefs = false,
                transactionsRefs = false,
                plotCycleResultsRefs = false,
                plotFertilizerApplicationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bonusAllocationsRefs) db.bonusAllocations,
                    if (transactionsRefs) db.transactions,
                    if (plotCycleResultsRefs) db.plotCycleResults,
                    if (plotFertilizerApplicationsRefs)
                      db.plotFertilizerApplications,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable: $$PlotsTableReferences
                                        ._currencyCodeTable(db),
                                    referencedColumn: $$PlotsTableReferences
                                        ._currencyCodeTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (cropTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cropTypeId,
                                    referencedTable: $$PlotsTableReferences
                                        ._cropTypeIdTable(db),
                                    referencedColumn: $$PlotsTableReferences
                                        ._cropTypeIdTable(db)
                                        .cropId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bonusAllocationsRefs)
                        await $_getPrefetchedData<
                          PlotRow,
                          $PlotsTable,
                          BonusAllocationRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlotsTableReferences
                              ._bonusAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).bonusAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.targetPlotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          PlotRow,
                          $PlotsTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlotsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plotCycleResultsRefs)
                        await $_getPrefetchedData<
                          PlotRow,
                          $PlotsTable,
                          PlotCycleResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlotsTableReferences
                              ._plotCycleResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).plotCycleResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plotFertilizerApplicationsRefs)
                        await $_getPrefetchedData<
                          PlotRow,
                          $PlotsTable,
                          PlotFertilizerApplicationRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlotsTableReferences
                              ._plotFertilizerApplicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).plotFertilizerApplicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plotId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlotsTable,
      PlotRow,
      $$PlotsTableFilterComposer,
      $$PlotsTableOrderingComposer,
      $$PlotsTableAnnotationComposer,
      $$PlotsTableCreateCompanionBuilder,
      $$PlotsTableUpdateCompanionBuilder,
      (PlotRow, $$PlotsTableReferences),
      PlotRow,
      PrefetchHooks Function({
        bool currencyCode,
        bool cropTypeId,
        bool bonusAllocationsRefs,
        bool transactionsRefs,
        bool plotCycleResultsRefs,
        bool plotFertilizerApplicationsRefs,
      })
    >;
typedef $$BonusAllocationsTableCreateCompanionBuilder =
    BonusAllocationsCompanion Function({
      Value<int> id,
      required int cycleId,
      required int targetPlotId,
      required int amount,
      required int allocatedAt,
    });
typedef $$BonusAllocationsTableUpdateCompanionBuilder =
    BonusAllocationsCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<int> targetPlotId,
      Value<int> amount,
      Value<int> allocatedAt,
    });

final class $$BonusAllocationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BonusAllocationsTable,
          BonusAllocationRow
        > {
  $$BonusAllocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.bonusAllocations.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlotsTable _targetPlotIdTable(_$AppDatabase db) =>
      db.plots.createAlias(
        $_aliasNameGenerator(db.bonusAllocations.targetPlotId, db.plots.id),
      );

  $$PlotsTableProcessedTableManager get targetPlotId {
    final $_column = $_itemColumn<int>('target_plot_id')!;

    final manager = $$PlotsTableTableManager(
      $_db,
      $_db.plots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetPlotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BonusAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $BonusAllocationsTable> {
  $$BonusAllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocatedAt => $composableBuilder(
    column: $table.allocatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableFilterComposer get targetPlotId {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetPlotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BonusAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $BonusAllocationsTable> {
  $$BonusAllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocatedAt => $composableBuilder(
    column: $table.allocatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableOrderingComposer get targetPlotId {
    final $$PlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetPlotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableOrderingComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BonusAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BonusAllocationsTable> {
  $$BonusAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get allocatedAt => $composableBuilder(
    column: $table.allocatedAt,
    builder: (column) => column,
  );

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableAnnotationComposer get targetPlotId {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetPlotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BonusAllocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BonusAllocationsTable,
          BonusAllocationRow,
          $$BonusAllocationsTableFilterComposer,
          $$BonusAllocationsTableOrderingComposer,
          $$BonusAllocationsTableAnnotationComposer,
          $$BonusAllocationsTableCreateCompanionBuilder,
          $$BonusAllocationsTableUpdateCompanionBuilder,
          (BonusAllocationRow, $$BonusAllocationsTableReferences),
          BonusAllocationRow,
          PrefetchHooks Function({bool cycleId, bool targetPlotId})
        > {
  $$BonusAllocationsTableTableManager(
    _$AppDatabase db,
    $BonusAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BonusAllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BonusAllocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BonusAllocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> targetPlotId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> allocatedAt = const Value.absent(),
              }) => BonusAllocationsCompanion(
                id: id,
                cycleId: cycleId,
                targetPlotId: targetPlotId,
                amount: amount,
                allocatedAt: allocatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required int targetPlotId,
                required int amount,
                required int allocatedAt,
              }) => BonusAllocationsCompanion.insert(
                id: id,
                cycleId: cycleId,
                targetPlotId: targetPlotId,
                amount: amount,
                allocatedAt: allocatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BonusAllocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false, targetPlotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable:
                                    $$BonusAllocationsTableReferences
                                        ._cycleIdTable(db),
                                referencedColumn:
                                    $$BonusAllocationsTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (targetPlotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.targetPlotId,
                                referencedTable:
                                    $$BonusAllocationsTableReferences
                                        ._targetPlotIdTable(db),
                                referencedColumn:
                                    $$BonusAllocationsTableReferences
                                        ._targetPlotIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BonusAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BonusAllocationsTable,
      BonusAllocationRow,
      $$BonusAllocationsTableFilterComposer,
      $$BonusAllocationsTableOrderingComposer,
      $$BonusAllocationsTableAnnotationComposer,
      $$BonusAllocationsTableCreateCompanionBuilder,
      $$BonusAllocationsTableUpdateCompanionBuilder,
      (BonusAllocationRow, $$BonusAllocationsTableReferences),
      BonusAllocationRow,
      PrefetchHooks Function({bool cycleId, bool targetPlotId})
    >;
typedef $$SavingsBarnTableCreateCompanionBuilder =
    SavingsBarnCompanion Function({
      Value<int> id,
      Value<int> totalSaved,
      Value<String> barnSkinId,
      required int lastUpdatedAt,
    });
typedef $$SavingsBarnTableUpdateCompanionBuilder =
    SavingsBarnCompanion Function({
      Value<int> id,
      Value<int> totalSaved,
      Value<String> barnSkinId,
      Value<int> lastUpdatedAt,
    });

class $$SavingsBarnTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsBarnTable> {
  $$SavingsBarnTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSaved => $composableBuilder(
    column: $table.totalSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barnSkinId => $composableBuilder(
    column: $table.barnSkinId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsBarnTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsBarnTable> {
  $$SavingsBarnTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSaved => $composableBuilder(
    column: $table.totalSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barnSkinId => $composableBuilder(
    column: $table.barnSkinId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsBarnTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsBarnTable> {
  $$SavingsBarnTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalSaved => $composableBuilder(
    column: $table.totalSaved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barnSkinId => $composableBuilder(
    column: $table.barnSkinId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$SavingsBarnTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsBarnTable,
          SavingsBarnRow,
          $$SavingsBarnTableFilterComposer,
          $$SavingsBarnTableOrderingComposer,
          $$SavingsBarnTableAnnotationComposer,
          $$SavingsBarnTableCreateCompanionBuilder,
          $$SavingsBarnTableUpdateCompanionBuilder,
          (
            SavingsBarnRow,
            BaseReferences<_$AppDatabase, $SavingsBarnTable, SavingsBarnRow>,
          ),
          SavingsBarnRow,
          PrefetchHooks Function()
        > {
  $$SavingsBarnTableTableManager(_$AppDatabase db, $SavingsBarnTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsBarnTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsBarnTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsBarnTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> totalSaved = const Value.absent(),
                Value<String> barnSkinId = const Value.absent(),
                Value<int> lastUpdatedAt = const Value.absent(),
              }) => SavingsBarnCompanion(
                id: id,
                totalSaved: totalSaved,
                barnSkinId: barnSkinId,
                lastUpdatedAt: lastUpdatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> totalSaved = const Value.absent(),
                Value<String> barnSkinId = const Value.absent(),
                required int lastUpdatedAt,
              }) => SavingsBarnCompanion.insert(
                id: id,
                totalSaved: totalSaved,
                barnSkinId: barnSkinId,
                lastUpdatedAt: lastUpdatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsBarnTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsBarnTable,
      SavingsBarnRow,
      $$SavingsBarnTableFilterComposer,
      $$SavingsBarnTableOrderingComposer,
      $$SavingsBarnTableAnnotationComposer,
      $$SavingsBarnTableCreateCompanionBuilder,
      $$SavingsBarnTableUpdateCompanionBuilder,
      (
        SavingsBarnRow,
        BaseReferences<_$AppDatabase, $SavingsBarnTable, SavingsBarnRow>,
      ),
      SavingsBarnRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int plotId,
      required int cycleId,
      required int amount,
      required String currencyCode,
      required int baseAmount,
      required int plotAmount,
      required double exchangeRate,
      required int spentAt,
      Value<String?> note,
      Value<bool> isEmergency,
      required int createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> plotId,
      Value<int> cycleId,
      Value<int> amount,
      Value<String> currencyCode,
      Value<int> baseAmount,
      Value<int> plotAmount,
      Value<double> exchangeRate,
      Value<int> spentAt,
      Value<String?> note,
      Value<bool> isEmergency,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlotsTable _plotIdTable(_$AppDatabase db) => db.plots.createAlias(
    $_aliasNameGenerator(db.transactions.plotId, db.plots.id),
  );

  $$PlotsTableProcessedTableManager get plotId {
    final $_column = $_itemColumn<int>('plot_id')!;

    final manager = $$PlotsTableTableManager(
      $_db,
      $_db.plots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.transactions.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.transactions.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plotAmount => $composableBuilder(
    column: $table.plotAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEmergency => $composableBuilder(
    column: $table.isEmergency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlotsTableFilterComposer get plotId {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plotAmount => $composableBuilder(
    column: $table.plotAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEmergency => $composableBuilder(
    column: $table.isEmergency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlotsTableOrderingComposer get plotId {
    final $$PlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableOrderingComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plotAmount => $composableBuilder(
    column: $table.plotAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isEmergency => $composableBuilder(
    column: $table.isEmergency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$PlotsTableAnnotationComposer get plotId {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool plotId, bool cycleId, bool currencyCode})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> plotId = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> plotAmount = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<int> spentAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isEmergency = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                plotId: plotId,
                cycleId: cycleId,
                amount: amount,
                currencyCode: currencyCode,
                baseAmount: baseAmount,
                plotAmount: plotAmount,
                exchangeRate: exchangeRate,
                spentAt: spentAt,
                note: note,
                isEmergency: isEmergency,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int plotId,
                required int cycleId,
                required int amount,
                required String currencyCode,
                required int baseAmount,
                required int plotAmount,
                required double exchangeRate,
                required int spentAt,
                Value<String?> note = const Value.absent(),
                Value<bool> isEmergency = const Value.absent(),
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                plotId: plotId,
                cycleId: cycleId,
                amount: amount,
                currencyCode: currencyCode,
                baseAmount: baseAmount,
                plotAmount: plotAmount,
                exchangeRate: exchangeRate,
                spentAt: spentAt,
                note: note,
                isEmergency: isEmergency,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({plotId = false, cycleId = false, currencyCode = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (plotId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plotId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._plotIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._plotIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._currencyCodeTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._currencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool plotId, bool cycleId, bool currencyCode})
    >;
typedef $$PlotCycleResultsTableCreateCompanionBuilder =
    PlotCycleResultsCompanion Function({
      Value<int> id,
      required int cycleId,
      required int plotId,
      required String plotNameSnapshot,
      Value<PlotKind> kindSnapshot,
      required String cropTypeIdSnapshot,
      Value<String?> plotColorIdSnapshot,
      Value<bool> isUnplanned,
      Value<int?> budgetAmountSnapshot,
      required String currencyCodeSnapshot,
      required int totalSpent,
      Value<double?> incomeShareAtClose,
      required PlotFinalState finalState,
      required int completedAt,
    });
typedef $$PlotCycleResultsTableUpdateCompanionBuilder =
    PlotCycleResultsCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<int> plotId,
      Value<String> plotNameSnapshot,
      Value<PlotKind> kindSnapshot,
      Value<String> cropTypeIdSnapshot,
      Value<String?> plotColorIdSnapshot,
      Value<bool> isUnplanned,
      Value<int?> budgetAmountSnapshot,
      Value<String> currencyCodeSnapshot,
      Value<int> totalSpent,
      Value<double?> incomeShareAtClose,
      Value<PlotFinalState> finalState,
      Value<int> completedAt,
    });

final class $$PlotCycleResultsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlotCycleResultsTable,
          PlotCycleResultRow
        > {
  $$PlotCycleResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.plotCycleResults.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlotsTable _plotIdTable(_$AppDatabase db) => db.plots.createAlias(
    $_aliasNameGenerator(db.plotCycleResults.plotId, db.plots.id),
  );

  $$PlotsTableProcessedTableManager get plotId {
    final $_column = $_itemColumn<int>('plot_id')!;

    final manager = $$PlotsTableTableManager(
      $_db,
      $_db.plots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _currencyCodeSnapshotTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.plotCycleResults.currencyCodeSnapshot,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get currencyCodeSnapshot {
    final $_column = $_itemColumn<String>('currency_code_snapshot')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _currencyCodeSnapshotTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlotCycleResultsTableFilterComposer
    extends Composer<_$AppDatabase, $PlotCycleResultsTable> {
  $$PlotCycleResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plotNameSnapshot => $composableBuilder(
    column: $table.plotNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlotKind, PlotKind, String> get kindSnapshot =>
      $composableBuilder(
        column: $table.kindSnapshot,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get cropTypeIdSnapshot => $composableBuilder(
    column: $table.cropTypeIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plotColorIdSnapshot => $composableBuilder(
    column: $table.plotColorIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetAmountSnapshot => $composableBuilder(
    column: $table.budgetAmountSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get incomeShareAtClose => $composableBuilder(
    column: $table.incomeShareAtClose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlotFinalState, PlotFinalState, String>
  get finalState => $composableBuilder(
    column: $table.finalState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableFilterComposer get plotId {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get currencyCodeSnapshot {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCodeSnapshot,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotCycleResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlotCycleResultsTable> {
  $$PlotCycleResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plotNameSnapshot => $composableBuilder(
    column: $table.plotNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kindSnapshot => $composableBuilder(
    column: $table.kindSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropTypeIdSnapshot => $composableBuilder(
    column: $table.cropTypeIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plotColorIdSnapshot => $composableBuilder(
    column: $table.plotColorIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetAmountSnapshot => $composableBuilder(
    column: $table.budgetAmountSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get incomeShareAtClose => $composableBuilder(
    column: $table.incomeShareAtClose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalState => $composableBuilder(
    column: $table.finalState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableOrderingComposer get plotId {
    final $$PlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableOrderingComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get currencyCodeSnapshot {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCodeSnapshot,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotCycleResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlotCycleResultsTable> {
  $$PlotCycleResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plotNameSnapshot => $composableBuilder(
    column: $table.plotNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlotKind, String> get kindSnapshot =>
      $composableBuilder(
        column: $table.kindSnapshot,
        builder: (column) => column,
      );

  GeneratedColumn<String> get cropTypeIdSnapshot => $composableBuilder(
    column: $table.cropTypeIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plotColorIdSnapshot => $composableBuilder(
    column: $table.plotColorIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnplanned => $composableBuilder(
    column: $table.isUnplanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get budgetAmountSnapshot => $composableBuilder(
    column: $table.budgetAmountSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get incomeShareAtClose => $composableBuilder(
    column: $table.incomeShareAtClose,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlotFinalState, String> get finalState =>
      $composableBuilder(
        column: $table.finalState,
        builder: (column) => column,
      );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableAnnotationComposer get plotId {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get currencyCodeSnapshot {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCodeSnapshot,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotCycleResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlotCycleResultsTable,
          PlotCycleResultRow,
          $$PlotCycleResultsTableFilterComposer,
          $$PlotCycleResultsTableOrderingComposer,
          $$PlotCycleResultsTableAnnotationComposer,
          $$PlotCycleResultsTableCreateCompanionBuilder,
          $$PlotCycleResultsTableUpdateCompanionBuilder,
          (PlotCycleResultRow, $$PlotCycleResultsTableReferences),
          PlotCycleResultRow,
          PrefetchHooks Function({
            bool cycleId,
            bool plotId,
            bool currencyCodeSnapshot,
          })
        > {
  $$PlotCycleResultsTableTableManager(
    _$AppDatabase db,
    $PlotCycleResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlotCycleResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlotCycleResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlotCycleResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> plotId = const Value.absent(),
                Value<String> plotNameSnapshot = const Value.absent(),
                Value<PlotKind> kindSnapshot = const Value.absent(),
                Value<String> cropTypeIdSnapshot = const Value.absent(),
                Value<String?> plotColorIdSnapshot = const Value.absent(),
                Value<bool> isUnplanned = const Value.absent(),
                Value<int?> budgetAmountSnapshot = const Value.absent(),
                Value<String> currencyCodeSnapshot = const Value.absent(),
                Value<int> totalSpent = const Value.absent(),
                Value<double?> incomeShareAtClose = const Value.absent(),
                Value<PlotFinalState> finalState = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
              }) => PlotCycleResultsCompanion(
                id: id,
                cycleId: cycleId,
                plotId: plotId,
                plotNameSnapshot: plotNameSnapshot,
                kindSnapshot: kindSnapshot,
                cropTypeIdSnapshot: cropTypeIdSnapshot,
                plotColorIdSnapshot: plotColorIdSnapshot,
                isUnplanned: isUnplanned,
                budgetAmountSnapshot: budgetAmountSnapshot,
                currencyCodeSnapshot: currencyCodeSnapshot,
                totalSpent: totalSpent,
                incomeShareAtClose: incomeShareAtClose,
                finalState: finalState,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required int plotId,
                required String plotNameSnapshot,
                Value<PlotKind> kindSnapshot = const Value.absent(),
                required String cropTypeIdSnapshot,
                Value<String?> plotColorIdSnapshot = const Value.absent(),
                Value<bool> isUnplanned = const Value.absent(),
                Value<int?> budgetAmountSnapshot = const Value.absent(),
                required String currencyCodeSnapshot,
                required int totalSpent,
                Value<double?> incomeShareAtClose = const Value.absent(),
                required PlotFinalState finalState,
                required int completedAt,
              }) => PlotCycleResultsCompanion.insert(
                id: id,
                cycleId: cycleId,
                plotId: plotId,
                plotNameSnapshot: plotNameSnapshot,
                kindSnapshot: kindSnapshot,
                cropTypeIdSnapshot: cropTypeIdSnapshot,
                plotColorIdSnapshot: plotColorIdSnapshot,
                isUnplanned: isUnplanned,
                budgetAmountSnapshot: budgetAmountSnapshot,
                currencyCodeSnapshot: currencyCodeSnapshot,
                totalSpent: totalSpent,
                incomeShareAtClose: incomeShareAtClose,
                finalState: finalState,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlotCycleResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cycleId = false,
                plotId = false,
                currencyCodeSnapshot = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$PlotCycleResultsTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$PlotCycleResultsTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (plotId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plotId,
                                    referencedTable:
                                        $$PlotCycleResultsTableReferences
                                            ._plotIdTable(db),
                                    referencedColumn:
                                        $$PlotCycleResultsTableReferences
                                            ._plotIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (currencyCodeSnapshot) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCodeSnapshot,
                                    referencedTable:
                                        $$PlotCycleResultsTableReferences
                                            ._currencyCodeSnapshotTable(db),
                                    referencedColumn:
                                        $$PlotCycleResultsTableReferences
                                            ._currencyCodeSnapshotTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PlotCycleResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlotCycleResultsTable,
      PlotCycleResultRow,
      $$PlotCycleResultsTableFilterComposer,
      $$PlotCycleResultsTableOrderingComposer,
      $$PlotCycleResultsTableAnnotationComposer,
      $$PlotCycleResultsTableCreateCompanionBuilder,
      $$PlotCycleResultsTableUpdateCompanionBuilder,
      (PlotCycleResultRow, $$PlotCycleResultsTableReferences),
      PlotCycleResultRow,
      PrefetchHooks Function({
        bool cycleId,
        bool plotId,
        bool currencyCodeSnapshot,
      })
    >;
typedef $$PlotFertilizerApplicationsTableCreateCompanionBuilder =
    PlotFertilizerApplicationsCompanion Function({
      Value<int> id,
      required int cycleId,
      required int plotId,
      required String fertilizerItemId,
      required int appliedAt,
    });
typedef $$PlotFertilizerApplicationsTableUpdateCompanionBuilder =
    PlotFertilizerApplicationsCompanion Function({
      Value<int> id,
      Value<int> cycleId,
      Value<int> plotId,
      Value<String> fertilizerItemId,
      Value<int> appliedAt,
    });

final class $$PlotFertilizerApplicationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlotFertilizerApplicationsTable,
          PlotFertilizerApplicationRow
        > {
  $$PlotFertilizerApplicationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.plotFertilizerApplications.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlotsTable _plotIdTable(_$AppDatabase db) => db.plots.createAlias(
    $_aliasNameGenerator(db.plotFertilizerApplications.plotId, db.plots.id),
  );

  $$PlotsTableProcessedTableManager get plotId {
    final $_column = $_itemColumn<int>('plot_id')!;

    final manager = $$PlotsTableTableManager(
      $_db,
      $_db.plots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlotFertilizerApplicationsTableFilterComposer
    extends Composer<_$AppDatabase, $PlotFertilizerApplicationsTable> {
  $$PlotFertilizerApplicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fertilizerItemId => $composableBuilder(
    column: $table.fertilizerItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableFilterComposer get plotId {
    final $$PlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableFilterComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotFertilizerApplicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlotFertilizerApplicationsTable> {
  $$PlotFertilizerApplicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fertilizerItemId => $composableBuilder(
    column: $table.fertilizerItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableOrderingComposer get plotId {
    final $$PlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableOrderingComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotFertilizerApplicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlotFertilizerApplicationsTable> {
  $$PlotFertilizerApplicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fertilizerItemId => $composableBuilder(
    column: $table.fertilizerItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlotsTableAnnotationComposer get plotId {
    final $$PlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plotId,
      referencedTable: $db.plots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.plots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlotFertilizerApplicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlotFertilizerApplicationsTable,
          PlotFertilizerApplicationRow,
          $$PlotFertilizerApplicationsTableFilterComposer,
          $$PlotFertilizerApplicationsTableOrderingComposer,
          $$PlotFertilizerApplicationsTableAnnotationComposer,
          $$PlotFertilizerApplicationsTableCreateCompanionBuilder,
          $$PlotFertilizerApplicationsTableUpdateCompanionBuilder,
          (
            PlotFertilizerApplicationRow,
            $$PlotFertilizerApplicationsTableReferences,
          ),
          PlotFertilizerApplicationRow,
          PrefetchHooks Function({bool cycleId, bool plotId})
        > {
  $$PlotFertilizerApplicationsTableTableManager(
    _$AppDatabase db,
    $PlotFertilizerApplicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlotFertilizerApplicationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PlotFertilizerApplicationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlotFertilizerApplicationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<int> plotId = const Value.absent(),
                Value<String> fertilizerItemId = const Value.absent(),
                Value<int> appliedAt = const Value.absent(),
              }) => PlotFertilizerApplicationsCompanion(
                id: id,
                cycleId: cycleId,
                plotId: plotId,
                fertilizerItemId: fertilizerItemId,
                appliedAt: appliedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cycleId,
                required int plotId,
                required String fertilizerItemId,
                required int appliedAt,
              }) => PlotFertilizerApplicationsCompanion.insert(
                id: id,
                cycleId: cycleId,
                plotId: plotId,
                fertilizerItemId: fertilizerItemId,
                appliedAt: appliedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlotFertilizerApplicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false, plotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable:
                                    $$PlotFertilizerApplicationsTableReferences
                                        ._cycleIdTable(db),
                                referencedColumn:
                                    $$PlotFertilizerApplicationsTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (plotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plotId,
                                referencedTable:
                                    $$PlotFertilizerApplicationsTableReferences
                                        ._plotIdTable(db),
                                referencedColumn:
                                    $$PlotFertilizerApplicationsTableReferences
                                        ._plotIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlotFertilizerApplicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlotFertilizerApplicationsTable,
      PlotFertilizerApplicationRow,
      $$PlotFertilizerApplicationsTableFilterComposer,
      $$PlotFertilizerApplicationsTableOrderingComposer,
      $$PlotFertilizerApplicationsTableAnnotationComposer,
      $$PlotFertilizerApplicationsTableCreateCompanionBuilder,
      $$PlotFertilizerApplicationsTableUpdateCompanionBuilder,
      (
        PlotFertilizerApplicationRow,
        $$PlotFertilizerApplicationsTableReferences,
      ),
      PlotFertilizerApplicationRow,
      PrefetchHooks Function({bool cycleId, bool plotId})
    >;
typedef $$CoinLedgerTableCreateCompanionBuilder =
    CoinLedgerCompanion Function({
      Value<int> id,
      Value<int?> cycleId,
      required int amount,
      required CoinReason reason,
      Value<int?> relatedId,
      Value<String?> relatedType,
      Value<String?> description,
      required int occurredAt,
    });
typedef $$CoinLedgerTableUpdateCompanionBuilder =
    CoinLedgerCompanion Function({
      Value<int> id,
      Value<int?> cycleId,
      Value<int> amount,
      Value<CoinReason> reason,
      Value<int?> relatedId,
      Value<String?> relatedType,
      Value<String?> description,
      Value<int> occurredAt,
    });

final class $$CoinLedgerTableReferences
    extends BaseReferences<_$AppDatabase, $CoinLedgerTable, CoinLedgerRow> {
  $$CoinLedgerTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.coinLedger.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager? get cycleId {
    final $_column = $_itemColumn<int>('cycle_id');
    if ($_column == null) return null;
    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoinLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $CoinLedgerTable> {
  $$CoinLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CoinReason, CoinReason, String> get reason =>
      $composableBuilder(
        column: $table.reason,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedType => $composableBuilder(
    column: $table.relatedType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoinLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $CoinLedgerTable> {
  $$CoinLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedType => $composableBuilder(
    column: $table.relatedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoinLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoinLedgerTable> {
  $$CoinLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CoinReason, String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get relatedId =>
      $composableBuilder(column: $table.relatedId, builder: (column) => column);

  GeneratedColumn<String> get relatedType => $composableBuilder(
    column: $table.relatedType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoinLedgerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoinLedgerTable,
          CoinLedgerRow,
          $$CoinLedgerTableFilterComposer,
          $$CoinLedgerTableOrderingComposer,
          $$CoinLedgerTableAnnotationComposer,
          $$CoinLedgerTableCreateCompanionBuilder,
          $$CoinLedgerTableUpdateCompanionBuilder,
          (CoinLedgerRow, $$CoinLedgerTableReferences),
          CoinLedgerRow,
          PrefetchHooks Function({bool cycleId})
        > {
  $$CoinLedgerTableTableManager(_$AppDatabase db, $CoinLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoinLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoinLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoinLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> cycleId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<CoinReason> reason = const Value.absent(),
                Value<int?> relatedId = const Value.absent(),
                Value<String?> relatedType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
              }) => CoinLedgerCompanion(
                id: id,
                cycleId: cycleId,
                amount: amount,
                reason: reason,
                relatedId: relatedId,
                relatedType: relatedType,
                description: description,
                occurredAt: occurredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> cycleId = const Value.absent(),
                required int amount,
                required CoinReason reason,
                Value<int?> relatedId = const Value.absent(),
                Value<String?> relatedType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int occurredAt,
              }) => CoinLedgerCompanion.insert(
                id: id,
                cycleId: cycleId,
                amount: amount,
                reason: reason,
                relatedId: relatedId,
                relatedType: relatedType,
                description: description,
                occurredAt: occurredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoinLedgerTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable: $$CoinLedgerTableReferences
                                    ._cycleIdTable(db),
                                referencedColumn: $$CoinLedgerTableReferences
                                    ._cycleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CoinLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoinLedgerTable,
      CoinLedgerRow,
      $$CoinLedgerTableFilterComposer,
      $$CoinLedgerTableOrderingComposer,
      $$CoinLedgerTableAnnotationComposer,
      $$CoinLedgerTableCreateCompanionBuilder,
      $$CoinLedgerTableUpdateCompanionBuilder,
      (CoinLedgerRow, $$CoinLedgerTableReferences),
      CoinLedgerRow,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$BadgesEarnedTableCreateCompanionBuilder =
    BadgesEarnedCompanion Function({
      Value<int> id,
      required String badgeId,
      required int earnedAt,
      Value<int?> cycleId,
    });
typedef $$BadgesEarnedTableUpdateCompanionBuilder =
    BadgesEarnedCompanion Function({
      Value<int> id,
      Value<String> badgeId,
      Value<int> earnedAt,
      Value<int?> cycleId,
    });

final class $$BadgesEarnedTableReferences
    extends BaseReferences<_$AppDatabase, $BadgesEarnedTable, BadgeEarnedRow> {
  $$BadgesEarnedTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    $_aliasNameGenerator(db.badgesEarned.cycleId, db.cycles.id),
  );

  $$CyclesTableProcessedTableManager? get cycleId {
    final $_column = $_itemColumn<int>('cycle_id');
    if ($_column == null) return null;
    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BadgesEarnedTableFilterComposer
    extends Composer<_$AppDatabase, $BadgesEarnedTable> {
  $$BadgesEarnedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get badgeId => $composableBuilder(
    column: $table.badgeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BadgesEarnedTableOrderingComposer
    extends Composer<_$AppDatabase, $BadgesEarnedTable> {
  $$BadgesEarnedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get badgeId => $composableBuilder(
    column: $table.badgeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BadgesEarnedTableAnnotationComposer
    extends Composer<_$AppDatabase, $BadgesEarnedTable> {
  $$BadgesEarnedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get badgeId =>
      $composableBuilder(column: $table.badgeId, builder: (column) => column);

  GeneratedColumn<int> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BadgesEarnedTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BadgesEarnedTable,
          BadgeEarnedRow,
          $$BadgesEarnedTableFilterComposer,
          $$BadgesEarnedTableOrderingComposer,
          $$BadgesEarnedTableAnnotationComposer,
          $$BadgesEarnedTableCreateCompanionBuilder,
          $$BadgesEarnedTableUpdateCompanionBuilder,
          (BadgeEarnedRow, $$BadgesEarnedTableReferences),
          BadgeEarnedRow,
          PrefetchHooks Function({bool cycleId})
        > {
  $$BadgesEarnedTableTableManager(_$AppDatabase db, $BadgesEarnedTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BadgesEarnedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BadgesEarnedTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BadgesEarnedTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> badgeId = const Value.absent(),
                Value<int> earnedAt = const Value.absent(),
                Value<int?> cycleId = const Value.absent(),
              }) => BadgesEarnedCompanion(
                id: id,
                badgeId: badgeId,
                earnedAt: earnedAt,
                cycleId: cycleId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String badgeId,
                required int earnedAt,
                Value<int?> cycleId = const Value.absent(),
              }) => BadgesEarnedCompanion.insert(
                id: id,
                badgeId: badgeId,
                earnedAt: earnedAt,
                cycleId: cycleId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BadgesEarnedTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable: $$BadgesEarnedTableReferences
                                    ._cycleIdTable(db),
                                referencedColumn: $$BadgesEarnedTableReferences
                                    ._cycleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BadgesEarnedTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BadgesEarnedTable,
      BadgeEarnedRow,
      $$BadgesEarnedTableFilterComposer,
      $$BadgesEarnedTableOrderingComposer,
      $$BadgesEarnedTableAnnotationComposer,
      $$BadgesEarnedTableCreateCompanionBuilder,
      $$BadgesEarnedTableUpdateCompanionBuilder,
      (BadgeEarnedRow, $$BadgesEarnedTableReferences),
      BadgeEarnedRow,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$OwnedItemsTableCreateCompanionBuilder =
    OwnedItemsCompanion Function({
      Value<int> id,
      required String itemId,
      required OwnedItemType itemType,
      Value<int> quantity,
      required int acquiredAt,
    });
typedef $$OwnedItemsTableUpdateCompanionBuilder =
    OwnedItemsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<OwnedItemType> itemType,
      Value<int> quantity,
      Value<int> acquiredAt,
    });

class $$OwnedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OwnedItemsTable> {
  $$OwnedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OwnedItemType, OwnedItemType, String>
  get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnedItemsTable> {
  $$OwnedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnedItemsTable> {
  $$OwnedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OwnedItemType, String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => column,
  );
}

class $$OwnedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnedItemsTable,
          OwnedItemRow,
          $$OwnedItemsTableFilterComposer,
          $$OwnedItemsTableOrderingComposer,
          $$OwnedItemsTableAnnotationComposer,
          $$OwnedItemsTableCreateCompanionBuilder,
          $$OwnedItemsTableUpdateCompanionBuilder,
          (
            OwnedItemRow,
            BaseReferences<_$AppDatabase, $OwnedItemsTable, OwnedItemRow>,
          ),
          OwnedItemRow,
          PrefetchHooks Function()
        > {
  $$OwnedItemsTableTableManager(_$AppDatabase db, $OwnedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<OwnedItemType> itemType = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> acquiredAt = const Value.absent(),
              }) => OwnedItemsCompanion(
                id: id,
                itemId: itemId,
                itemType: itemType,
                quantity: quantity,
                acquiredAt: acquiredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required OwnedItemType itemType,
                Value<int> quantity = const Value.absent(),
                required int acquiredAt,
              }) => OwnedItemsCompanion.insert(
                id: id,
                itemId: itemId,
                itemType: itemType,
                quantity: quantity,
                acquiredAt: acquiredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnedItemsTable,
      OwnedItemRow,
      $$OwnedItemsTableFilterComposer,
      $$OwnedItemsTableOrderingComposer,
      $$OwnedItemsTableAnnotationComposer,
      $$OwnedItemsTableCreateCompanionBuilder,
      $$OwnedItemsTableUpdateCompanionBuilder,
      (
        OwnedItemRow,
        BaseReferences<_$AppDatabase, $OwnedItemsTable, OwnedItemRow>,
      ),
      OwnedItemRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db, _db.currencies);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CyclesTableTableManager get cycles =>
      $$CyclesTableTableManager(_db, _db.cycles);
  $$CycleSummariesTableTableManager get cycleSummaries =>
      $$CycleSummariesTableTableManager(_db, _db.cycleSummaries);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$WellsTableTableManager get wells =>
      $$WellsTableTableManager(_db, _db.wells);
  $$IncomeEntriesTableTableManager get incomeEntries =>
      $$IncomeEntriesTableTableManager(_db, _db.incomeEntries);
  $$CropsCatalogTableTableManager get cropsCatalog =>
      $$CropsCatalogTableTableManager(_db, _db.cropsCatalog);
  $$PlotsTableTableManager get plots =>
      $$PlotsTableTableManager(_db, _db.plots);
  $$BonusAllocationsTableTableManager get bonusAllocations =>
      $$BonusAllocationsTableTableManager(_db, _db.bonusAllocations);
  $$SavingsBarnTableTableManager get savingsBarn =>
      $$SavingsBarnTableTableManager(_db, _db.savingsBarn);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PlotCycleResultsTableTableManager get plotCycleResults =>
      $$PlotCycleResultsTableTableManager(_db, _db.plotCycleResults);
  $$PlotFertilizerApplicationsTableTableManager
  get plotFertilizerApplications =>
      $$PlotFertilizerApplicationsTableTableManager(
        _db,
        _db.plotFertilizerApplications,
      );
  $$CoinLedgerTableTableManager get coinLedger =>
      $$CoinLedgerTableTableManager(_db, _db.coinLedger);
  $$BadgesEarnedTableTableManager get badgesEarned =>
      $$BadgesEarnedTableTableManager(_db, _db.badgesEarned);
  $$OwnedItemsTableTableManager get ownedItems =>
      $$OwnedItemsTableTableManager(_db, _db.ownedItems);
}
