import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:acalapp/core/config/app_config.dart';

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
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }
}
