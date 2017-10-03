import 'dart:async';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:tools/tools.dart';
import 'package:meta/meta.dart';

abstract class ABackgroundService {
  static final Logger _log = new Logger('ABackgroundService');

  bool _stop = false;

  Future<Null> start() {
    _log.info("Starting background service");
    return _backgroundThread();
  }


  void stop() {
    _log.info("Stopping background service");
    _stop = true;
  }


  @protected
  Future<Null> doWork();

  Future<Null> _backgroundThread() async {
    while (!_stop) {
      try {
        _log.info("Starting background service cycle");
        await doWork();
      } catch (e, st) {
        _log.severe(e, st);
      } finally {
        await wait(milliseconds: 60000);
      }
    }
  }


}