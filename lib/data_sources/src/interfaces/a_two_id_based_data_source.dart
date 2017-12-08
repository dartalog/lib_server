import 'dart:async';
import 'package:logging/logging.dart';
import 'package:server/data/data.dart';
import 'package:option/option.dart';
import 'package:server/data_sources/src/interfaces/a_data_source.dart';
import 'package:server/server.dart';

abstract class ATwoIdBasedDataSource<T extends IIdData> implements ADataSource {
  static final Logger _log = new Logger('ATwoIdBasedDataSource');

  Future<IdDataList<T>> getAll();
  Future<PaginatedData<T>> getAllPaginated(
      {int page: 0, int perPage: defaultPerPage});
  Future<Option<T>> getById(String id, String id2);
  Future<String> create(T t);
  Future<String> update(String id, String id2, T t);
  Future<Null> deleteById(String id, String id2);
  Future<bool> existsById(String id, String id2);
  Future<IdDataList<T>> search(String query);
}
