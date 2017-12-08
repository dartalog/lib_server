import 'dart:async';
import 'package:server/data/data.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:option/option.dart';
import 'a_mongo_object_data_source.dart';
import 'package:meta/meta.dart';
import '../constants.dart';
import 'package:server/server.dart';
export 'a_mongo_object_data_source.dart';
import '../../data_sources.dart';
import 'package:server/data_sources/interfaces.dart';

abstract class AMongoIdDataSource<T extends AIdData>
    extends AMongoObjectDataSource<T> implements AIdBasedDataSource<T> {
  AMongoIdDataSource(MongoDbConnectionPool pool) : super(pool);

  @override
  Future<Null> deleteById(String id) => deleteFromDb(where.eq(idField, id));

  @override
  Future<bool> existsById(String id) => super.exists(where.eq(idField, id));

  @override
  Future<IdDataList<T>> getAll({String sortField: null}) =>
      getListFromDb(where.sortBy(sortField ?? idField));

  Future<PaginatedIdData<T>> getPaginated(
          {String sortField: null, int offset: 0, int limit: defaultPerPage}) =>
      getPaginatedListFromDb(where.sortBy(sortField ?? idField),
          offset: offset, limit: limit);

  @override
  Future<Option<T>> getById(String id) =>
      getForOneFromDb(where.eq(idField, id));

  @override
  Future<String> create(T object) async {
    await insertIntoDb(object);
    return object.id;
  }

  @override
  Future<String> update(String id, T object) async {
    await updateToDb(where.eq(idField, id), object);
    return object.id;
  }

  @override
  void updateMap(AIdData item, Map<String, dynamic> data) {
    staticUpdateMap(item, data);
  }

  static void staticUpdateMap(AIdData item, Map<String, dynamic> data) {
    data[idField] = item.id;
  }

  static void setIdForData(AIdData item, Map<String, dynamic> data) {
    item.id = data[idField];
  }

  @protected
  Future<PaginatedIdData<T>> getPaginatedListFromDb(SelectorBuilder selector,
          {int offset: 0,
          int limit: defaultPerPage,
          String sortField,
          bool sortDescending: false}) async =>
      new PaginatedIdData<T>.copyPaginatedData(await getPaginatedFromDb(
          selector,
          offset: offset,
          limit: limit,
          sortField: sortField,
          sortDescending: sortDescending));

  @override
  Future<PaginatedIdData<T>> genericSearchPaginated(String query,
          {SelectorBuilder selector,
          int offset: 0,
          int limit: defaultPerPage}) async =>
      new PaginatedIdData<T>.copyPaginatedData(await super
          .genericSearchPaginated(query, offset: offset, limit: limit));

  @protected
  Future<IdDataList<T>> getListFromDb(dynamic selector) async =>
      new IdDataList<T>.copy(await getFromDb(selector));

  @override
  Future<IdDataList<T>> search(String query,
      {SelectorBuilder selector, String sortBy}) async {
    final List<T> data =
        await super.searchAndSort(query, selector: selector, sortBy: sortBy);
    return new IdDataList<T>.copy(data);
  }
}
