import 'package:flutter/foundation.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer_portal/data/customer_auth_service.dart';
import 'package:acalapp/features/customer_portal/data/portal_token_storage.dart';
import 'package:acalapp/features/customer_portal/domain/customer_auth_user.dart';

class CurrentCustomer extends ChangeNotifier {
  CustomerAuthUser? _customer;
  String? _token;

  CustomerAuthUser? get customer => _customer;
  String? get token => _token;
  bool get isAuthenticated => _customer != null && _token != null;

  final CustomerAuthService _authService;

  CurrentCustomer({CustomerAuthService? authService}) : _authService = authService ?? CustomerAuthService();

  void setSession(CustomerAuthUser customer, String token) {
    _customer = customer;
    _token = token;
    notifyListeners();
  }

  void clear() {
    _customer = null;
    _token = null;
    notifyListeners();
  }

  Future<void> restore() async {
    try {
      final token = await PortalTokenStorage.read();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final customer = await _authService.fetchCurrentCustomer();
        _customer = customer;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        clear();
        await PortalTokenStorage.delete();
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
    await PortalTokenStorage.delete();
    clear();
  }
}
