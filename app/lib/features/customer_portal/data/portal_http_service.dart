import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:acalapp/core/config/app_config.dart';
import 'package:acalapp/core/services/http_service.dart' show ApiException;
import 'package:acalapp/features/customer_portal/data/portal_token_storage.dart';

/// Minimal HTTP client for the customer portal. `HttpService` reads its
/// auth token from a single global closure tied to the staff session, so it
/// can't carry a second, concurrent customer session — this reads the
/// customer's token directly from `PortalTokenStorage` instead.
class PortalHttpService {
  PortalHttpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _base = Uri.parse(AppConfig.apiBaseUrl);

  static const _requestTimeout = Duration(seconds: 30);

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await PortalTokenStorage.read();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: await _headers()).timeout(_requestTimeout);
    return _decode(response);
  }

  Future<Uint8List> getBytes(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: await _headers()).timeout(_requestTimeout);
    _checkStatus(response);
    return response.bodyBytes;
  }

  Future<dynamic> post(String path, Object body) async {
    final response = await _client
        .post(_uri(path), headers: await _headers(), body: jsonEncode(body))
        .timeout(_requestTimeout);
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: await _headers()).timeout(_requestTimeout);
    _checkStatus(response);
  }

  void dispose() => _client.close();

  Uri _uri(String path, [Map<String, String>? query]) => _base.replace(path: path, queryParameters: query);

  dynamic _decode(http.Response response) {
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
      throw ApiException(response.statusCode, body);
    }
  }
}
