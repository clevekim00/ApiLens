// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEnvironmentItemCollection on Isar {
  IsarCollection<EnvironmentItem> get environmentItems => this.collection();
}

const EnvironmentItemSchema = CollectionSchema(
  name: r'EnvironmentItem',
  id: 8110338257624782644,
  properties: {
    r'isSelected': PropertySchema(
      id: 0,
      name: r'isSelected',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'variablesJson': PropertySchema(
      id: 2,
      name: r'variablesJson',
      type: IsarType.string,
    )
  },
  estimateSize: _environmentItemEstimateSize,
  serialize: _environmentItemSerialize,
  deserialize: _environmentItemDeserialize,
  deserializeProp: _environmentItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'isSelected': IndexSchema(
      id: 5103110419848918687,
      name: r'isSelected',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isSelected',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _environmentItemGetId,
  getLinks: _environmentItemGetLinks,
  attach: _environmentItemAttach,
  version: '3.1.0+1',
);

int _environmentItemEstimateSize(
  EnvironmentItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.variablesJson.length * 3;
  return bytesCount;
}

void _environmentItemSerialize(
  EnvironmentItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isSelected);
  writer.writeString(offsets[1], object.name);
  writer.writeString(offsets[2], object.variablesJson);
}

EnvironmentItem _environmentItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EnvironmentItem();
  object.id = id;
  object.isSelected = reader.readBool(offsets[0]);
  object.name = reader.readString(offsets[1]);
  object.variablesJson = reader.readString(offsets[2]);
  return object;
}

P _environmentItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _environmentItemGetId(EnvironmentItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _environmentItemGetLinks(EnvironmentItem object) {
  return [];
}

void _environmentItemAttach(
    IsarCollection<dynamic> col, Id id, EnvironmentItem object) {
  object.id = id;
}

extension EnvironmentItemQueryWhereSort
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QWhere> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhere> anyIsSelected() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSelected'),
      );
    });
  }
}

extension EnvironmentItemQueryWhere
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QWhereClause> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause>
      isSelectedEqualTo(bool isSelected) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSelected',
        value: [isSelected],
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterWhereClause>
      isSelectedNotEqualTo(bool isSelected) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSelected',
              lower: [],
              upper: [isSelected],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSelected',
              lower: [isSelected],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSelected',
              lower: [isSelected],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSelected',
              lower: [],
              upper: [isSelected],
              includeUpper: false,
            ));
      }
    });
  }
}

extension EnvironmentItemQueryFilter
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QFilterCondition> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      isSelectedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSelected',
        value: value,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
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

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'variablesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'variablesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'variablesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'variablesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterFilterCondition>
      variablesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'variablesJson',
        value: '',
      ));
    });
  }
}

extension EnvironmentItemQueryObject
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QFilterCondition> {}

extension EnvironmentItemQueryLinks
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QFilterCondition> {}

extension EnvironmentItemQuerySortBy
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QSortBy> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      sortByIsSelected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSelected', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      sortByIsSelectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSelected', Sort.desc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      sortByVariablesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variablesJson', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      sortByVariablesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variablesJson', Sort.desc);
    });
  }
}

extension EnvironmentItemQuerySortThenBy
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QSortThenBy> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      thenByIsSelected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSelected', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      thenByIsSelectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSelected', Sort.desc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      thenByVariablesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variablesJson', Sort.asc);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QAfterSortBy>
      thenByVariablesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'variablesJson', Sort.desc);
    });
  }
}

extension EnvironmentItemQueryWhereDistinct
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QDistinct> {
  QueryBuilder<EnvironmentItem, EnvironmentItem, QDistinct>
      distinctByIsSelected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSelected');
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EnvironmentItem, EnvironmentItem, QDistinct>
      distinctByVariablesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'variablesJson',
          caseSensitive: caseSensitive);
    });
  }
}

extension EnvironmentItemQueryProperty
    on QueryBuilder<EnvironmentItem, EnvironmentItem, QQueryProperty> {
  QueryBuilder<EnvironmentItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EnvironmentItem, bool, QQueryOperations> isSelectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSelected');
    });
  }

  QueryBuilder<EnvironmentItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<EnvironmentItem, String, QQueryOperations>
      variablesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'variablesJson');
    });
  }
}
