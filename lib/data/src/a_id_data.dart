import 'package:server/data_sources/data_sources.dart';
import 'a_data.dart';

abstract class IIdData {
  String get id;
  set id(String value);
}

abstract class AIdData extends AData implements IIdData {
  @DbIndex(idField)
  String get id =>_id;

  @DbIndex(idField)
  set id(String value) => _id = value;

  String _id = "";

  AIdData();

  AIdData.withValues(this._id);

  AIdData.copy(dynamic o) {
    this.id = o.id;
  }
}
