import 'package:server/data_sources/interfaces.dart';
import 'package:server/data/data.dart';
import 'package:logging/logging.dart';

class DbLoggingHandler {
  final ALogDataSource _logDataSource;

  DbLoggingHandler(this._logDataSource);

  void call(LogRecord logRecord) {
    try {
      this._logDataSource.create(new LogEntry.fromLogRecord(logRecord));
    } catch (e, st) {
      // Where would I log it?
    }
  }
}
