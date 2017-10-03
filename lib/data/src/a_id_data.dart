import 'a_data.dart';

class AIdData extends AData {
  String id = "";

  AIdData();

  AIdData.withValues(this.id);

  AIdData.copy(dynamic o) {
    this.id = o.id;
  }
}
