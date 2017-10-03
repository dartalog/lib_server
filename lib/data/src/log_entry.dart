import 'package:logging/logging.dart';

class LogEntry {
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
