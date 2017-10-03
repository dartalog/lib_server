import 'dart:async';
import 'package:logging/logging.dart';
import 'package:server/data/data.dart';
import 'package:option/option.dart';
import 'package:server/data_sources/src/interfaces/a_data_source.dart';

abstract class AIdBasedDataSource<T extends AIdData> extends ADataSource {
  static final Logger _log = new Logger('AUuidBasedDataSource');

  Future<IdDataList<T>> getAll();
  Future<Option<T>> getById(String id);
  Future<String> create(T t);
  Future<String> update(String id, T t);
  Future<Null> deleteById(String id);
  Future<bool> existsById(String id);
  Future<IdDataList<T>> search(String query);
}
