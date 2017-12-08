import 'a_id_data.dart';
import 'package:server/data_sources/data_sources.dart';

abstract class AUser extends AIdData {
  //await db.createIndex(name,
  //keys: {"id": "text", "name": "text"}, name: "TextIndex");

  String password;

  @DbIndex("TextIndex", text: true)
  String name;
  String type;

  AUser();
  AUser.copy(dynamic o) : super.copy(o) {
    this.name = o.name;
    this.type = o.type;
    if (o.password == null)
      this.password = "";
    else
      this.password = o.password;
  }


}