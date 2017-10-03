import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'mongo_database.dart';

typedef Future<Null> CollectionPrep(mongo.Db db, String name);
class MongoCollection {
  final String name;
  final CollectionPrep _prepareCollection;

  MongoCollection(this.name, [this._prepareCollection = null]);

  Future<mongo.DbCollection> getDbCollection(MongoDatabase con) async {
    if(_prepareCollection!=null)
      await _prepareCollection(con.db, this.name);
    return con.db.collection(this.name);
  }

}