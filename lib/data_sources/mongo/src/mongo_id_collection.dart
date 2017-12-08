import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'mongo_collection.dart';
import '../constants.dart';
import '../../data_sources.dart';

class MongoIdCollection extends MongoCollection {
  final CollectionPrep _innerCollectionPrep;

  MongoIdCollection(String name, [this._innerCollectionPrep= null]):
        super(name, (mongo.Db db, String name) async {
        if(_innerCollectionPrep!=null) {
          await _innerCollectionPrep(db, name);
        }
      });


}