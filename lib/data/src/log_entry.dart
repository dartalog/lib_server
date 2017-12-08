import 'package:logging/logging.dart';
import 'package:server/data_sources/data_sources.dart';

class LogEntry {
  @DbIndex("LogTimestampIndex", ascending: false)
  DateTime timestamp;
  String message;
  String level;
  String error;
  String stackTrace;
  String logger;

  LogEntry();

  LogEntry.fromLogRecord(LogRecord logRecord) {
    this.timestamp = logRecord.time;
    this.message = logRecord.message;
    this.level = logRecord.level.toString();
    this.error = logRecord.error?.toString();
    this.logger = logRecord.loggerName;
    this.stackTrace = logRecord.stackTrace?.toString();
  }
}
