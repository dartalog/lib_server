import 'dart:async';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:shelf_auth/shelf_auth.dart';
import 'package:meta/meta.dart';
import 'package:tools/tools.dart';
import 'package:server/data_sources/interfaces.dart';
import 'package:server/data/data.dart';
import 'package:server/server.dart';

abstract class AModel<U extends AUser> {
  /// Manually sets the current logged-in (or not logged-in) user.
  @visibleForTesting
  static void overrideCurrentUser(String uuid) {
    if (isNullOrWhitespace(uuid)) {
      _authenticationOverride = new None<Principal>();
    } else {
      _authenticationOverride = new Some<Principal>(new Principal(uuid));
    }
  }

  /// Clears out all current user overrides, even an override of "un-authenticated".
  @visibleForTesting
  static void clearCurrentUserOverride() => _authenticationOverride = null;
  static Option<Principal> _authenticationOverride;
  // TODO: Get this not to be static so that it's carried along with the server instance.

  final AUserDataSource userDataSource;
  final APrivilegeSet privilegeSet;
  AModel(this.userDataSource, this.privilegeSet);

  @protected
  String get currentUserId =>
      userPrincipal.map((Principal p) => p.name).getOrDefault("");

  @protected
  String get defaultCreatePrivilegeRequirement =>
      defaultWritePrivilegeRequirement;
  @protected
  String get defaultDeletePrivilegeRequirement =>
      defaultWritePrivilegeRequirement;
  @protected
  String get defaultPrivilegeRequirement => APrivilegeSet.admin;
  @protected
  String get defaultReadPrivilegeRequirement => defaultPrivilegeRequirement;
  @protected
  String get defaultUpdatePrivilegeRequirement =>
      defaultWritePrivilegeRequirement;
  @protected
  String get defaultWritePrivilegeRequirement => defaultPrivilegeRequirement;

  @protected
  Logger get loggerImpl;

  @protected
  bool get userAuthenticated {
    return userPrincipal.isNotEmpty;
  }

  @protected
  Option<Principal> get userPrincipal {
    if (_authenticationOverride == null) {
      return authenticatedContext()
          .map((AuthenticatedContext<Principal> context) => context.principal);
    } else {
      return _authenticationOverride;
    }
  }

  @protected
  Future<U> getCurrentUser() async {
    final Principal p = userPrincipal
        .getOrElse(() => throw new UnauthorizedException("Please log in"));
    return (await userDataSource.getById(p.name))
        .getOrElse(() => throw new UnauthorizedException("User not found"));
  }

  @protected
  Future<bool> userHasPrivilege(String userType) async {
    if (userType == APrivilegeSet.none)
      return true; //None is equivalent to not being logged in, or logged in as a user with no privileges
    final U user = await getCurrentUser();
    return privilegeSet.evaluate(userType, user.type);
  }

  @protected
  Future<bool> validateCreatePrivilegeRequirement() =>
      validateUserPrivilege(defaultCreatePrivilegeRequirement);

  @protected
  Future<Null> validateCreatePrivileges() async {
    if (!userAuthenticated) {
      throw new UnauthorizedException();
    }
    await validateCreatePrivilegeRequirement();
  }

  @protected
  Future<bool> validateDefaultPrivilegeRequirement() =>
      validateUserPrivilege(defaultPrivilegeRequirement);

  @protected
  Future<bool> validateDeletePrivilegeRequirement() =>
      validateUserPrivilege(defaultDeletePrivilegeRequirement);

  @protected
  Future<Null> validateDeletePrivileges([String id]) async {
    if (!userAuthenticated) {
      throw new UnauthorizedException();
    }
    await validateDeletePrivilegeRequirement();
  }

  @protected
  Future<Null> validateGetPrivileges() async {
    await validateReadPrivilegeRequirement();
  }

  @protected
  Future<bool> validateReadPrivilegeRequirement() =>
      validateUserPrivilege(defaultReadPrivilegeRequirement);

  @protected
  Future<bool> validateUpdatePrivilegeRequirement() =>
      validateUserPrivilege(defaultUpdatePrivilegeRequirement);

  @protected
  Future<Null> validateUpdatePrivileges(String uuid) async {
    if (!userAuthenticated) {
      throw new UnauthorizedException();
    }
    await validateUpdatePrivilegeRequirement();
  }

  @protected
  Future<bool> validateUserPrivilege(String privilege) async {
    if (await userHasPrivilege(privilege)) return true;
    throw new ForbiddenException("$privilege required");
  }
}
