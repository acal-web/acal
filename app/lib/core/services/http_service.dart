import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:acalapp/core/config/app_config.dart';

/// Thrown for non-2xx responses. [body] is the decoded JSON error payload
/// (e.g. Rails' `{"name": ["has already been taken"]}"`) when the response
/// is JSON, or the raw response body otherwise.
class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;

  /// Standardized error code, if [body] is an `{"code": ..., "message": ...}`
  /// payload (see `ApiError` on the Rails side / `ApiErrorCode` on Flutter).
  int? get code => body is Map ? body['code'] as int? : null;

  /// First error message for [field], if [body] is a Rails-style
  /// `{"field": ["message", ...]}` errors map.
  String? fieldError(String field) {
    final errors = body is Map ? body[field] : null;
    return errors is List && errors.isNotEmpty ? errors.first.toString() : null;
  }

  @override
  String toString() => 'ApiException($statusCode): $body';
}

class HttpService {
  HttpService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _base = Uri.parse(AppConfig.apiBaseUrl);

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query));
    return _decode(response);
  }

  Future<dynamic> post(String path, Object body) async {
    final response = await _client.post(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, Object body) async {
    final response = await _client.put(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path));
    _checkStatus(response);
  }

  void dispose() => _client.close();

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: path, queryParameters: query);

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
