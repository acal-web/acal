import 'package:flutter/foundation.dart';
import 'package:acalapp/core/services/device_registration_service.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/auth/data/auth_service.dart';
import 'package:acalapp/features/auth/data/token_storage.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';

/// Whether a stored session has been validated yet. The router treats
/// [checking] as neither logged in nor out — it holds on a splash screen
/// instead of redirecting to `/login`, so a returning user isn't bounced
/// through the login page while [CurrentUser.restore] is still running.
enum AuthStatus { checking, authenticated, unauthenticated }

class CurrentUser extends ChangeNotifier {
  AuthUser? _user;
  String? _token;
  AuthStatus _status = AuthStatus.checking;

  AuthUser? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  bool get isChecking => _status == AuthStatus.checking;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final AuthService _authService;

  CurrentUser({AuthService? authService}) : _authService = authService ?? AuthService();

  void setSession(AuthUser user, String token) {
    _user = user;
    _token = token;
    _status = AuthStatus.authenticated;
    notifyListeners();
    final devicesPath = user.role == UserRole.customer ? '/portal/devices' : '/devices';
    registerDevice(post: HttpService().post, path: devicesPath);
  }

  void clear() {
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> restore() async {
    try {
      final token = await TokenStorage.read();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final user = await _authService.fetchCurrentUser();
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await TokenStorage.delete();
      }
    } catch (_) {
      // Ignore other errors (network issues, etc)
    }
    clear();
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Ignore errors
    }
    await TokenStorage.delete();
    clear();
  }
}
