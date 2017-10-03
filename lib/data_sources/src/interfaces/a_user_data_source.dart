import 'dart:async';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:server/data/data.dart';
import 'a_id_based_data_source.dart';

abstract class AUserDataSource<T extends AUser> extends AIdBasedDataSource<T> {
  static final Logger _log = new Logger('AUserDataSource');

  Future<List<T>> getAdmins();

  Future<Null> setPassword(String username, String password);
  Future<Option<String>> getPasswordHash(String username);
}
