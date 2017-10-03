import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class MongoDatabase {
  static const int maxConnections = 3;

  final mongo.Db db;

  MongoDatabase(this.db);


  Future<Null> nukeDatabase() async {
    final mongo.DbCommand cmd = mongo.DbCommand.createDropDatabaseCommand(db);
    await db.executeDbCommand(cmd);
  }

//  Future<Null> startTransaction() async {
//    final mongo.DbCollection transactions = await getTransactionsCollection();
//    await transactions.findOne({"state": "initial"});
//  }

}