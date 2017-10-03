import 'dart:async';
import 'dart:io';
import 'package:server/server.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:path/path.dart' as path;

const SERVICE_CONTEXT = #server.invocationContext;

AServerContext get serverContext => ss.lookup(SERVICE_CONTEXT);

class AServerContext {
  final String dataPath;
  final String rootDirectory;

  Future<Null> checkIfSetupRequired() async {
    if (await isSetupAvailable()) throw new SetupRequiredException();
  }

  void disableSetup() {
    _setupDisabled = true;
  }

  final String setupLockFilePath;

  bool _setupDisabled = false;

  Future<bool> isSetupAvailable() async {
    if (_setupDisabled) return false;

    if (await new File(setupLockFilePath).exists()) {
      _setupDisabled = true;
      return false;
    }
    return true;
  }

  AServerContext(this.rootDirectory, this.dataPath):
        setupLockFilePath = path.join(rootDirectory, dataPath, "setup.lock");
}