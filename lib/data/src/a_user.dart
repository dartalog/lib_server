import 'a_id_data.dart';

abstract class AUser extends AIdData {
  String password;
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