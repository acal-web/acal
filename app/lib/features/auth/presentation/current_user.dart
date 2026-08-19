import 'package:flutter/foundation.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/auth/data/auth_service.dart';
import 'package:acalapp/features/auth/data/token_storage.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';

class CurrentUser extends ChangeNotifier {
  AuthUser? _user;
  String? _token;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;

  final AuthService _authService;

  CurrentUser({AuthService? authService}) : _authService = authService ?? AuthService();

  void setSession(AuthUser user, String token) {
    _user = user;
    _token = token;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> restore() async {
    try {
      final token = await TokenStorage.read();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final user = await _authService.fetchCurrentUser();
        _user = user;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        clear();
        await TokenStorage.delete();
      }
    } catch (_) {
      // Ignore other errors (network issues, etc)
    }
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
