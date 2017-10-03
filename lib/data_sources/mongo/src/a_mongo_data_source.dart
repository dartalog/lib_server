import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:option/option.dart';
import 'package:meta/meta.dart';
import 'mongo_db_connection_pool.dart';
export 'mongo_db_connection_pool.dart';
import 'mongo_database.dart';
export 'mongo_database.dart';
import 'mongo_collection.dart';

abstract class AMongoDataSource {
  @protected
  Logger get childLogger;

  final MongoDbConnectionPool dbConnectionPool;
  AMongoDataSource(this.dbConnectionPool);

  int getOffset(int page, int perPage) => page * perPage;

  @protected
  Future<T> databaseWrapper<T>(Future<T> statement(MongoDatabase db),
      {int retries: 5}) async {
    return await dbConnectionPool.databaseWrapper<T>(statement,
        retries: retries);
  }

  @protected
  Future<T> collectionWrapper<T>(Future<T> statement(DbCollection c)) =>
      databaseWrapper((MongoDatabase con) async =>
          await statement(await getDbCollection(con)));

  @protected
  Future<Map> deleteFromDb(dynamic selector) async {
    return await collectionWrapper<Map>((DbCollection collection) async {
      return await collection.remove(selector);
    });
  }

  @protected
  MongoCollection get collection;

  Future<DbCollection> getDbCollection(MongoDatabase con) async {
    return await collection.getDbCollection(con);
  }

  @protected
  Future<Map> genericUpdate(dynamic selector, dynamic document,
      {bool multiUpdate: false}) async {
    return await collectionWrapper<Map>((DbCollection collection) async {
      return await collection.update(selector, document,
          multiUpdate: multiUpdate);
    });
  }

  @protected
  Future<Map> aggregate(List<dynamic> pipeline) async {
    return await collectionWrapper<Map>((DbCollection collection) async {
      return await collection.aggregate(pipeline);
    });
  }

  @protected
  Future<bool> exists(dynamic selector) async {
    return await collectionWrapper((DbCollection collection) async {
      final int count = await collection.count(selector);
      return count > 0;
    });
  }

  @protected
  Future<Option<Map>> genericFindOne(SelectorBuilder selector) async {
    final List<Map> output = await _genericFind(selector.limit(1));
    if (output.length == 0) return new None<Map>();
    return new Some<Map>(output[0]);
  }

  Future<List<Map>> _genericFind(SelectorBuilder selector) async {
    return await collectionWrapper((DbCollection collection) async {
      final Stream<Map> str = collection.find(selector);
      final List<Map> output = await str.toList();
      return output;
    });
  }

  Future<Stream<Map>> genericFindStream(SelectorBuilder selector) async {
    return await collectionWrapper((DbCollection collection) async {
      return collection.find(selector);
    });
  }

  @protected
  Future<int> genericCount(SelectorBuilder selector) async {
    return await collectionWrapper((DbCollection collection) async {
      return collection.count(selector);
    });
  }
}
