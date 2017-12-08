import 'dart:mirrors';
import 'dart:async';
import 'package:tools/tools.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:option/option.dart';
import 'package:meta/meta.dart';
import 'a_mongo_data_source.dart';
import '../constants.dart';
import 'package:server/server.dart';
import 'package:server/data/data.dart';
import '../../data_sources.dart';
export 'a_mongo_data_source.dart';

abstract class AMongoObjectDataSource<T extends Object> extends AMongoDataSource {
  AMongoObjectDataSource(MongoDbConnectionPool pool) : super(pool);

  @protected
  Future<List<T>> searchAndSort(String query,
      {SelectorBuilder selector, String sortBy}) async {
    final SelectorBuilder searchSelector =
        _prepareTextSearch(query, selector: selector);
    return await getFromDb(searchSelector);
  }

  Future<PaginatedData<T>> genericSearchPaginated(String query,
      {SelectorBuilder selector,
      int offset: 0,
      int limit: defaultPerPage}) async {
    final SelectorBuilder searchSelector =
        _prepareTextSearch(query, selector: selector);
    return await getPaginatedFromDb(searchSelector);
  }

  Map<String, dynamic> _createMap(T object) {
    final Map<String, dynamic> data = <String, dynamic>{};
    prepareForDatabase(object, data);
    return data;
  }


  @override
  Future<DbCollection> getDbCollection(MongoDatabase con) async {
    ClassMirror c = reflectClass(T);
    InstanceMirror im = c.newInstance(const Symbol(''), []);


    Map<String,Index> indexes = <String,Index>{};

    for(TypeVariableMirror vm in c.typeVariables) {
      DbIndex metadata  = vm.metadata.firstWhere((InstanceMirror im) => im.type== reflectClass(DbIndex))?.reflectee;
      if(metadata==null)
        continue;

      Index index = indexes[metadata.name]??new Index();
      if(metadata.unique) {
        index.unique = true;
      }
      if(metadata.sparse)
        index.sparse = true;

      String name = vm.metadata.firstWhere((InstanceMirror im) => im.type== reflectClass(DbField))?.reflectee?.name??vm.simpleName.toString();

      IndexField indexField = new IndexField();
      indexField.order = metadata.order;
      indexField.ascending = metadata.ascending;
      indexField.name = name;

      index.fields.add(indexField);

      indexes[metadata.name] = index;
    }

    for(String key in indexes.keys) {
      Index idx = indexes[key];
      idx.sort();
      Map keys = {};
      for(IndexField indexField in idx.fields) {
        keys[indexField.name] = indexField.ascending ? 1: -1;
      }
      await con.db.createIndex( ,collection.name,
          keys: keys,
          name: key,
          unique: idx.unique,
          sparse: idx.sparse);
    }


    final DbCollection output = await super.getDbCollection(con);
    return output;
  }

  @protected
  Future<T> createDataObject(Map<String, Map> data) async {
    ClassMirror c = reflectClass(T);
    InstanceMirror im = c.newInstance(const Symbol(''), []);
    T output = im.reflectee;

    for(TypeVariableMirror vm in c.typeVariables) {
      DbField metadata = vm.metadata.firstWhere((InstanceMirror im) => im.type==reflectClass(DbField))?.reflectee;
      if(metadata?.ignore??false)
          break;

      String name = vm.simpleName.toString();
      if(isNotNullOrWhitespace(metadata?.name))
        name = metadata.name;


      dynamic value;
      if(data.containsKey(name)) {
        value = data[name];
      } else  {
        value = metadata?.defaultValue;
      }

      if(data.containsKey(name)) {
        im.setField(vm.simpleName, value);
      }

    }

    return output;
  }

  Future<Option<T>> getForOneFromDb(SelectorBuilder selector) async {
    final List<T> results = await getFromDb(selector.limit(1));
    if (results.length == 0) {
      return new None<T>();
    }
    return new Some<T>(results.first);
  }

  Future<List<T>> getFromDb(SelectorBuilder selector) async {
    final Stream<T> stream = await streamFromDb(selector);
    final List<T> output = new List<T>();
    await for (T result in stream) {
      output.add(result);
    }
    return output;
  }

  Future<Stream<T>> streamFromDb(dynamic selector) async {
    final Stream<Map> outputStream = await genericFindStream(selector);
    return streamToObject(outputStream);
  }

  Future<Stream<T>> streamToObject(Stream str) async {
    return str.asyncMap<T>((Map data) async {
      if (data.containsKey("\$err"))
        throw new Exception("Database error: $data['\$err']");
      return await createDataObject(data);
    });
  }

  @protected
  Future<PaginatedData<T>> getPaginatedFromDb(SelectorBuilder selector,
      {int offset: 0,
      int limit: defaultPerPage,
      String sortField,
      bool sortDescending: false}) async {
    final PaginatedData<T> output = new PaginatedData<T>();
    output.totalCount = await genericCount(selector);
    output.limit = limit;
    output.startIndex = offset;

    if (selector == null) selector == where;
    if (!isNullOrWhitespace(sortField))
      selector.sortBy(sortField, descending: sortDescending);

    selector.limit(limit).skip(offset);

    output.data.addAll(await getFromDb(selector));
    return output;
  }

  @protected
  Future<Null> insertIntoDb(T item) async {
    return await collectionWrapper((DbCollection collection) async {
      final Map<String, dynamic> data = _createMap(item);

      await collection.insert(data);
    });
  }

  SelectorBuilder _prepareTextSearch(String query,
      {SelectorBuilder selector, String sortBy}) {
    SelectorBuilder searchSelector = where.eq($text, {$search: query});
    if (selector != null) searchSelector = searchSelector.and(selector);
    if (!isNullOrWhitespace(sortBy)) {
      searchSelector = searchSelector.sortBy(sortBy);
    } else {
      searchSelector =
          searchSelector.metaTextScore("score").sortByMetaTextScore("score");
    }
    return searchSelector;
  }



  @protected
  void prepareForDatabase(T object, Map<String, dynamic> data) {
    InstanceMirror im = reflect(object);

    for(TypeVariableMirror vm in im.type.typeVariables) {
      DbField metadata = vm.metadata.firstWhere((InstanceMirror im) => im.type==reflectClass(DbField))?.reflectee;
      if(metadata?.ignore??false)
        break;

      String name = vm.simpleName.toString();
      if(isNotNullOrWhitespace(metadata?.name))
        name = metadata.name;

      data[name] = im.getField(vm.simpleName).reflectee;
    }
  }

  @protected
  Future<Null> updateToDb(dynamic selector, T item) async {
    return await collectionWrapper((DbCollection collection) async {
      final Map<String, dynamic> data = await collection.findOne(selector);
      if (data == null)
        throw new InvalidInputException("Object to update not found");
      final dynamic originalId = data['_id'];
      prepareForDatabase(item, data);
      await collection.save(data);
      if (data['_id'] != originalId) await collection.remove(selector);
    });
  }

  void _constructKeyQuery(dynamic key) {



  }

  Future<Null> deleteByKey(dynamic key) => deleteFromDb(where.eq(idField, id));


}

class Index {
  final List<IndexField> fields = <IndexField>[];
  bool unique;
  bool sparse;

  void sort() {
    fields.sort((a,b) => a.order.compareTo(b.order));
  }
}
class IndexField {
  String name;
  bool ascending;
  int order;
}
