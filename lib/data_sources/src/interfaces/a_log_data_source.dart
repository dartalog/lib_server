import 'dart:async';
import 'package:logging/logging.dart';
import 'package:server/data/data.dart';
import 'a_data_source.dart';

abstract class ALogDataSource extends ADataSource {
  static final Logger _log = new Logger('ALogDataSource');

  Future<Null> create(LogEntry data);
}
