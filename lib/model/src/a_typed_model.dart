import 'dart:async';
import 'package:meta/meta.dart';
import 'package:server/data/data.dart';
import 'package:tools/tools.dart';
import 'a_model.dart';
import 'package:server/data_sources/interfaces.dart';

abstract class ATypedModel<T, U extends AUser> extends AModel<U> {
  ATypedModel(AUserDataSource userDataSource, APrivilegeSet privilegeSet)
      : super(userDataSource, privilegeSet);

  Future<Null> validate(T t, {String existingId: null}) =>
      DataValidationException.performValidation(
          (Map<String, String> output) async =>
              validateFields(t, output, existingId: existingId));

  @protected
  Future<Null> validateFields(T t, Map<String, String> output,
      {String existingId: null});
}
