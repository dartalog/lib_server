import 'package:server/data/data.dart';

abstract class AUserModel<T extends AUser> {
  bool verifyPassword(String hash, String password);
}