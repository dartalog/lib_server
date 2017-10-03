import 'a_server.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_rpc/shelf_rpc.dart' as shelf_rpc;
import 'package:shelf_static/shelf_static.dart';
import 'package:rpc/rpc.dart';
import 'package:server/data_sources/interfaces.dart';
import 'package:path/path.dart';
import 'package:server/model/model.dart';
import 'package:server/tools.dart';
import '../server.dart';
import 'package:server/api/api.dart';
import 'package:server/server.dart';
import 'media_mime_resolver.dart';

abstract class AApiServer extends AServer {
  ApiServer _apiServer;

  List<AApi> getApis();

  final String apiPrefix = "api";

  AApiServer(
      String serverName, String serverRoot, String dataPath, AUserDataSource userDataSource, AUserModel userModel)
      : super(serverName, serverRoot, dataPath, userDataSource, userModel);

  @override
  void setUpRouter(Router router) {
    super.setUpRouter(router);

    final Handler staticImagesHandler = createStaticHandler(
        join(rootDirectory, dataPath),
        listDirectories: false,
        serveFilesOutsidePath: false,
        useHeaderBytesForContentType: true,
        contentTypeResolver: mediaMimeResolver);

    _apiServer = new ApiServer(apiPrefix: apiPrefix, prettyPrint: true);
    for(AApi api in getApis()) {
      _apiServer.addApi(api);
    }
    _apiServer.enableDiscoveryApi();


    final Handler apiHandler = shelf_rpc.createRpcHandler(_apiServer);
    final Handler apiPipeline = const Pipeline()
        .addMiddleware(defaultAuthMiddleware)
        .addHandler(apiHandler);

    router.add("/$dataPath/", <String>['GET', 'OPTIONS'], staticImagesHandler,
        exactMatch: false);

    router.add(
        '/$apiPrefix/',
        <String>['GET', 'PUT', 'POST', 'HEAD', 'OPTIONS', 'DELETE'],
        apiPipeline,
        exactMatch: false);

    router.add('/discovery/', <String>['GET', 'HEAD', 'OPTIONS'], apiPipeline,
        exactMatch: false);
  }
}
