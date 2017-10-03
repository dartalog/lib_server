import 'dart:async';

import 'package:server/data/data.dart';
import 'responses/id_response.dart';
import 'package:meta/meta.dart';
import 'package:rpc/rpc.dart';
import 'package:server/model/model.dart' as model;
import 'a_resource.dart';
import 'package:server/tools.dart';
import '../../server.dart';

abstract class AIdResource<T extends AIdData> extends AResource {
  model.AIdBasedModel<T, AUser> get idModel;

  Future<IdResponse> create(T t);
  @protected
  Future<IdResponse> createWithCatch(T t, {List<MediaMessage> mediaMessages}) =>
      catchExceptionsAwait(() async {
        try {
          childLogger.fine("Start createWithCatch($t, $mediaMessages)");
          String output;

          List<List<int>> files;
          if (mediaMessages != null) {
            files = convertMediaMessagesToIntLists(mediaMessages);
          }

          if (idModel is model.AFileUploadModel<T>) {
            final model.AFileUploadModel<T> fileModel =
                idModel as model.AFileUploadModel<T>;
            output = await fileModel.create(t, files: files);
          } else {
            output = await idModel.create(t);
          }
          final IdResponse response =
              new IdResponse.fromId(output, this.generateRedirect(output));
          return response;
        } finally {
          childLogger.fine("End createWithCatch()");
        }
      });

  Future<VoidMessage> delete(String id);
  @protected
  Future<VoidMessage> deleteWithCatch(String id) =>
      catchExceptionsAwait(() async {
        try {
          childLogger.fine("Start deleteWithCatch($id)");
          await idModel.delete(id);
          return new VoidMessage();
        } finally {
          childLogger.fine("End deleteWithCatch()");
        }
      });

  Future<T> getById(String id);

  Future<IdResponse> update(String id, T t);

  @protected
  Future<T> getByUuidWithCatch(String id) => catchExceptionsAwait(() async {
        try {
          childLogger.fine("Start getByUuidWithCatch($id)");
          return await idModel.getById(id);
        } finally {
          childLogger.fine("Start getByUuidWithCatch()");
        }
      });

  @protected
  Future<IdResponse> updateWithCatch(String id, T t,
          {List<MediaMessage> mediaMessages}) =>
      catchExceptionsAwait(() async {
        try {
          childLogger.fine("Start updateWithCatch($id, $t, $mediaMessages)");
          List<List<int>> files;
          if (mediaMessages != null) {
            files = convertMediaMessagesToIntLists(mediaMessages);
          }

          String output;
          if (idModel is model.AFileUploadModel<T>) {
            final model.AFileUploadModel<T> fileModel =
                idModel as model.AFileUploadModel<T>;
            output = await fileModel.update(id, t, files: files);
          } else {
            output = await idModel.update(id, t);
          }

          final IdResponse response =
              new IdResponse.fromId(output, this.generateRedirect(output));
          return response;
        } finally {
          childLogger.fine("End updateWithCatch()");
        }
      });
}
