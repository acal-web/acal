import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the customer portal session token under its own key, separate
/// from `TokenStorage` (staff), so the two sessions can't collide.
class PortalTokenStorage {
  static const _tokenKey = 'acal_customer_auth_token';

  static const _storage = FlutterSecureStorage();

  static Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Silent fail on write error
    }
  }

  static Future<void> delete() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Silent fail on delete error
    }
  }
}
