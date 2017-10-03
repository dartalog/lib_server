// Copyright (c) 2017, Matthew. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library server_libs;

export 'src/exceptions/setup_disabled_exception.dart';
export 'src/exceptions/setup_required_exception.dart';
export 'src/a_server.dart';
export 'src/a_api_server.dart';
export 'src/db_logging_handler.dart';
export 'src/media_mime_resolver.dart';
export 'src/server_context.dart';
export 'src/a_background_service.dart';

// TODO: Export any libraries intended for clients of this package.

const int defaultPerPage = 60;
