import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'mongo_collection.dart';
import '../constants.dart';

class MongoIdCollection extends MongoCollection {
  final CollectionPrep _innerCollectionPrep;

  MongoIdCollection(String name, [this._innerCollectionPrep= null]):
        super(name, (mongo.Db db, String name) async {
        await db.createIndex(name,
            keys: {idField: 1}, name: "IdIndex", unique: true);
        if(_innerCollectionPrep!=null) {
          await _innerCollectionPrep(db, name);
        }
      });


}