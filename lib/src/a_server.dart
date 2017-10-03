import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:option/option.dart';
import 'package:logging/logging.dart';
import 'package:server/data/data.dart';
import 'package:server/data_sources/interfaces.dart';
import 'package:di/di.dart';
import 'package:shelf_auth/shelf_auth.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:path/path.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:server/model/model.dart';
import 'package:path/path.dart' as path;
import '../server.dart';
import 'package:tools/tools.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:logging_handlers/server_logging_handlers.dart'
    as server_logging;

abstract class AServer {
  static final Logger _log = new Logger('AServer');
  final AUserDataSource userDataSource;
  final AUserModel userModel;

  String instanceUuid;
  String connectionString;
  ModuleInjector injector;

  Completer _serverCompleter;
  HttpServer _server;

  final String dataPath;

  String rootUrl;
  final String rootDirectory;
  final String serverName;

  final List<ABackgroundService> _backgroundServices = <ABackgroundService>[];


  AServer(this.serverName, this.rootDirectory, this.dataPath,
      this.userDataSource, this.userModel) {
    _log.fine("new Server()");
  }

  Middleware defaultAuthMiddleware;

  AServerContext createServerContext() => new AServerContext(this.rootDirectory, this.dataPath);


  void setUpRouter(Router router) {
    // Set up authentication stuff
    final JwtSessionHandler<Principal, SessionClaimSet> sessionHandler =
        new JwtSessionHandler<Principal, SessionClaimSet>(
            this.serverName, generateUuid(), _getUser,
            idleTimeout: new Duration(hours: 1),
            totalSessionTimeout: new Duration(days: 7));

    final Middleware loginMiddleware = authenticate(<Authenticator<Principal>>[
      new UsernamePasswordAuthenticator<Principal>(_authenticateUser)
    ], sessionHandler: sessionHandler, allowHttp: true);

    defaultAuthMiddleware = authenticate(<Authenticator<Principal>>[],
        sessionHandler: sessionHandler,
        allowHttp: true,
        allowAnonymousAccess: true);

    final Handler loginPipeline = const Pipeline()
        .addMiddleware(loginMiddleware)
        .addHandler((Request request) => new Response.ok(""));

    router.add('/login/', <String>['POST', 'GET', 'OPTIONS'], loginPipeline);
  }

  dynamic start(String bindIp, int port) async {
    _log.fine("Start start($bindIp, $port)");
    if (_server != null) throw new Exception("Server has already been started");

    try {
      final Router root = router();
      setUpRouter(root);

      final Directory siteDir = new Directory(join(rootDirectory, 'web/'));
      if (siteDir.existsSync()) {
        final Handler staticSiteHandler = createStaticHandler(siteDir.path,
            listDirectories: false,
            defaultDocument: 'index.html',
            serveFilesOutsidePath: true);
        root.add('/', <String>['GET', 'OPTIONS'], staticSiteHandler,
            exactMatch: false);
      }

      final Map<String, String> extraHeaders = <String, String>{
        'Access-Control-Allow-Headers':
            'Origin, X-Requested-With, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Methods': 'POST, GET, PUT, HEAD, DELETE, OPTIONS',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Expose-Headers': 'Authorization',
        'Access-Control-Allow-Origin': '*'
      };

      Response _cors(Response response) =>
          response.change(headers: extraHeaders);
      final Middleware _fixCORS = createMiddleware(responseHandler: _cors);

      final Handler handler = const Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_fixCORS)
          .addMiddleware(exceptionHandler())
          .addHandler(root.handler);

      _serverCompleter = new Completer();
      ss.fork(() async {
        ss.register(SERVICE_CONTEXT, createServerContext());

        _server = await io.serve(handler, bindIp, port);

        rootUrl = "http://${_server.address.host}:${_server.port}/";
        _log.info('Serving at $rootUrl');

        return _serverCompleter.future;
      }).then((_) {
        _log.info('Server application shut down cleanly');
      });

    } catch (e, s) {
      _log.severe("Error while starting server", e, s);
    } finally {
      _log.fine("End start()");
    }
  }

  dynamic stop() async {
    for (ABackgroundService bs in _backgroundServices) {
      await bs.stop();
    }

    if (_server == null) throw new Exception("Server has not been started");
    await _server.close();
    _server = null;
    if (_serverCompleter != null) _serverCompleter.complete();
  }

  Future<Option<Principal>> _authenticateUser(
      String userName, String password) async {
    try {
      _log.fine("Start _authenticateUser($userName, password_obfuscated)");
      final Option<AUser> user =
          await userDataSource.getById(userName.trim().toLowerCase());

      if (user.isEmpty) return new None<Principal>();

      final Option<String> hashOption =
          await userDataSource.getPasswordHash(user.get().id);

      if (hashOption.isEmpty)
        throw new Exception("User does not have a password set");

      if (userModel.verifyPassword(hashOption.get(), password))
        return new Some<Principal>(new Principal(user.get().id));
      else
        return new None<Principal>();
    } catch (e, st) {
      _log.severe(e, st);
      rethrow;
    } finally {
      _log.fine("End _authenticateUser()");
    }
  }

  Future<Option<Principal>> _getUser(String uuid) async {
    final Option<AUser> user = await userDataSource.getById(uuid);
    if (user.isEmpty) return new None<Principal>();
    return new Some<Principal>(new Principal(user.get().id));
  }
}
