// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAccountCollection on Isar {
  IsarCollection<Account> get accounts => this.collection();
}

const AccountSchema = CollectionSchema(
  name: r'Account',
  id: -6646797162501847804,
  properties: {
    r'autoSaveAmount': PropertySchema(
      id: 0,
      name: r'autoSaveAmount',
      type: IsarType.double,
    ),
    r'autoSaveEnabled': PropertySchema(
      id: 1,
      name: r'autoSaveEnabled',
      type: IsarType.bool,
    ),
    r'autoSaveIsPercentage': PropertySchema(
      id: 2,
      name: r'autoSaveIsPercentage',
      type: IsarType.bool,
    ),
    r'autoSaveTargetAccountId': PropertySchema(
      id: 3,
      name: r'autoSaveTargetAccountId',
      type: IsarType.long,
    ),
    r'buckets': PropertySchema(
      id: 4,
      name: r'buckets',
      type: IsarType.objectList,
      target: r'AccountBucket',
    ),
    r'color': PropertySchema(
      id: 5,
      name: r'color',
      type: IsarType.long,
    ),
    r'icon': PropertySchema(
      id: 6,
      name: r'icon',
      type: IsarType.long,
    ),
    r'isArchived': PropertySchema(
      id: 7,
      name: r'isArchived',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'openingBalance': PropertySchema(
      id: 9,
      name: r'openingBalance',
      type: IsarType.double,
    ),
    r'reservedBalance': PropertySchema(
      id: 10,
      name: r'reservedBalance',
      type: IsarType.double,
    ),
    r'reservedLimit': PropertySchema(
      id: 11,
      name: r'reservedLimit',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 12,
      name: r'type',
      type: IsarType.string,
      enumMap: _AccounttypeEnumValueMap,
    )
  },
  estimateSize: _accountEstimateSize,
  serialize: _accountSerialize,
  deserialize: _accountDeserialize,
  deserializeProp: _accountDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'AccountBucket': AccountBucketSchema},
  getId: _accountGetId,
  getLinks: _accountGetLinks,
  attach: _accountAttach,
  version: '3.1.0+1',
);

int _accountEstimateSize(
  Account object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.buckets.length * 3;
  {
    final offsets = allOffsets[AccountBucket]!;
    for (var i = 0; i < object.buckets.length; i++) {
      final value = object.buckets[i];
      bytesCount +=
          AccountBucketSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _accountSerialize(
  Account object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.autoSaveAmount);
  writer.writeBool(offsets[1], object.autoSaveEnabled);
  writer.writeBool(offsets[2], object.autoSaveIsPercentage);
  writer.writeLong(offsets[3], object.autoSaveTargetAccountId);
  writer.writeObjectList<AccountBucket>(
    offsets[4],
    allOffsets,
    AccountBucketSchema.serialize,
    object.buckets,
  );
  writer.writeLong(offsets[5], object.color);
  writer.writeLong(offsets[6], object.icon);
  writer.writeBool(offsets[7], object.isArchived);
  writer.writeString(offsets[8], object.name);
  writer.writeDouble(offsets[9], object.openingBalance);
  writer.writeDouble(offsets[10], object.reservedBalance);
  writer.writeDouble(offsets[11], object.reservedLimit);
  writer.writeString(offsets[12], object.type.name);
}

Account _accountDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Account();
  object.autoSaveAmount = reader.readDouble(offsets[0]);
  object.autoSaveEnabled = reader.readBool(offsets[1]);
  object.autoSaveIsPercentage = reader.readBool(offsets[2]);
  object.autoSaveTargetAccountId = reader.readLongOrNull(offsets[3]);
  object.buckets = reader.readObjectList<AccountBucket>(
        offsets[4],
        AccountBucketSchema.deserialize,
        allOffsets,
        AccountBucket(),
      ) ??
      [];
  object.color = reader.readLong(offsets[5]);
  object.icon = reader.readLong(offsets[6]);
  object.id = id;
  object.isArchived = reader.readBool(offsets[7]);
  object.name = reader.readString(offsets[8]);
  object.openingBalance = reader.readDouble(offsets[9]);
  object.reservedBalance = reader.readDouble(offsets[10]);
  object.reservedLimit = reader.readDouble(offsets[11]);
  object.type =
      _AccounttypeValueEnumMap[reader.readStringOrNull(offsets[12])] ??
          AccountType.wallet;
  return object;
}

P _accountDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readObjectList<AccountBucket>(
            offset,
            AccountBucketSchema.deserialize,
            allOffsets,
            AccountBucket(),
          ) ??
          []) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (_AccounttypeValueEnumMap[reader.readStringOrNull(offset)] ??
          AccountType.wallet) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AccounttypeEnumValueMap = {
  r'wallet': r'wallet',
  r'bank': r'bank',
  r'cash': r'cash',
  r'savings': r'savings',
  r'salary': r'salary',
  r'others': r'others',
};
const _AccounttypeValueEnumMap = {
  r'wallet': AccountType.wallet,
  r'bank': AccountType.bank,
  r'cash': AccountType.cash,
  r'savings': AccountType.savings,
  r'salary': AccountType.salary,
  r'others': AccountType.others,
};

Id _accountGetId(Account object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _accountGetLinks(Account object) {
  return [];
}

void _accountAttach(IsarCollection<dynamic> col, Id id, Account object) {
  object.id = id;
}

extension AccountQueryWhereSort on QueryBuilder<Account, Account, QWhere> {
  QueryBuilder<Account, Account, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AccountQueryWhere on QueryBuilder<Account, Account, QWhereClause> {
  QueryBuilder<Account, Account, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Account, Account, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Account, Account, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Account, Account, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AccountQueryFilter
    on QueryBuilder<Account, Account, QFilterCondition> {
  QueryBuilder<Account, Account, QAfterFilterCondition> autoSaveAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSaveAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'autoSaveAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> autoSaveAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'autoSaveAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> autoSaveAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'autoSaveAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> autoSaveEnabledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSaveEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveIsPercentageEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSaveIsPercentage',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'autoSaveTargetAccountId',
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'autoSaveTargetAccountId',
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoSaveTargetAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'autoSaveTargetAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'autoSaveTargetAccountId',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      autoSaveTargetAccountIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'autoSaveTargetAccountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      bucketsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'buckets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> colorEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> colorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> colorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> colorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> iconEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'icon',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> iconGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'icon',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> iconLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'icon',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> iconBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'icon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> isArchivedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isArchived',
        value: value,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> openingBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      openingBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> openingBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> openingBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openingBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservedBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      reservedBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reservedBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reservedBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reservedBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedLimitEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reservedLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition>
      reservedLimitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reservedLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedLimitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reservedLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> reservedLimitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reservedLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeEqualTo(
    AccountType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeGreaterThan(
    AccountType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeLessThan(
    AccountType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeBetween(
    AccountType lower,
    AccountType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<Account, Account, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension AccountQueryObject
    on QueryBuilder<Account, Account, QFilterCondition> {
  QueryBuilder<Account, Account, QAfterFilterCondition> bucketsElement(
      FilterQuery<AccountBucket> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'buckets');
    });
  }
}

extension AccountQueryLinks
    on QueryBuilder<Account, Account, QFilterCondition> {}

extension AccountQuerySortBy on QueryBuilder<Account, Account, QSortBy> {
  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveAmount', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveAmount', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveEnabled', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveEnabled', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveIsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveIsPercentage', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy>
      sortByAutoSaveIsPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveIsPercentage', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByAutoSaveTargetAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveTargetAccountId', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy>
      sortByAutoSaveTargetAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveTargetAccountId', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByOpeningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingBalance', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByOpeningBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingBalance', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByReservedBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedBalance', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByReservedBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedBalance', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByReservedLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedLimit', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByReservedLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedLimit', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AccountQuerySortThenBy
    on QueryBuilder<Account, Account, QSortThenBy> {
  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveAmount', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveAmount', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveEnabled', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveEnabled', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveIsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveIsPercentage', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy>
      thenByAutoSaveIsPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveIsPercentage', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByAutoSaveTargetAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveTargetAccountId', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy>
      thenByAutoSaveTargetAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoSaveTargetAccountId', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icon', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByOpeningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingBalance', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByOpeningBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openingBalance', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByReservedBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedBalance', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByReservedBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedBalance', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByReservedLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedLimit', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByReservedLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reservedLimit', Sort.desc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Account, Account, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AccountQueryWhereDistinct
    on QueryBuilder<Account, Account, QDistinct> {
  QueryBuilder<Account, Account, QDistinct> distinctByAutoSaveAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSaveAmount');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByAutoSaveEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSaveEnabled');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByAutoSaveIsPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSaveIsPercentage');
    });
  }

  QueryBuilder<Account, Account, QDistinct>
      distinctByAutoSaveTargetAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoSaveTargetAccountId');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icon');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isArchived');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByOpeningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openingBalance');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByReservedBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reservedBalance');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByReservedLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reservedLimit');
    });
  }

  QueryBuilder<Account, Account, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension AccountQueryProperty
    on QueryBuilder<Account, Account, QQueryProperty> {
  QueryBuilder<Account, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Account, double, QQueryOperations> autoSaveAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSaveAmount');
    });
  }

  QueryBuilder<Account, bool, QQueryOperations> autoSaveEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSaveEnabled');
    });
  }

  QueryBuilder<Account, bool, QQueryOperations> autoSaveIsPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSaveIsPercentage');
    });
  }

  QueryBuilder<Account, int?, QQueryOperations>
      autoSaveTargetAccountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoSaveTargetAccountId');
    });
  }

  QueryBuilder<Account, List<AccountBucket>, QQueryOperations>
      bucketsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'buckets');
    });
  }

  QueryBuilder<Account, int, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<Account, int, QQueryOperations> iconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icon');
    });
  }

  QueryBuilder<Account, bool, QQueryOperations> isArchivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isArchived');
    });
  }

  QueryBuilder<Account, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Account, double, QQueryOperations> openingBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openingBalance');
    });
  }

  QueryBuilder<Account, double, QQueryOperations> reservedBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reservedBalance');
    });
  }

  QueryBuilder<Account, double, QQueryOperations> reservedLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reservedLimit');
    });
  }

  QueryBuilder<Account, AccountType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const AccountBucketSchema = Schema(
  name: r'AccountBucket',
  id: 7266005888992627427,
  properties: {
    r'balance': PropertySchema(
      id: 0,
      name: r'balance',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _accountBucketEstimateSize,
  serialize: _accountBucketSerialize,
  deserialize: _accountBucketDeserialize,
  deserializeProp: _accountBucketDeserializeProp,
);

int _accountBucketEstimateSize(
  AccountBucket object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _accountBucketSerialize(
  AccountBucket object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.balance);
  writer.writeString(offsets[1], object.name);
}

AccountBucket _accountBucketDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AccountBucket();
  object.balance = reader.readDouble(offsets[0]);
  object.name = reader.readStringOrNull(offsets[1]);
  return object;
}

P _accountBucketDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension AccountBucketQueryFilter
    on QueryBuilder<AccountBucket, AccountBucket, QFilterCondition> {
  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<AccountBucket, AccountBucket, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension AccountBucketQueryObject
    on QueryBuilder<AccountBucket, AccountBucket, QFilterCondition> {}
