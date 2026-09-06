import 'dart:convert';

import 'package:http/http.dart' as http;

import 'e2e_config.dart';

/// Direct HTTP access to the Rails test API, used to arrange state before a
/// scenario and to verify it afterwards.
///
/// It deliberately logs in on its own instead of reusing the token the app
/// holds: an assertion made through this client proves the data really reached
/// the database, not just that the UI believed it did.
abstract final class E2eApi {
  static Future<String> login({
    String username = e2eAdminUsername,
    String password = e2eAdminPassword,
  }) async {
    final response = await http.post(
      _uri('/session'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session': {'username': username, 'password': password},
      }),
    );
    _check(response, 'POST /session');
    return (jsonDecode(response.body) as Map<String, dynamic>)['token'] as String;
  }

  /// Truncates every table and recreates the admin the suite logs in as.
  ///
  /// `POST /test/reset` wipes the admin's own row too, but the API authorizes
  /// from the JWT's role alone and never reloads the user, so the token taken
  /// before the reset stays valid for the request that recreates the account.
  /// That is what lets the suite run repeatedly with no manual step in between.
  static Future<void> resetBackendWithFreshAdmin() async {
    final token = await login();

    final reset = await http.post(
      _uri('/test/reset'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _check(reset, 'POST /test/reset');

    final created = await http.post(
      _uri('/users'),
      headers: _authJson(token),
      body: jsonEncode({
        'user': {
          'username': e2eAdminUsername,
          'name': 'Administrador',
          'password': e2eAdminPassword,
          'role': 'administrador',
        },
      }),
    );
    _check(created, 'POST /users (recreate admin)');
  }

  static Future<List<Map<String, dynamic>>> users() async {
    final token = await login();
    final response = await http.get(
      _uri('/users', {'size': '100'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    _check(response, 'GET /users');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['content'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String group,
    String description = 'seed',
    bool hasWaterMeter = false,
    double waterPrice = 10.0,
    double membershipPrice = 30.0,
  }) async {
    final token = await login();
    final response = await http.post(
      _uri('/categories'),
      headers: _authJson(token),
      body: jsonEncode({
        'category': {
          'name': name,
          'description': description,
          'group': group,
          'has_water_meter': hasWaterMeter,
          'water_price': waterPrice,
          'membership_price': membershipPrice,
        },
      }),
    );
    _check(response, 'POST /categories');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> deleteCategory(String id) async {
    final token = await login();
    final response = await http.delete(
      _uri('/categories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _check(response, 'DELETE /categories/$id');
  }

  /// [active] mirrors the API's own filter: `'true'` (default) for live rows,
  /// `'false'` for soft-deleted ones, `'all'` for both.
  static Future<List<Map<String, dynamic>>> categories({String active = 'true'}) async {
    final token = await login();
    final response = await http.get(
      _uri('/categories', {'active': active, 'size': '100'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    _check(response, 'GET /categories');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['content'] as List).cast<Map<String, dynamic>>();
  }

  /// The category matching [name] and [group], or null. The pair is what the
  /// database's unique index covers, so it identifies at most one row.
  static Future<Map<String, dynamic>?> findCategory({
    required String name,
    required String group,
    String active = 'true',
  }) async {
    final all = await categories(active: active);
    for (final category in all) {
      if (category['name'] == name && category['group'] == group) return category;
    }
    return null;
  }

  static Map<String, String> _authJson(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse(e2eApiBaseUrl).replace(path: path, queryParameters: query);

  /// Fails loudly on arrangement errors. A silent 4xx here would surface later
  /// as a confusing UI assertion failure several steps away from the cause.
  static void _check(http.Response response, String what) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('$what failed: ${response.statusCode} ${response.body}');
    }
  }
}
