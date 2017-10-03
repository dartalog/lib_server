import 'package:rpc/rpc.dart';

String get requestRoot =>
    "${context.requestUri.scheme}://${context.requestUri.host}:${context.requestUri.port}/";
